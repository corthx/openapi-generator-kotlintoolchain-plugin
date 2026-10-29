# Migrating from the OpenAPI Generator Gradle plugin

This guide is for projects currently using the official
[`org.openapi.generator`](https://github.com/OpenAPITools/openapi-generator/tree/master/modules/openapi-generator-gradle-plugin)
Gradle plugin that want to move to this Kotlin Toolchain plugin.

It walks through what changes in your build configuration, how each Gradle
plugin option maps to a `module.yaml` setting, and which behavioural
differences are worth knowing about.

> For migrating from the Maven plugin, see the (separate) Maven migration
> guide — out of scope here.

## Before / after

A representative Ktor client setup using the Gradle plugin:

```kotlin
// build.gradle.kts
plugins {
  id("org.openapi.generator") version "7.10.0"
  application
}

dependencies {
  implementation("com.squareup.okhttp3:okhttp:4.12.0")
  implementation("com.squareup.moshi:moshi-kotlin:1.15.2")
}

openApiGenerate {
  generatorName.set("kotlin")
  inputSpec.set("$rootDir/src/main/resources/openapi/test-api.yml")
  outputDir.set("$buildDir/generated/openapi")
  apiPackage.set("com.example.api")
  modelPackage.set("com.example.model")
}

// Wire generated sources into the main source set
sourceSets["main"].java.srcDir("$buildDir/generated/openapi/src/main/kotlin")

// Make compile depend on generation
tasks.named("compileKotlin") { dependsOn("openApiGenerate") }
```

The equivalent under this plugin — register the plugin once in
`project.yaml`, then configure it per-module in `module.yaml`:

```yaml
# project.yaml
plugins:
  - ./openapi-generator-plugin/plugin-core
```

```yaml
# module.yaml
product: jvm/app

plugins:
  openapi-generator:
    enabled: true
    generatorName: kotlin
    inputSpec: "resources/openapi/test-api.yml"
    apiPackage: com.example.api
    modelPackage: com.example.model

dependencies:
  - com.squareup.okhttp3:okhttp:4.12.0
  - com.squareup.moshi:moshi-kotlin:1.15.2

settings:
  jvm:
    jdk:
      version: 21
      distributions: [corretto]
    mainClass: com.example.ApplicationKt
  kotlin:
    version: 2.3.20
```

Source set wiring and the `compileKotlin → generate` task dependency are
handled automatically. A `./kotlin build` triggers generation as needed; you
can also run the action explicitly with `./kotlin run generateOpenAPI`.

A working end-to-end example lives in
[`tests/simple-ktor-client/`](../tests/simple-ktor-client/). The same shape
applies to a Ktor server setup — switch `generatorName` to `kotlin-server`
and set `library: jvm-ktor` (see the [Ktor server library docs](https://openapi-generator.tech/docs/generators/kotlin-server))
— but no dedicated server test project ships with the plugin yet.

## Settings mapping

Gradle options use the `openApiGenerate { ... }` extension. Toolchain
settings live under `plugins.openapi-generator` in `module.yaml`.

### Direct one-to-one mappings

| Gradle option                       | `module.yaml` setting             | Notes                                                                |
|-------------------------------------|-----------------------------------|----------------------------------------------------------------------|
| `generatorName`                     | `generatorName`                   | Same values (e.g. `kotlin`, `kotlin-server`, `java`, …).             |
| `inputSpec` (local file)            | `inputSpec`                       | Path is resolved relative to the module root, not `$rootDir`.        |
| `inputSpec` (URL)                   | `remoteInputSpec`                 | Split out into a separate setting; mutually exclusive.               |
| `configFile`                        | `configFile`                      | JSON file; inline settings override file values.                     |
| `auth`                              | `auth`                            | Used when fetching `remoteInputSpec`.                                |
| `httpUserAgent`                     | `httpUserAgent`                   | Used when fetching `remoteInputSpec`.                                |
| `verbose`                           | `verbose`                         |                                                                      |
| `logToStderr`                       | `logToStderr`                     |                                                                      |
| `dryRun`                            | `dryRun`                          |                                                                      |
| `validateSpec`                      | `validateSpec`                    |                                                                      |
| `skipValidateSpec`                  | `skipValidateSpec`                |                                                                      |
| `cleanupOutput`                     | `cleanupOutput`                   |                                                                      |
| `skipOverwrite`                     | `skipOverwrite`                   |                                                                      |
| `globalProperties`                  | `globalProperties`                | Same `Map<String, String>` shape.                                    |
| `configOptions`                     | `configOptions`                   |                                                                      |
| `additionalProperties`              | `additionalProperties`            |                                                                      |
| `packageName`                       | `packageName`                     |                                                                      |
| `apiPackage`                        | `apiPackage`                      |                                                                      |
| `modelPackage`                      | `modelPackage`                    |                                                                      |
| `invokerPackage`                    | `invokerPackage`                  |                                                                      |
| `modelNamePrefix`                   | `modelNamePrefix`                 |                                                                      |
| `modelNameSuffix`                   | `modelNameSuffix`                 |                                                                      |
| `apiNameSuffix`                     | `apiNameSuffix`                   |                                                                      |
| `groupId`                           | `groupId`                         |                                                                      |
| `id`                                | `id`                              |                                                                      |
| `version`                           | `version`                         |                                                                      |
| `library`                           | `library`                         |                                                                      |
| `gitHost`                           | `gitHost`                         |                                                                      |
| `gitUserId`                         | `gitUserId`                       |                                                                      |
| `gitRepoId`                         | `gitRepoId`                       |                                                                      |
| `releaseNote`                       | `releaseNote`                     |                                                                      |
| `typeMappings`                      | `typeMappings`                    |                                                                      |
| `instantiationTypes`                | `instantiationTypes`              |                                                                      |
| `importMappings`                    | `importMappings`                  |                                                                      |
| `languageSpecificPrimitives`        | `languageSpecificPrimitives`      | YAML list (e.g. `[Instant, LocalDate]`).                             |
| `nameMappings`                      | `nameMappings`                    |                                                                      |
| `parameterNameMappings`             | `parameterNameMappings`           |                                                                      |
| `modelNameMappings`                 | `modelNameMappings`               |                                                                      |
| `enumNameMappings`                  | `enumNameMappings`                |                                                                      |
| `operationIdNameMappings`           | `operationIdNameMappings`         |                                                                      |
| `schemaMappings`                    | `schemaMappings`                  |                                                                      |
| `inlineSchemaNameMappings`          | `inlineSchemaNameMappings`        |                                                                      |
| `inlineSchemaOptions`               | `inlineSchemaOptions`             |                                                                      |
| `reservedWordsMappings`             | `reservedWordsMappings`           |                                                                      |
| `serverVariables`                   | `serverVariables`                 |                                                                      |
| `openapiNormalizer`                 | `openapiNormalizer`               |                                                                      |
| `removeOperationIdPrefix`           | `removeOperationIdPrefix`         |                                                                      |
| `skipOperationExample`              | `skipOperationExample`            |                                                                      |
| `enablePostProcessFile`             | `enablePostProcessFile`           |                                                                      |
| `templateDir`                       | `templateDir`                     | Resolved relative to the module root.                                |
| `engine` / `templateEngine`         | `templateEngine`                  | `mustache` (default) or `handlebars`.                                |
| `ignoreFileOverride`                | `ignoreFileOverride`              | Path to a custom `.openapi-generator-ignore` file.                   |
| `openapiGeneratorIgnoreList`        | `openapiGeneratorIgnoreList`      | YAML list of gitignore-style patterns.                               |

### Renamed / restructured

| Gradle option            | `module.yaml` setting   | What changed                                                                  |
|--------------------------|-------------------------|-------------------------------------------------------------------------------|
| `inputSpecRootDirectory` | `inputSpecsDirectory`   | Same purpose (directory of `$ref`-able specs); name slightly different.       |
| `inputSpec` (URL value)  | `remoteInputSpec`       | Remote specs use a dedicated setting; pair with `auth` / `httpUserAgent`.     |

### No equivalent (yet)

| Gradle option                          | Status                                                                |
|----------------------------------------|-----------------------------------------------------------------------|
| `outputDir`                            | Not exposed — output directory is managed by the plugin (see below).  |
| `removeOperationIdPrefixDelimiter`     | Not implemented yet.                                                  |
| `removeOperationIdPrefixCount`         | Not implemented yet.                                                  |

`generateApiTests` / `generateApiDocumentation` / `generateModelTests` /
`generateModelDocumentation` are not exposed as dedicated settings — drive
them through `globalProperties` instead (`apiTests`, `apiDocs`,
`modelTests`, `modelDocs`), which is the same mechanism the upstream
generator uses. See
[`tests/suppress-test-generation/`](../tests/suppress-test-generation/) and
[`tests/generate-test-docs-controls/`](../tests/generate-test-docs-controls/)
for worked examples.

If you depend on one of the unsupported settings, please open an
[enhancement issue](https://gitlab.com/corthx/openapi-generator-kotlintoolchain-plugin/-/issues/new?issuable_template=Feature%20Request)
so it can be tracked — the migration guide will be updated to link to it.

## Behavioural differences

A few things behave differently from the Gradle plugin. None of them
require code changes, but they may surprise you on the first run.

### Output directory and source set wiring

The Gradle plugin writes to `$buildDir/generated/openapi` (configurable via
`outputDir`) and leaves source set wiring to you — typically a manual
`sourceSets["main"].java.srcDir(...)` and a `tasks.named("compileKotlin")
{ dependsOn("openApiGenerate") }` block.

This plugin manages the output directory internally and **automatically
registers the produced sources as source sets** — both Kotlin and Java,
main and test. There is no `outputDir` setting because there is nothing to
wire up: the compile tasks pick up the generated sources without manual
configuration.

If a generator produces test files (e.g. JUnit-based API tests), they land
in the module's test source set rather than the main one. Disable them via
`globalProperties: { apiTests: "false", modelTests: "false" }` if you do
not want them.

### Caching and incremental builds

The Gradle plugin participates in Gradle's task graph and caches outputs
through Gradle's build cache. This plugin uses the Kotlin Toolchain shared
cache: the generator only re-runs when its inputs change (the spec,
`inputSpecsDirectory` contents, `templateDir`, `ignoreFileOverride`, and
the configuration block itself). The cache directory can be redirected
with the `KOTLIN_SHARED_CACHE_DIR` environment variable.

In practice this means: editing a referenced spec under
`inputSpecsDirectory` invalidates the cache exactly like editing
`inputSpec` does — declare it so partial-spec edits are picked up.

### Multi-module projects

In Gradle, each subproject that needs generated code applies the plugin
and configures `openApiGenerate { ... }` independently. The Kotlin
Toolchain equivalent is the same: register the plugin once in
`project.yaml`, then enable and configure it in each module's
`module.yaml` that needs generated code. Modules without
`plugins.openapi-generator.enabled: true` are unaffected.

## Things you don't need anymore

When migrating, you can delete the following from your build:

- The `plugins { id("org.openapi.generator") version "…" }` block.
- Any `buildscript { ... }` block that exists only to pull in
  `openapi-generator-gradle-plugin` on the classpath.
- The entire `openApiGenerate { ... }` extension — its contents move to
  `module.yaml`.
- Manual source set wiring such as
  `sourceSets["main"].java.srcDir("$buildDir/generated/openapi/...")`.
- Manual task dependencies such as
  `tasks.named("compileKotlin") { dependsOn("openApiGenerate") }`.
- Any `outputDir` / `buildDir` plumbing tied to the generated sources path.
- Gradle itself, once all modules have moved off it — the Kotlin Toolchain
  build is driven by the `./kotlin` wrapper, with no `build.gradle(.kts)`
  or `settings.gradle(.kts)` required.
