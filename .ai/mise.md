# Mise Configuration Guide

## Overview

This project uses [mise](https://mise.jdx.dev/) to manage tools and tasks. Configuration is split across two files to
separate what is needed everywhere from what is only useful locally.

## Configuration Files

| File            | Purpose                                                                        |
|-----------------|--------------------------------------------------------------------------------|
| `mise.toml`     | Tools and tasks needed in both CI and local dev                                |
| `mise.dev.toml` | Dev-only tools and hooks, loaded only when `MISE_ENV=dev`                      |
| `mise.ci.toml`  | CI-only settings, loaded only when `MISE_ENV=ci`                               |
| `.miserc.toml`  | Sets the default env to `dev` for local dev environments                       |
| `.mise/*.toml`  | Topical task definitions, included via `[task_config] includes` in `mise.toml` |

## Envs

The project uses mise envs to load different configuration depending on the environment:

- **Local dev** (default): `.miserc.toml` sets `env = ["dev"]`, so mise loads `mise.toml` + `mise.dev.toml`.
  The enter hook runs automatically, installing tools and setting up git hooks.
- **CI**: `MISE_ENV=ci` is set in `.gitlab/ci/global.gitlab-ci.yml`, so `mise.toml` + `mise.ci.toml` are loaded.
  No enter hook, no dev-only tools. `mise.ci.toml` disables tool auto-install so `mise run` cannot undo the per-job
  tool sets (`.toolset:*` in `.gitlab/ci/global.gitlab-ci.yml`).

## Adding Tools

- Add tools used in **both CI and local dev** to `mise.toml`.
- Add tools used **only locally** (e.g. linters not run in CI) to `mise.dev.toml`.
- A tool needed by a CI job must also be added to that job's `.toolset:*` set in `.gitlab/ci/global.gitlab-ci.yml`.
- All tools must use **pinned versions** (e.g. `actionlint = "1.7.12"`). Never use `latest` or other floating
  references. Look up the current stable version and pin it explicitly.

## Adding Tasks

Task definitions live in topical files under `.mise/` (e.g. `.mise/pre-commit.toml` groups pre-commit tasks). They are
loaded via the `[task_config] includes` array in `mise.toml`.

When adding a new task:

1. Put it in the topical `.mise/*.toml` file that fits its domain.
2. Create a new file if no suitable one exists, and add it to the `includes` array in `mise.toml`.
3. Never add tasks directly to `mise.toml`.
