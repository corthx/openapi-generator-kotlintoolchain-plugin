# Contributing

Thank you for your interest in contributing! This project is hosted
on [GitLab](https://gitlab.com/corthx/openapi-generator-kotlintoolchain-plugin) — please open issues and merge
requests there. The GitHub repository is a read-only mirror.

## Reporting Bugs

Open an issue on GitLab using
the [Bug Report](https://gitlab.com/corthx/openapi-generator-kotlintoolchain-plugin/-/work_items/new?description_template=Bug%20Report)
template. Include as much detail as possible — environment, reproduction steps, and a minimal `module.yaml` + OpenAPI
spec if applicable.

## Suggesting Features

Open an issue on GitLab using
the [Feature Request](https://gitlab.com/corthx/openapi-generator-kotlintoolchain-plugin/-/work_items/new?description_template=Feature%20Request)
template. Describe the problem you're trying to solve and your proposed solution.

## Submitting Code

1. Fork the project on GitLab.
2. Create a branch from `main`
3. Make your changes.
4. Verify the build passes: `./kotlin build`.
5. Open a Merge Request against `main` using the provided template.

## Development Setup

See [docs/development.md](docs/development.md).

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```text
<type>(<scope>): <short description>
```

Common types: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`.

Examples:

```text
feat(plugin): Add globalProperties support
fix(generate): Skip test file generation by default
docs: Update README usage section
```

## License

By submitting a contribution, you agree that your code will be licensed under the [Apache License 2.0](LICENSE).
