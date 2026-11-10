# CI/CD Configuration Guide

This document describes the architecture, patterns, and common tasks for this project GitLab CI/CD configuration.

## Overview

The CI/CD configuration spans different YAML files across `.gitlab-ci.yml` and `.gitlab/ci/`.

## Directory Structure

```text
.gitlab-ci.yml                    # Entry point: stages, workflow rules, global variables, includes
.gitlab/ci/
  version.yml                     # Pinned tool versions (Ruby, Go, Node, Chrome, etc.)
  global.gitlab-ci.yml            # Shared foundations: retry, before_script, caches
  rules.gitlab-ci.yml             # Centralized rules (~3,500 lines): conditions, file patterns, composite rules
  releases.gitlab-ci.yml          # Release tagging
  tofu.gitlab-ci.yml              # OpenTofu plan / apply / destroy, one set of jobs per terraform/live unit
```

## Include Mechanism

The main `.gitlab-ci.yml` uses a **wildcard include** to auto-register all top-level CI files:

```yaml
include:
  - local: .gitlab/ci/*.gitlab-ci.yml
```

Adding a new `.gitlab/ci/foo.gitlab-ci.yml` file automatically includes it in the pipeline. No manual registration
needed.

Conditional includes handle special cases:

- `overrides/skip.yml` -- only for security-canonical-sync MRs (creates a no-op pipeline)

## Rules System

`rules.gitlab-ci.yml` is the single largest file and the single source of truth for all job conditions. It uses three
pattern types:

### 1. Condition anchors (`.if-*`)

Boolean conditions based on CI variables. Referenced via YAML anchors.

```yaml
.if-merge-request: &if-merge-request
  if: '$CI_PIPELINE_SOURCE == "merge_request_event" && ...'

.if-default-branch-refs: &if-default-branch-refs
  if: '$CI_COMMIT_REF_NAME == $CI_DEFAULT_BRANCH && ...'
```

### 2. File-change patterns (`.*-patterns`)

Glob arrays for detecting which files changed. Referenced via YAML anchors.

```yaml
.ci-patterns: &ci-patterns
  - "{,jh/}.gitlab-ci.yml"
  - "{,jh/}.gitlab/ci/**/*"

.plugin-core-patterns: &plugin-core-patterns
  - "plugin-core/**/*"
```

### 3. Composite rule sets (`.category:rules:job-type`)

Combine conditions + file patterns into complete `rules:` blocks that jobs reference via `extends:`.

```yaml
.rails:rules:ee-and-foss-default-rules:
  rules:
    - <<: *if-merge-request
      changes: *plugin-core-patterns
      when: never
    - <<: *if-merge-request-labels-pipeline-expedite
      when: never
    - <<: *if-merge-request-labels-run-all-rspec
      changes: *core-backend-patterns
```

Jobs use these via extends:

```yaml
rspec unit pg17:
  extends:
    - .rspec-base-pg17
    - .rspec-unit-parallel
```

### OpenTofu rules

Each `terraform/live/<unit>/` has a `&tofu-<unit>-patterns` anchor and two composites, `.tofu:rules:plan:<unit>` and
`.tofu:rules:apply:<unit>`, plus a shared `.tofu:rules:destroy`. They are built from these condition anchors:

- `&if-merge-request-label-tofu-plan` / `&if-merge-request-label-tofu-apply` — MR pipelines with that label: plan every
  unit, and with `tofu:apply` also expose a manual apply
- `&if-destroy-infra` — `destroy_infra` input set to `true` on the default branch (`DESTROY_INFRA=true`)
- `&if-schedule-token-rotation` — schedules with `SCHEDULE_TASK=token-rotation`, which re-apply the bot units

A plan runs when an MR or a default-branch push changes the unit's files, on the labels above, on manual runs, and in
destroy pipelines. An apply is always manual, except in the token-rotation schedule. See
[docs/infrastructure.md](../docs/infrastructure.md) for the units and their bootstrap.

## Job Dependencies (DAG)

Stages in this project exist purely for **visual grouping** in the GitLab pipeline UI — they have no effect on
execution order. Every job declares its real dependencies via `needs:`, and the actual execution timeline is the DAG
formed by those declarations.

Rules:

- Every job MUST declare a `needs:` key, even when empty. Never rely on implicit stage-by-stage ordering.
- `needs: []` — for jobs with no upstream dependency. They start at t=0 alongside every other `needs: []` job,
  regardless of which stage they sit in.
- `needs: [{job: <name>, artifacts: false}]` — for jobs that depend on another job's completion (e.g. to reuse the
  cache it just pushed). Pass `artifacts: false` when you only care about completion and don't need the upstream
  job's artifact bundle — it skips the artifact upload/download dance.

Because of this, a new job can be placed in whichever stage fits it semantically (for UI clarity) without that
choice affecting when it runs. Adding a job and forgetting `needs:` is a bug, not a shortcut.

## Shared Foundations

### `global.gitlab-ci.yml`

Defines reusable building blocks:

- **`.default-retry`** -- retry policy (max 2 retries for infra failures)
- **`.mise-before_script`** -- installs the job's mise tool set (`mise install $TOOLSET_TOOLS`) and activates it
- **`.toolset:*`** -- per-job tool sets (`TOOLSET` / `TOOLSET_TOOLS`). Adding a tool to `mise.toml` does not make it
  available to a job: add it to every set that needs it. `.mise-cache` is keyed per `$TOOLSET`
- **`.use-docker-in-docker`** -- Docker-in-Docker setup
- **Cache definitions** -- `.mise-cache`, `.kotlin-toolchain-cache`, `.assets-cache`, etc.

## Child Pipelines

Child pipelines are triggered via `trigger:` jobs. Key patterns:

## Workflow Rules

The `workflow:rules:` block in `.gitlab-ci.yml` determines:

- Whether a pipeline runs at all
- The pipeline name
- Special variable overrides (e.g., `BUNDLE_GEMFILE: Gemfile.next` for rails-next)

Key pipeline types:

- **MR pipelines** -- triggered by merge request events
- **Default branch pipelines** -- pushes/merges to master
- **Scheduled pipelines** -- nightly, weekly, maintenance
- **Manual pipelines** -- e.g. for releases
- **Destroy pipelines** -- manual web trigger with the `destroy_infra` input set to `true`, named `Destroy pipeline`.
  Sets `DESTROY_INFRA=true`, which exposes the `destroy:<unit>` jobs

## Common Tasks

### Add a new CI job

1. Add the job to the appropriate `.gitlab/ci/*.gitlab-ci.yml` file (or create a new one -- it auto-includes via
   wildcard).
2. Define a `.<job>:rules` composite in `rules.gitlab-ci.yml` from the existing condition anchors and file patterns,
   and reference it from the job with `!reference [".<job>:rules", rules]`. Never reference a bare `.if-*` anchor
   from another file.
3. Extend shared foundations (`.default-retry`, a `.toolset:*` set, service mixins) and add
   `!reference [".mise-before_script", before_script]` to its `before_script:` if it uses mise tools.
4. Declare `needs:` explicitly (see [Job Dependencies (DAG)](#job-dependencies-dag)). Use `needs: []` if there is no
   upstream dependency. Stage choice is for UI grouping only and must not be relied on for ordering.

### Add file-change patterns for a new area

1. In `rules.gitlab-ci.yml`, add a new pattern anchor:

   ```yaml
   .my-new-patterns: &my-new-patterns
     - "path/to/files/**/*"
   ```

2. Create composite rules that use the pattern with appropriate conditions.

## External Dependencies

The CI config pulls from external sources:

- **CI Components**: `danger-review@2.1.0`, `allure-report@11.18.0`

## Gotchas

- **Wildcard auto-include**: Any new `*.gitlab-ci.yml` at the top level of `.gitlab/ci/` is automatically included.
  Files in subdirectories are NOT auto-included.
- **Rules first-match-wins**: GitLab CI `rules:` uses first-match-wins semantics. Order matters. Put `when: never`
  exclusions before `when: always` inclusions.
- **YAML anchor scope**: Anchors defined in `rules.gitlab-ci.yml` are available in files that `include:` it (like
  `rails/shared.gitlab-ci.yml`), but NOT in files included via the top-level wildcard. Top-level files use `!reference`
  instead.
- **`!reference` vs YAML anchors**: Use `!reference [".some-key", rules]` to reference keys across files included at the
  same level. YAML anchors (`*anchor`) only work within the same file or direct includes.
