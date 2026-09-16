#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# hashcheck.sh - the cross-check for XXH3-64 (slice 289).
#
# WHY IT IS A GATE OF ITS OWN. `Xxh3.hash64` decides the FILE THREAD IDS of a
# `--generateTrace` run: every `thread_name` and every parse/bind/emit event of
# trace.json carries `1000000 + hash64("file:" + path) % 1000000000`, so a wrong
# digit is a whole baseline. The two trace baselines between them reach ONE of
# the algorithm's six length classes - 0, 1..3, 4..8, 9..16, 17..128, 129..240
# and the accumulator loop past 240, whose block boundary is at 1024 - and an arm
# no input reaches is indistinguishable from a correct one (the same argument
# numcheck.sh makes for jsnum). So: one generated corpus, two producers, a byte
# diff.
#
#   ours       packages/tscaly/0.1.0/tscaly_hash.scaly + tscaly/HashCheck.scaly
#   reference  packages/tscaly/tests/oracle/hash.go, over zeebo/xxh3 - the very
#              package internal/tracing hashes its thread ids with
#
# The corpus is GENERATED here rather than committed, from a fixed seed, so the
# file both sides read is the same file. One line is one input string, verbatim -
# so it carries no newline and needs no escaping for anything else.
#
# Submodule discipline is run.sh's, for run.sh's reason: the submodule is also
# the test corpus, so it is checked clean on BOTH sides of the oracle build and
# the copy-in is removed again. The oracle must be built INSIDE it because
# zeebo/xxh3 is the submodule's own dependency.
#
# Usage:  packages/tscaly/tests/hashcheck.sh [count]      (default 20000)

set -u

cd "$(dirname "$0")/../../.."
REPO=$(pwd)

PKG=packages/tscaly
SUB=$PKG/_submodules/typescript-go
OUT=$PKG/tests/out/hash
COUNT=${1:-20000}

LIBSCALY=${LIBSCALY:-/tmp/libscaly.a}
SCALYC=${SCALYC:-$REPO/scalyc/build/scalyc}

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }

if [ ! -f "$SUB/go.mod" ]; then
  red "reference not present: the submodule is not initialized."
  echo "  git submodule update --init $SUB"
  exit 2
fi
if ! command -v go >/dev/null 2>&1; then
  red "oracle unavailable: no Go toolchain on PATH."
  echo "This is a missing dependency, not a test result - nothing was measured."
  exit 2
fi
if [ ! -x "$SCALYC" ]; then red "compiler not built: $SCALYC"; echo "  ./build.sh"; exit 2; fi
if [ ! -f "$LIBSCALY" ]; then red "runtime archive missing: $LIBSCALY"; exit 2; fi

submodule_dirty() { [ -n "$(git -C "$SUB" status --porcelain 2>/dev/null)" ]; }

if submodule_dirty; then
  red "the reference submodule has local changes - refusing to run."
  git -C "$SUB" status --short | sed 's/^/    /'
  exit 2
fi

mkdir -p "$OUT"

# -- the corpus ---------------------------------------------------------------
#
# Hand cases first, because a random generator does not produce the shapes a
# reader would think of - the empty string, every length from 1 to 20, the two
# inputs the trace baselines actually hash, and every BOUNDARY of the algorithm:
# 3/4, 8/9, 16/17, 128/129, 240/241, and the 1024-byte block the accumulator
# loop scrambles at. Then random bytes at random lengths, including lengths past
# several blocks.
python3 - "$COUNT" > "$OUT/corpus" <<'PYEOF'
import random, sys

count = int(sys.argv[1])
lines = []
seen = set()

def add(s):
    if "\n" in s or s in seen:
        return
    seen.add(s)
    lines.append(s)

# the two the trace baselines hash, and the checker thread's own key shape
add("file:/home/src/tslibs/TS/Lib/lib.es2025.full.d.ts")
add("file:/home/src/workspaces/project/a.ts")
add("checker:0")

# the empty string and every short length
add("")
for n in range(1, 21):
    add("a" * n)
    add("".join(chr(0x20 + ((i * 7) % 95)) for i in range(n)))

# every length boundary of the algorithm, from both sides
for n in (3, 4, 5, 8, 9, 16, 17, 32, 33, 64, 65, 96, 97, 128, 129,
          143, 144, 160, 176, 192, 208, 224, 240, 241, 255, 256,
          511, 512, 1023, 1024, 1025, 2047, 2048, 2049, 4096, 4097):
    add("x" * n)
    add("".join(chr(0x21 + (i % 94)) for i in range(n)))

r = random.Random(20260916)
alphabet = [chr(c) for c in range(0x20, 0x7f)]
while len(lines) < count:
    n = r.choice([r.randrange(0, 24), r.randrange(0, 260), r.randrange(0, 3000)])
    add("".join(r.choice(alphabet) for _ in range(n)))

sys.stdout.write("\n".join(lines) + "\n")
PYEOF

cases=$(wc -l < "$OUT/corpus" | tr -d ' ')

# -- the reference ------------------------------------------------------------
SUB_GITDIR=$(git -C "$SUB" rev-parse --absolute-git-dir 2>/dev/null)
if [ -n "$SUB_GITDIR" ] && [ -d "$SUB_GITDIR/info" ]; then
  grep -qx '/oracle/' "$SUB_GITDIR/info/exclude" 2>/dev/null \
    || echo '/oracle/' >> "$SUB_GITDIR/info/exclude"
fi

mkdir -p "$SUB/oracle/hash"
cp "$PKG/tests/oracle/hash.go" "$SUB/oracle/hash/main.go"
( cd "$SUB" && go build -o "$REPO/$OUT/oracle_hash" ./oracle/hash ) \
  > "$OUT/oracle-build.log" 2>&1
orc=$?
rm -rf "$SUB/oracle"
if [ $orc -ne 0 ]; then
  red "the hash oracle failed to build:"; sed 's/^/    /' "$OUT/oracle-build.log"; exit 2
fi
if submodule_dirty; then
  red "the submodule is dirty AFTER the oracle build - a bug in this script."
  git -C "$SUB" status --short | sed 's/^/    /'
  exit 2
fi

# -- our side -----------------------------------------------------------------
"$SCALYC" -c --no-prelude -o "$OUT/tscaly.o" "$PKG/0.1.0/tscaly.scaly" \
  > "$OUT/pkg-build.log" 2>&1
if [ $? -ne 0 ]; then
  red "the tscaly package failed to compile:"; sed 's/^/    /' "$OUT/pkg-build.log"; exit 2
fi
"$SCALYC" -c -o "$OUT/tscaly_hash.o" "$PKG/0.1.0/tscaly_hash.scaly" \
  > "$OUT/prog-build.log" 2>&1
if [ $? -ne 0 ]; then
  red "tscaly_hash failed to compile:"; sed 's/^/    /' "$OUT/prog-build.log"; exit 2
fi
clang -o "$OUT/tscaly_hash" "$OUT/tscaly_hash.o" "$OUT/tscaly.o" "$LIBSCALY" -lm \
  > "$OUT/link.log" 2>&1
if [ $? -ne 0 ]; then
  red "the tscaly_hash link failed:"; sed 's/^/    /' "$OUT/link.log"; exit 2
fi

# -- the comparison -----------------------------------------------------------
#
# No pipeline around either binary: `rc=$?` after `$(prog | ...)` reads the last
# stage's status (root CLAUDE.md's harness rule).
"$OUT/oracle_hash" "$OUT/corpus" > "$OUT/ref" 2> "$OUT/ref.err"
rrc=$?
"$OUT/tscaly_hash" "$OUT/corpus" > "$OUT/ours" 2> "$OUT/ours.err"
orc=$?
if [ $rrc -ne 0 ]; then
  red "the oracle exited $rrc - suspect the harness, not the port:"
  sed 's/^/    /' "$OUT/ref.err"; exit 2
fi
if [ $orc -ne 0 ]; then
  red "tscaly_hash exited $orc:"; sed 's/^/    /' "$OUT/ours.err"; exit 1
fi

diff "$OUT/ref" "$OUT/ours" > "$OUT/diff" 2>&1
if [ $? -ne 0 ]; then
  n=$(grep -c '^<' "$OUT/diff")
  red "$n of $cases inputs differ from the reference:"
  head -20 "$OUT/diff" | sed 's/^/    /'
  echo "  full diff: $OUT/diff (the corpus line numbers are $OUT/corpus's)"
  exit 1
fi

green "OK - $cases inputs, byte-identical to the reference's own xxh3."
