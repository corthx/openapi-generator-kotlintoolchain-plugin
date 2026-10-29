# Migrating from the OpenAPI Generator Maven plugin

This guide is for projects currently using the official
[`openapi-generator-maven-plugin`](https://github.com/OpenAPITools/openapi-generator/tree/master/modules/openapi-generator-maven-plugin)
that want to move to this Kotlin Toolchain plugin.

It walks through what changes in your build configuration, how each Maven
plugin `<configuration>` key maps to a `module.yaml` setting, and which
behavioural differences are worth knowing about.

> For migrating from the Gradle plugin, see
> [docs/migration-from-gradle-plugin.md](migration-from-gradle-plugin.md).

## Before / after

A representative Ktor client setup using the Maven plugin — `pom.xml`
declares the generator, binds it to the `generate-sources` phase, and uses
`build-helper-maven-plugin` to register the produced sources as a Maven
source root:

```xml
<!-- pom.xml -->
<build>
  <plugins>
    <plugin>
      <groupId>org.openapitools</groupId>
      <artifactId>openapi-generator-maven-plugin</artifactId>
      <version>7.10.0</version>
      <executions>
        <execution>
          <goals>
            <goal>generate</goal>
          </goals>
          <configuration>
            <generatorName>kotlin</generatorName>
            <inputSpec>${project.basedir}/src/main/resources/openapi/test-api.yml</inputSpec>
            <output>${project.build.directory}/generated-sources/openapi</output>
            <apiPackage>com.example.api</apiPackage>
            <modelPackage>com.example.model</modelPackage>
          </configuration>
        </execution>
      </executions>
    </plugin>

    <plugin>
      <groupId>org.codehaus.mojo</groupId>
      <artifactId>build-helper-maven-plugin</artifactId>
      <version>3.6.0</version>
      <executions>
        <execution>
          <phase>generate-sources</phase>
          <goals>
            <goal>add-source</goal>
          </goals>
          <configuration>
            <sources>
              <source>${project.build.directory}/generated-sources/openapi/src/main/kotlin</source>
            </sources>
          </configuration>
        </execution>
      </executions>
    </plugin>
  </plugins>
</build>

<dependencies>
  <dependency>
    <groupId>com.squareup.okhttp3</groupId>
    <artifactId>okhttp</artifactId>
    <version>4.12.0</version>
  </dependency>
  <dependency>
    <groupId>com.squareup.moshi</groupId>
    <artifactId>moshi-kotlin</artifactId>
    <version>1.15.2</version>
  </dependency>
</dependencies>
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

Source set wiring and the lifecycle binding are handled automatically.
A `./kotlin build` triggers generation as needed; you can also run the
action explicitly with `./kotlin run generateOpenAPI`.

A working end-to-end example lives in
[`tests/simple-ktor-client/`](../tests/simple-ktor-client/). The same shape
applies to a Ktor server setup — switch `generatorName` to `kotlin-server`
and set `library: jvm-ktor` (see the [Ktor server library docs](https://openapi-generator.tech/docs/generators/kotlin-server))
— but no dedicated server test project ships with the plugin yet.

## Settings mapping

Maven plugin options live inside `<configuration>` under
`<plugin><artifactId>openapi-generator-maven-plugin</artifactId>…</plugin>`.
Toolchain settings live under `plugins.openapi-generator` in `module.yaml`.

### Direct one-to-one mappings

| Maven `<configuration>` key  | `module.yaml` setting        | Notes                                                                |
|------------------------------|------------------------------|----------------------------------------------------------------------|
| `generatorName`              | `generatorName`              | Same values (e.g. `kotlin`, `kotlin-server`, `java`, …).             |
| `inputSpec` (local file)     | `inputSpec`                  | Path resolved relative to module root, not `${project.basedir}`.     |
| `inputSpec` (URL)            | `remoteInputSpec`            | Split out into a separate setting; mutually exclusive.               |
| `auth`                       | `auth`                       | Used when fetching `remoteInputSpec`.                                |
| `httpUserAgent`              | `httpUserAgent`              | Used when fetching `remoteInputSpec`.                                |
| `verbose`                    | `verbose`                    |                                                                      |
| `logToStderr`                | `logToStderr`                |                                                                      |
| `dryRun`                     | `dryRun`                     |                                                                      |
| `validateSpec`               | `validateSpec`               |                                                                      |
| `skipValidateSpec`           | `skipValidateSpec`           |                                                                      |
| `cleanupOutput`              | `cleanupOutput`              |                                                                      |
| `skipOverwrite`              | `skipOverwrite`              |                                                                      |
| `globalProperties`           | `globalProperties`           | Same `Map<String, String>` shape.                                    |
| `configOptions`              | `configOptions`              |                                                                      |
| `additionalProperties`       | `additionalProperties`       |                                                                      |
| `packageName`                | `packageName`                |                                                                      |
| `apiPackage`                 | `apiPackage`                 |                                                                      |
| `modelPackage`               | `modelPackage`               |                                                                      |
| `invokerPackage`             | `invokerPackage`             |                                                                      |
| `modelNamePrefix`            | `modelNamePrefix`            |                                                                      |
| `modelNameSuffix`            | `modelNameSuffix`            |                                                                      |
| `apiNameSuffix`              | `apiNameSuffix`              |                                                                      |
| `groupId`                    | `groupId`                    |                                                                      |
| `library`                    | `library`                    |                                                                      |
| `gitHost`                    | `gitHost`                    |                                                                      |
| `gitUserId`                  | `gitUserId`                  |                                                                      |
| `gitRepoId`                  | `gitRepoId`                  |                                                                      |
| `releaseNote`                | `releaseNote`                |                                                                      |
| `typeMappings`               | `typeMappings`               |                                                                      |
| `instantiationTypes`         | `instantiationTypes`         |                                                                      |
| `importMappings`             | `importMappings`             |                                                                      |
| `languageSpecificPrimitives` | `languageSpecificPrimitives` | YAML list (e.g. `[Instant, LocalDate]`).                             |
| `nameMappings`               | `nameMappings`               |                                                                      |
| `parameterNameMappings`      | `parameterNameMappings`      |                                                                      |
| `modelNameMappings`          | `modelNameMappings`          |                                                                      |
| `enumNameMappings`           | `enumNameMappings`           |                                                                      |
| `operationIdNameMappings`    | `operationIdNameMappings`    |                                                                      |
| `schemaMappings`             | `schemaMappings`             |                                                                      |
| `inlineSchemaNameMappings`   | `inlineSchemaNameMappings`   |                                                                      |
| `inlineSchemaOptions`        | `inlineSchemaOptions`        |                                                                      |
| `reservedWordsMappings`      | `reservedWordsMappings`      |                                                                      |
| `serverVariables`            | `serverVariables`            |                                                                      |
| `openapiNormalizer`          | `openapiNormalizer`          |                                                                      |
| `removeOperationIdPrefix`    | `removeOperationIdPrefix`    |                                                                      |
| `skipOperationExample`       | `skipOperationExample`       |                                                                      |
| `enablePostProcessFile`      | `enablePostProcessFile`      |                                                                      |
| `ignoreFileOverride`         | `ignoreFileOverride`         | Path to a custom `.openapi-generator-ignore` file.                   |
| `openapiGeneratorIgnoreList` | `openapiGeneratorIgnoreList` | YAML list of gitignore-style patterns.                               |

### Renamed / restructured

| Maven `<configuration>` key | `module.yaml` setting | What changed                                                              |
|-----------------------------|-----------------------|---------------------------------------------------------------------------|
| `inputSpecRootDirectory`    | `inputSpecsDirectory` | Same purpose (directory of `$ref`-able specs); name slightly different.   |
| `inputSpec` (URL value)     | `remoteInputSpec`     | Remote specs use a dedicated setting; pair with `auth` / `httpUserAgent`. |
| `configurationFile`         | `configFile`          | JSON file; inline settings override file values.                          |
| `templateDirectory`         | `templateDir`         | Resolved relative to the module root.                                     |
| `engine`                    | `templateEngine`      | `mustache` (default) or `handlebars`.                                     |
| `artifactId`                | `id`                  | ArtifactId written into generated build scripts.                          |
| `artifactVersion`           | `version`             | Artifact version written into generated build scripts.                    |
| `skip`                      | `enabled` (inverted)  | Disable generation for a module via `enabled: false`.                     |

### No equivalent (yet)

| Maven `<configuration>` key        | Status                                                                |
|------------------------------------|-----------------------------------------------------------------------|
| `output`                           | Not exposed — output directory is managed by the plugin (see below).  |
| `templateResourcePath`             | Not implemented yet.                                                  |
| `removeOperationIdPrefixDelimiter` | Not implemented yet.                                                  |
| `removeOperationIdPrefixCount`     | Not implemented yet.                                                  |
| `skipIfSpecIsUnchanged`            | Not needed — caching is automatic (see below).                        |
| `addCompileSourceRoot`             | Not needed — source-root wiring is automatic (see below).             |
| `addTestCompileSourceRoot`         | Not needed — source-root wiring is automatic (see below).             |

`generateApis` / `generateApiTests` / `generateApiDocumentation` /
`generateModels` / `generateModelTests` / `generateModelDocumentation` /
`generateSupportingFiles` are not exposed as dedicated settings — drive
them through `globalProperties` instead (`apis`, `apiTests`, `apiDocs`,
`models`, `modelTests`, `modelDocs`, `supportingFiles`), which is the same
mechanism the upstream generator uses. See
[`tests/suppress-test-generation/`](../tests/suppress-test-generation/) and
[`tests/generate-test-docs-controls/`](../tests/generate-test-docs-controls/)
for worked examples.

If you depend on one of the unsupported settings, please open an
[enhancement issue](https://gitlab.com/corthx/openapi-generator-kotlintoolchain-plugin/-/issues/new?issuable_template=Feature%20Request)
so it can be tracked — the migration guide will be updated to link to it.

## Behavioural differences

A few things behave differently from the Maven plugin. None of them
require code changes, but they may surprise you on the first run.

### Lifecycle binding and when generation runs

The Maven plugin runs through a `<execution>` bound to a Maven lifecycle
phase — usually `generate-sources` — and is invoked whenever Maven walks
through that phase (`mvn compile`, `mvn package`, `mvn test`, …).

This plugin slots into the Kotlin Toolchain build pipeline directly: a
`./kotlin build` (or `./kotlin test`) walks the module graph and runs
`generateOpenAPI` for each module where the plugin is enabled, before
compilation. There is no phase to bind to and no `<execution>` block — the
plugin's presence and `enabled: true` are the only declaration needed.

You can also invoke the action standalone with
`./kotlin run generateOpenAPI`, equivalent to running
`mvn openapi-generator:generate` on its own.

### Output directory and source-root wiring

The Maven plugin writes to `${project.build.directory}/generated-sources/openapi`
(configurable via `<output>`) and, by default, registers that path as a
Maven source root via `addCompileSourceRoot`/`addTestCompileSourceRoot`.
Wiring it into a Kotlin source set typically still requires
`build-helper-maven-plugin` `add-source` executions.

This plugin manages the output directory internally and **automatically
registers the produced sources as source sets** — both Kotlin and Java,
main and test. There is no `output` setting because there is nothing to
wire up: the compile tasks pick up the generated sources without any
`build-helper-maven-plugin` plumbing.

If a generator produces test files (e.g. JUnit-based API tests), they land
in the module's test source set rather than the main one. Disable them via
`globalProperties: { apiTests: "false", modelTests: "false" }` if you do
not want them.

### Caching and incremental builds

The Maven plugin offers `skipIfSpecIsUnchanged` to avoid regenerating when
the spec file hasn't changed, but otherwise re-runs on every Maven
invocation. This plugin uses the Kotlin Toolchain shared cache: the
generator only re-runs when its inputs change (the spec,
`inputSpecsDirectory` contents, `templateDir`, `ignoreFileOverride`, and
the configuration block itself). The cache directory can be redirected
with the `KOTLIN_SHARED_CACHE_DIR` environment variable.

In practice this means: editing a referenced spec under
`inputSpecsDirectory` invalidates the cache exactly like editing
`inputSpec` does — declare it so partial-spec edits are picked up.

### Multiple specs in a single project

In Maven, multiple specs are typically generated by adding multiple
`<execution>` blocks under the same plugin declaration, each with its own
`<configuration>` and `<id>`.

The Kotlin Toolchain equivalent is **one module per spec**: register the
plugin once in `project.yaml`, then create a module per spec with its own
`module.yaml` that configures `plugins.openapi-generator` for that spec.
This matches how the toolchain encourages decomposing larger projects and
keeps generated sources scoped to the module that owns them.

### Multi-module projects

In Maven, each submodule that needs generated code declares the plugin in
its own `pom.xml` (or inherits it from a parent and re-declares the
`<execution>` it needs). The Kotlin Toolchain equivalent is the same:
register the plugin once in `project.yaml`, then enable and configure it
in each module's `module.yaml` that needs generated code. Modules without
`plugins.openapi-generator.enabled: true` are unaffected.

## Things you don't need anymore

When migrating, you can delete the following from your build:

- The `<plugin><artifactId>openapi-generator-maven-plugin</artifactId>…</plugin>`
  declaration and any surrounding `<executions>` / `<execution>` blocks.
- The `<plugin><artifactId>build-helper-maven-plugin</artifactId>…</plugin>`
  declaration when it exists only to add the generator's output as a
  source root.
- Any `<output>` / `${project.build.directory}` plumbing tied to the
  generated sources path.
- `<skipIfSpecIsUnchanged>` settings — incremental rebuilds are handled
  by the shared cache.
- `<addCompileSourceRoot>` / `<addTestCompileSourceRoot>` settings —
  source-set registration is automatic.
- Maven itself, once all modules have moved off it — the Kotlin Toolchain
  build is driven by the `./kotlin` wrapper, with no `pom.xml` required.
