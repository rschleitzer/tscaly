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
# `scaly build --release`: program, package and runtime as one module at -O2
# (until 2026-10-01 three IR emissions merged by tools/link-lto.sh; measured
# against that binary on the whole of VS Code, three alternating rounds: wall
# 4.9-5.0 s both, user 15.2-15.4 against 15.4-15.7 s, footprint 8.69 GB both,
# the 1 872 output lines identical).
#
# ★ Build to a path no running measurement uses: overwriting a binary under a
# live process invalidates its code signature on macOS and kills it.
# ★ scalyc peaks at ~6.5 GB here; never build while a measurement runs.

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../../../.." && pwd)"
OUT="${1:-$ROOT/packages/tscaly/tests/out/tscaly_exec_o2}"
BIN="${2:-$ROOT/scalyc/build/scalyc}"
# the tool beside the compiler: scaly for REPL/run/build/test, scalyc for the flags
SCALY=$("$ROOT/tools/scaly-of.sh" "$BIN")
cd "$ROOT"
ulimit -s 65520

t0=$(date +%s)
"$SCALY" build packages/tscaly/0.1.0/tscaly_exec.scaly --release -o "$OUT" \
  || { echo "bench build: FAIL (rc=$?)"; exit 1; }
echo "bench build: $OUT in $(( $(date +%s) - t0 ))s"
