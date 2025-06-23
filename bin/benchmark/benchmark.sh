#!/usr/bin/env bash

# Verify that there are no failing benchmarks.
mapfile -t FAILURES < <(dart run bin/benchmark/benchmark.dart --no-benchmark | grep -v OK)
if [[ ${#FAILURES[@]} -gt 0 ]]; then
  for NAME in "${FAILURES[@]}"; do
    echo "- $NAME"
  done
  exit 1
fi

# Run all the benchmarks in a separate process.
mapfile -t NAMES < <(dart run bin/benchmark/benchmark.dart --no-benchmark --no-verify)
for NAME in "${NAMES[@]}"; do
  dart run --no-enable-asserts bin/benchmark/benchmark.dart --filter="$NAME" --separator=";" --no-human --confidence
  sleep 1
done
