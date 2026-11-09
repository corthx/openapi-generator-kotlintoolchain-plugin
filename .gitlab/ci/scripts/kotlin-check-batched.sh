#!/usr/bin/env bash
# Runs `./kotlin check` over the project's modules in batches.
#
# A single `./kotlin check` forks one JUnit JVM per test module, all at
# once (~25 for this project), on top of the ~2 GB CLI JVM. That peaks
# above 7 GB and the runner OOM-kills the job (exit code 137). Batching
# bounds the number of concurrent test JVMs, keeping the peak around
# 2.5 GB, at the cost of one CLI startup per batch.
#
# Workaround for https://youtrack.jetbrains.com/issue/KTC-6094: test
# tasks don't count against the toolchain's parallelism limit, and no
# setting caps them. Remove this script once it's fixed (#61).
#
# Module list: plugin-core plus every tests/* module, mirroring the
# `modules:` globs in project.yaml. Keep the two in sync.

set -euo pipefail

batch_size="${KOTLIN_CHECK_BATCH_SIZE:-6}"

modules=(plugin-core)
for module_file in tests/*/module.yaml; do
  modules+=("$(basename "$(dirname "$module_file")")")
done

for ((i = 0; i < ${#modules[@]}; i += batch_size)); do
  args=()
  for module in "${modules[@]:i:batch_size}"; do
    args+=(--module "$module")
  done
  echo "Checking modules: ${modules[*]:i:batch_size}"
  ./kotlin check "${args[@]}"
done
