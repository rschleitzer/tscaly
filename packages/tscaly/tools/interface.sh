#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# interface.sh -- the package's generated interface, 0.1.0/interface/.
#
# A program that uses the package tscaly loads it through this interface: the
# module tree with every non-generic body left out, and what a caller needs to
# know about each routine written beside its signature. It is generated from
# the sources by the compiler and committed, so it has to be regenerated
# whenever the sources change.
#
#   packages/tscaly/tools/interface.sh           write it
#   packages/tscaly/tools/interface.sh --check   say whether it is current
#
# Takes about 35 s and 6.5 GB.
set -u
cd "$(dirname "$0")/../../.."
. packages/tscaly/tests/toolchain.sh || exit 2
OUT=packages/tscaly/0.1.0/interface
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
if ! ( ulimit -s 65520 2>/dev/null; "$SCALYC" --emit-interface -o "$T/interface" packages/tscaly/0.1.0/tscaly.scaly ) > "$T/out" 2>&1; then
  echo "interface: FAIL"; head -5 "$T/out"; exit 1
fi
if [ "${1:-}" = "--check" ]; then
  if diff -r -q "$OUT" "$T/interface" > "$T/diff" 2>&1; then
    echo "interface: current"
  else
    echo "interface: STALE -- run packages/tscaly/tools/interface.sh"; head -5 "$T/diff"; exit 1
  fi
else
  rm -rf "$OUT" && mv "$T/interface" "$OUT" && echo "interface: written"
fi
