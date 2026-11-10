# Development Setup

## Requirements

- **[Mise](https://mise.jdx.dev/installing-mise.html#homebrew)**

Mise will then install the multiple tools automatically.  
See the `[tools]` table header in `mise.toml` for more details.

To see the available mise tasks, use the `mise run` command.

## Build system

- The build system is [Kotlin Toolchain](https://kotlin-toolchain.org/latest/) — no Gradle or Maven needed.
- Use the `./kotlin` executable to configure the project. It will automatically download and use a compatible JDK for
  you.

## IntelliJ IDEA

Open the project root in IntelliJ IDEA. No manual JDK setup is required: run configurations use Kotlin Toolchain's
JDK auto-provisioning and will download the correct JDK automatically on first run.

## Maintenance jobs

- [Weekly dependency digest](deps-digest.md) — posts merged Renovate MRs to Discord every Monday.

## Infrastructure

The project's GitLab configuration is managed with OpenTofu under `terraform/`. See
[infrastructure.md](infrastructure.md).
