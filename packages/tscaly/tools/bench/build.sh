#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# build.sh — tscaly_exec as a whole-program `opt -O2` binary, for measurement.
#
#   packages/tscaly/tools/bench/build.sh [out-binary] [scalyc-binary]
#     out-binary     default: packages/tscaly/tests/out/tscaly_exec_o2
#     scalyc-binary  default: scalyc/build/scalyc
#
# The yardsticks build their programs at the default opt level (none); a time
# measured on that binary is several times too slow to compare with tsgo.
# Same pipeline as tests/dazzle/build-cli.sh: program, package and runtime IR,
# merged and optimized by tools/link-lto.sh.
#
# ★ Build to a path no running measurement uses: overwriting a binary under a
# live process invalidates its code signature on macOS and kills it.
# ★ scalyc peaks at ~6.5 GB here; never build while a measurement runs.

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../../../.." && pwd)"
OUT="${1:-$ROOT/packages/tscaly/tests/out/tscaly_exec_o2}"
BIN="${2:-$ROOT/scalyc/build/scalyc}"
cd "$ROOT"
ulimit -s 65520

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

t0=$(date +%s)
"$BIN" -S --no-prelude --no-tests -o "$WORK/scaly_rt.ll" packages/scaly/0.1.0/scaly.scaly > "$WORK/rt.log" 2>&1 \
  || { echo "bench build: FAIL (runtime)"; tail -5 "$WORK/rt.log"; exit 1; }
"$BIN" -S --no-prelude -o "$WORK/tscaly.ll" packages/tscaly/0.1.0/tscaly.scaly > "$WORK/pkg.log" 2>&1 \
  || { echo "bench build: FAIL (package)"; tail -5 "$WORK/pkg.log"; exit 1; }
"$BIN" -S -o "$WORK/tscaly_exec.ll" packages/tscaly/0.1.0/tscaly_exec.scaly > "$WORK/prog.log" 2>&1 \
  || { echo "bench build: FAIL (program)"; tail -5 "$WORK/prog.log"; exit 1; }
echo "bench build: IR emitted in $(( $(date +%s) - t0 ))s"
tools/link-lto.sh "$OUT" "$WORK/tscaly_exec.ll" "$WORK/tscaly.ll" "$WORK/scaly_rt.ll" \
  || { echo "bench build: FAIL (link-lto rc=$?)"; exit 1; }
echo "bench build: $OUT in $(( $(date +%s) - t0 ))s"
