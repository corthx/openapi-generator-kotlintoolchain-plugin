# OpenAPI Generator — Kotlin Toolchain Plugin

A [Kotlin Toolchain](https://kotlin-toolchain.org/latest/) plugin that
integrates [OpenAPI Generator](https://openapi-generator.tech/) into the build pipeline.

It exposes a `generateOpenAPI` task that reads an OpenAPI specification file, runs the configured generator, and
automatically registers the produced sources as source sets — Kotlin and Java, main and test — no manual wiring needed.

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![GitLab](https://img.shields.io/badge/source-GitLab-orange.svg)](https://gitlab.com/corthx/openapi-generator-kotlintoolchain-plugin)

## Installation

:warning: The Kotlin Toolchain does not yet have a plugin registry. Until then, the recommended way to consume this
plugin is via a **git submodule**.

### 1. Add the submodule

```sh
git submodule add git@gitlab.com:corthx/openapi-generator-kotlintoolchain-plugin.git openapi-generator-plugin
```

### 2. Register the plugin in `project.yaml`

```yaml
plugins:
  - ./openapi-generator-plugin/plugin-core
```

## Usage

### Enable the plugin in `module.yaml`

```yaml
plugins:
  openapi-generator:
    enabled: true
    generatorName: kotlin
    inputSpec: "resources/openapi/api.yml"
```

| Setting                      | Required | Description                                                                                                    |
|------------------------------|----------|----------------------------------------------------------------------------------------------------------------|
| `enabled`                    | yes      | Activates the plugin for this module.                                                                          |
| `generatorName`              | yes      | The OpenAPI Generator target (e.g. `kotlin`, `kotlin-server`, …).                                              |
| `inputSpec`                  | yes\*    | Path to a local OpenAPI spec file, relative to the module root. Mutually exclusive with `remoteInputSpec`.     |
| `inputSpecsDirectory`        | no       | Directory of spec files referenced from `inputSpec` (e.g. via `$ref`). Tracked so edits invalidate the cache.  |
| `remoteInputSpec`            | yes\*    | URL to a remote OpenAPI spec (e.g. a service's `/openapi.json`). Mutually exclusive with `inputSpec`.          |
| `auth`                       | no       | Authorization header(s) used to fetch `remoteInputSpec` (e.g. `Authorization: Bearer <token>`).                |
| `httpUserAgent`              | no       | Custom HTTP `User-Agent` used to fetch `remoteInputSpec`.                                                      |
| `configFile`                 | no       | Path to a JSON configuration file for the generator. Inline settings override values loaded from the file.     |
| `verbose`                    | no       | Enable verbose logging from the generator. Default: `false`.                                                   |
| `logToStderr`                | no       | Write all log messages to stderr instead of stdout. Default: `false`.                                          |
| `dryRun`                     | no       | Run the generator without writing any files to disk. Default: `false`.                                         |
| `validateSpec`               | no       | Enable or disable spec validation before code generation. Default: `true`.                                     |
| `skipValidateSpec`           | no       | Skip spec validation entirely. Equivalent to `validateSpec: false`. Default: `false`.                          |
| `cleanupOutput`              | no       | Delete all files in the output directory before generation begins. Default: `false`.                           |
| `skipOverwrite`              | no       | Prevent the generator from overwriting files that already exist in the output directory. Default: `false`.     |
| `globalProperties`           | no       | Global property overrides for the generator (e.g. `{apiTests: "false", debugModels: "true"}`).                 |
| `configOptions`              | no       | Generator-specific options as key-value pairs (e.g. `dateLibrary`, `enumPropertyNaming`).                      |
| `additionalProperties`       | no       | Extra properties made available inside Mustache/Handlebars templates (e.g. `{serializableModel: "true"}`).     |
| `packageName`                | no       | Default package for all generated classes when more specific packages are not set.                             |
| `apiPackage`                 | no       | Package for generated API interface/implementation classes.                                                    |
| `modelPackage`               | no       | Package for generated model/DTO classes.                                                                       |
| `invokerPackage`             | no       | Root/invoker package used by some generators as the top-level namespace.                                       |
| `modelNamePrefix`            | no       | Prefix prepended to every generated model class name.                                                          |
| `modelNameSuffix`            | no       | Suffix appended to every generated model class name.                                                           |
| `apiNameSuffix`              | no       | Suffix appended to every generated API class/interface name.                                                   |
| `groupId`                    | no       | GroupId written into generated build scripts (e.g. `pom.xml`, `build.gradle`).                                 |
| `id`                         | no       | ArtifactId written into generated build scripts.                                                               |
| `version`                    | no       | Artifact version written into generated build scripts.                                                         |
| `library`                    | no       | Sub-template to use with the selected generator (e.g. `jvm-ktor`, `jvm-okhttp4` for `kotlin`).                 |
| `gitHost`                    | no       | Git host (e.g. `gitlab.com`, `github.com`). Included in generated repository URLs and scripts.                 |
| `gitUserId`                  | no       | Git user or organisation name. Included in generated repository URLs and scripts.                              |
| `gitRepoId`                  | no       | Git repository name. Included in generated repository URLs and scripts.                                        |
| `releaseNote`                | no       | Release note text embedded in generated changelogs and scripts.                                                |
| `typeMappings`               | no       | Map from OpenAPI type names to language-specific types (e.g. `{DateTime: Instant}`).                           |
| `instantiationTypes`         | no       | Map from OpenAPI container types to their concrete instantiation classes (e.g. `{array: LinkedList}`).         |
| `importMappings`             | no       | Map from class names to fully-qualified import paths (e.g. `{Instant: java.time.Instant}`).                    |
| `languageSpecificPrimitives` | no       | Additional types to treat as language primitives — not wrapped in model classes (e.g. `[Instant, LocalDate]`). |
| `nameMappings`               | no       | Map from schema property names to generated property names (e.g. `{title: heading}`).                          |
| `parameterNameMappings`      | no       | Map from operation parameter names to generated parameter names (e.g. `{id: postId}`).                         |
| `modelNameMappings`          | no       | Map from schema/model names to generated class names (e.g. `{PostDto: BlogPostDto}`).                          |
| `enumNameMappings`           | no       | Map from enum value names to generated enum constant names (e.g. `{active: ENABLED}`).                         |
| `operationIdNameMappings`    | no       | Map from operation IDs to generated method names (e.g. `{getPost: fetchPost}`).                                |
| `schemaMappings`             | no       | Map from spec schema names to replacement types (e.g. `{PostDto: com.example.PostDto}`).                       |
| `inlineSchemaNameMappings`   | no       | Map from inline schema names to desired names (e.g. `{listPosts_200_response: PostCollection}`).               |
| `inlineSchemaOptions`        | no       | Options controlling how inline schemas are handled (e.g. `{RESOLVE_INLINE_ENUMS: "true"}`).                    |
| `reservedWordsMappings`      | no       | Override how reserved words in the target language are escaped (e.g. `{class: clazz}`).                        |
| `serverVariables`            | no       | Variable substitutions for server URL templates in the spec (e.g. `{scheme: https, env: prod}`).               |
| `openapiNormalizer`          | no       | Rules applied by the OpenAPI normalizer (e.g. `{SET_TAGS_FOR_ALL_OPERATIONS: blog}`).                          |
| `removeOperationIdPrefix`    | no       | Strip the prefix (before first `_`) from operation IDs (e.g. `Pets_GetPets` → `getPets`). Default: `false`.    |
| `skipOperationExample`       | no       | Do not include operation examples from the spec in generated code. Default: `false`.                           |
| `enablePostProcessFile`      | no       | Enable the post-processing hook (`OPENAPI_GENERATOR_IGNORE_FILE_OVERRIDE` env var). Default: `false`.          |
| `templateDir`                | no       | Directory of custom Mustache/Handlebars templates that override the built-in ones (mirroring their paths).     |
| `templateEngine`             | no       | Template engine to render templates: `mustache` (default) or `handlebars`.                                     |
| `ignoreFileOverride`         | no       | Path to a custom `.openapi-generator-ignore` file whose patterns exclude matching files from generation.       |
| `openapiGeneratorIgnoreList` | no       | Inline list of gitignore-style patterns excluded from generation (e.g. `[docs/**, src/test/**]`).              |

\* Exactly one of `inputSpec` or `remoteInputSpec` must be set.

### Run the generator

```sh
./kotlin run generateOpenAPI
```

The generated sources are automatically registered as a source set — no extra wiring needed. A normal build also
triggers generation:

```sh
./kotlin build
```

### Use the generated code

The generated package root follows the OpenAPI Generator convention for the chosen target. For the `kotlin` generator:

```kotlin
import org.openapitools.client.apis.DefaultApi

fun main() {
  val api = DefaultApi()
  val result = api.getSomething(id = 1)
  println(result)
}
```

Add the runtime dependencies required by the generator to `module.yaml`. For the `kotlin` generator:

```yaml
dependencies:
  - com.squareup.okhttp3:okhttp:4.12.0
  - com.squareup.moshi:moshi-kotlin:1.15.2
```

## Migrating from the Gradle plugin

Already using the official `org.openapi.generator` Gradle plugin?
See [docs/migration-from-gradle-plugin.md](docs/migration-from-gradle-plugin.md)
for a before / after comparison, a Gradle-options → `module.yaml`-settings
mapping table, and notes on behavioural differences.

## Migrating from the Maven plugin

Already using the official `openapi-generator-maven-plugin`?
See [docs/migration-from-maven-plugin.md](docs/migration-from-maven-plugin.md)
for a before / after comparison, a Maven-`<configuration>` → `module.yaml`-settings
mapping table, and notes on behavioural differences.

## Contributing

Contributions are welcome!
See [CONTRIBUTING](CONTRIBUTING.md) for guidelines.

## License

Licensed under the [Apache License 2.0](LICENSE).  
Copyright 2026 Corentin Hervaud.
