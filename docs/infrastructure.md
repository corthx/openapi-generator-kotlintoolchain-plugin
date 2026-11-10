# Infrastructure

This project's GitLab configuration (labels, issue boards, pipeline schedules and the bots' service accounts) is
managed as code with [OpenTofu](https://opentofu.org/). Change it by editing HCL and merging a merge request, not in
the GitLab UI: a manual change is reverted by the next apply.

## Layout

`terraform/live/<unit>/` holds one small root module per concern. Each one calls a versioned module that the
`infrastructure` repository publishes to the GitLab module registry (`gitlab.com/corthx/<module>/gitlab`).

| Unit | Manages |
| --- | --- |
| `labels` | Project labels, including `tofu:plan` / `tofu:apply` |
| `issue-boards` | Project issue boards and their lists |
| `terraform-provider-bot` | Maintainer service account whose token (`GITLAB_TOFU_PROVIDER_TOKEN`) authenticates the GitLab provider in every unit |
| `terraform-provider-rotator-bot` | Second maintainer account (`GITLAB_TOFU_PROVIDER_ROTATOR_TOKEN`), used only to rotate the provider bot's own token |
| `tofu-bot` | Reporter account (`GITLAB_TOFU_MR_PLAN_TOKEN`) that posts plans as MR comments |
| `pipeline-schedule-token-rotation` | Weekly `SCHEDULE_TASK=token-rotation` schedule that re-applies the bot units |
| `renovate-bot` | Developer account (`RENOVATE_TOKEN`, `RENOVATE_GIT_AUTHOR_EMAIL`) that Renovate runs as |
| `pipeline-schedule-renovate` | Daily `SCHEDULE_TASK=renovate` schedule that runs Renovate |
| `pipeline-schedule-deps-digest` | Weekly `SCHEDULE_TASK=deps-digest` schedule that posts the [dependency digest](deps-digest.md) |

GitLab manages the state: each unit has its own encrypted state, named after the unit. `backend "http" {}` stays empty
in code, and the OpenTofu CI component fills it in. No state file or `.terraform` directory is ever committed; the
`.terraform.lock.hcl` files are.

Out of scope: the `gitlab_project` resource (visibility, merge request settings, protected branches and tags). Adopting
it would mean importing the live project, and an apply could end up reconfiguring it. The GitHub mirror
(`.github/workflows/release.yml`) isn't managed here either.

## Day-to-day

- **Merge requests**: a unit's `plan` job runs when the merge request changes that unit's files. Add the `tofu:plan`
  label to plan every unit, or `tofu:apply` to plan every unit and expose a manual `apply` on the merge request.
- **Default branch**: after a merge, the changed units plan again and their `apply` job waits for a manual run.
- **Manual runs**: a pipeline run from the UI on the default branch plans every unit and exposes every `apply`.
- **Token rotation**: the weekly schedule re-applies the bot units, which rotates any token within 14 days of
  expiring.

Locally, `mise run tofu:format`, `mise run tofu:lint` and `mise run tofu:lock:all` format, lint and validate the units,
and refresh their provider lock files. The pre-commit hooks run the first two on staged `.tf` files.

Renovate keeps the provider, the `corthx/*` modules, OpenTofu and the OpenTofu CI component up to date. OpenTofu and
the component are written twice (`mise.toml` and the component's `opentofu_version` input, the include ref and its
`version` input): each copy carries a `# renovate:` comment, and one merge request labeled `tofu:plan` bumps both.

## Adding a bot

GitLab doesn't let a project service account create other service accounts, so the provider bot can't create a new
bot unit's account. It can manage the account afterwards, including the weekly token rotation.

1. Create `GITLAB_TOFU_PROVIDER_MANUAL_TOKEN` as in [Bootstrap](#bootstrap) step 2.
2. Point the new unit's `.unit:<bot>` at `.gitlab-provider-auth-via-manual-token`, and apply it from the merge request
   labeled `tofu:apply`.
3. Before merging, switch the unit to `.gitlab-provider-auth-via-provider-bot` and check that its plan shows no
   changes, so the default branch never relies on the manual token.
4. Revoke the project access token and delete `GITLAB_TOFU_PROVIDER_MANUAL_TOKEN`.

Only the bot's own unit needs this. A schedule unit, for example, stays on the provider bot, so the provider bot owns
the schedule. Apply a new schedule unit only once the job it triggers is on the default branch, so the schedule never
fires before the job exists.

## Destroying the infrastructure

Run a pipeline on the default branch with the `destroy_infra` input set to `true`. This exposes a manual `destroy`
job per unit. Destroying `labels` and `issue-boards` deletes the project's labels and boards.

## Bootstrap

Done once, when the units were added (#57). Needed again only if the bots are destroyed, since every unit authenticates
with a bot token that the bot units themselves create.

1. Add `corthx/openapi-generator-kotlintoolchain-plugin` to the job token allowlist of `corthx/infrastructure`
   (**Settings → CI/CD → Job token permissions**). Without it, `tofu init` fails with `403 Forbidden` on the module
   registry. In this project, turn on **Infrastructure** (Terraform states) and **Environments** (**Settings → General
   → Visibility, project features, permissions**). Without the first, `tofu init` fails with `HTTP remote state
   endpoint invalid auth`; the second is what scopes `GITLAB_TOFU_PROVIDER_ROTATOR_TOKEN` to the
   `terraform-provider-bot` jobs.
2. In **Settings → CI/CD → Variables**, add these masked and hidden variables. They must not be protected, because
   merge request pipelines plan with them:
   - `TOFU_ENCRYPTION_PASSPHRASE`: a long random passphrase that encrypts every state. Losing it makes the states
     unreadable. Keep it after the bootstrap.
   - `GITLAB_TOFU_PROVIDER_MANUAL_TOKEN`: a project access token with the Maintainer role and the `api` scope, and a
     short expiry.
3. In `.gitlab/ci/tofu.gitlab-ci.yml`, point every `.unit:*` at `.gitlab-provider-auth-via-manual-token` and set
   `post_mr_plan_comment: false`. Apply only the three tofu bot units (from a merge request labeled `tofu:apply`, or
   on the default branch), `terraform-provider-bot` first: they create the bot tokens every other unit authenticates
   with. Apply `renovate-bot` the same way, after deleting the `RENOVATE_TOKEN` variable set by hand: the unit creates
   its own, and fails if one already exists.
4. Switch every unit back to its bot auth and set `post_mr_plan_comment: true`, then apply the remaining units.
   `labels` and `issue-boards` import the existing labels and boards through their `imports.tf`, whose IDs use the
   project path, as in the configuration (`corthx/openapi-generator-kotlintoolchain-plugin:<id>`): a numeric project ID
   makes the provider replace the resource. `tofu:plan` / `tofu:apply` were created through the API beforehand, so
   this merge request could use them, and are imported too. Delete both `imports.tf` files once applied. Don't apply
   the pipeline schedules with the manual token: a schedule runs as its owner, which is whoever created it, so it
   would stop running once the token is revoked.
5. Delete the `renovate` and `deps-digest` schedules created by hand (**Build → Pipeline schedules**), now replaced
   by the ones the provider bot owns. Until then each task runs twice: harmless for Renovate, but the digest is
   posted twice.
6. Revoke the project access token and the old token Renovate used, and delete `GITLAB_TOFU_PROVIDER_MANUAL_TOKEN`.
   Check that the next scheduled `renovate` run still updates the dependency dashboard (#52).

The release pipeline authenticates with `CI_JOB_TOKEN`. Three CI/CD variables stay set by hand, since they aren't
GitLab credentials and no bot can issue them:

- `DISCORD_DEPS_WEBHOOK_URL`: the Discord webhook the `deps-digest` job posts to (see [deps-digest.md](deps-digest.md)).
- `MISE_GITHUB_TOKEN`: a GitHub token mise uses to download tools from GitHub releases without hitting github.com's
  anonymous rate limit. Renew it by hand before it expires.
- `RENOVATE_GITHUB_COM_TOKEN`: a GitHub token Renovate uses for changelogs and to stay under github.com's anonymous
  rate limit. Renew it by hand before it expires.

The GitHub mirror's credentials live in the push mirror settings, not in a variable.
