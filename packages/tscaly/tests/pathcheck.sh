#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# pathcheck.sh — the cross-check for tspath's absolute-path arms (slice 28).
#
# WHY IT IS A GATE OF ITS OWN. The binder names an external module's symbol
# `"` + RemoveFileExtension(GetNormalizedAbsolutePath(fileName, cwd)) + `"`, so
# the four yardsticks DO compare that string — once per unit, in exactly one
# shape: a clean repo-relative path under a clean absolute working directory.
# The function's root scanner distinguishes POSIX, UNC, a DOS volume, `^/` and
# two kinds of URL, and its segment loop folds `.`, `..`, doubled and trailing
# separators. No path any corpus produces reaches those arms, and an unexercised
# arm is indistinguishable from a correct one — so they get their own instrument:
# one generated corpus, two producers, a byte diff.
#
#   ours       packages/tscaly/0.1.0/tscaly_paths.scaly + tscaly/PathCheck.scaly
#   reference  packages/tscaly/tests/oracle/paths.go, over the submodule's tspath
#
# The corpus is GENERATED here rather than committed, from a fixed seed, so the
# file both sides read is the same file and a wider corpus is one number away.
#
# Submodule discipline is run.sh's, for run.sh's reason: the submodule is also
# the test corpus, so it is checked clean on BOTH sides of the oracle build and
# the copy-in is removed again.
#
# Usage:  packages/tscaly/tests/pathcheck.sh [count]      (default 20000)

set -u

cd "$(dirname "$0")/../../.."
REPO=$(pwd)

PKG=packages/tscaly
SUB=$PKG/_submodules/typescript-go
OUT=$PKG/tests/out/paths
COUNT=${1:-20000}

. packages/tscaly/tests/toolchain.sh || exit 2

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }

if [ ! -f "$SUB/go.mod" ]; then
  red "reference not present: the submodule is not initialized."
  echo "  git submodule update --init $SUB"
  exit 2
fi
if ! command -v go >/dev/null 2>&1; then
  red "oracle unavailable: no Go toolchain on PATH."
  echo "This is a missing dependency, not a test result — nothing was measured."
  exit 2
fi
if [ ! -x "$SCALYC" ]; then red "compiler not built: $SCALYC"; echo "  ./build.sh"; exit 2; fi
if [ ! -f "$LIBSCALY" ]; then red "runtime archive missing: $LIBSCALY"; exit 2; fi

submodule_dirty() { [ -n "$(git -C "$SUB" status --porcelain 2>/dev/null)" ]; }

if submodule_dirty; then
  red "the reference submodule has local changes — refusing to run."
  git -C "$SUB" status --short | sed 's/^/    /'
  exit 2
fi

mkdir -p "$OUT"

# ── the corpus ───────────────────────────────────────────────────────────────
#
# Hand cases first, because a random generator does not produce the shapes a
# reader would think of; then the random ones, whose alphabet is chosen so that
# every arm of the root scanner and every branch of the segment loop is reachable.
python3 - "$COUNT" > "$OUT/corpus" <<'PYEOF'
import random, sys

count = int(sys.argv[1])

names = [
    "", ".", "..", "a", "a/b", "a/b/c.ts", "./a", "../a", "a/./b", "a/../b",
    "a//b", "a/b/", "a/b//", "/", "//", "///", "/a", "/a/b", "/a/../b",
    "/../a", "/./a", "/a/b/../../../c", "a/../../b", "../../a",
    "c:", "c:/", "c:/a/b", "c:\\a\\b", "c:/a/../b", "//server", "//server/",
    "//server/share/a", "^/untitled/x", "file:///c:/a", "file://server/a",
    "file://localhost/c:/a", "file:///c%3a/a", "http://server",
    "http://server/a/../b", "a\\b", "\\a", "\\\\s\\h\\a",
    "a/b/./../c/", "x/y/z/../../..", "x/y/z/../../../..", "/x/y/../../..",
    ".hidden", "a.d.ts", "u00_b.d.ts", "u01_a.tsx", "p.json", "q.d.mts",
    "r.cjs", "s.mjs", "t.jsx", "u.tsbuildinfo", "v.ts.ts",
]
cwds = [
    "", "/", "/root", "/root/", "/a/b", "c:/w", "c:\\w", "//server/share",
    "relative/cwd", ".", "..", "http://h", "^/untitled",
]

lines = []
for n in names:
    for c in cwds:
        lines.append(c + "\t" + n)

segs = ["a", "bb", "", ".", "..", "c:", "x.ts", "y.d.ts", "z.json", "d"]
roots = ["", "/", "//", "c:/", "//server/", "^/", "file:///c:/", "http://h/",
         "\\", "\\\\s\\"]
r = random.Random(20260819)
while len(lines) < count:
    p = r.choice(roots)
    n = r.randrange(6)
    parts = []
    for j in range(n):
        parts.append(r.choice(segs))
    p += ("/" * r.randrange(1, 3)).join(parts)
    if r.randrange(4) == 0:
        p += "/"
    lines.append(r.choice(cwds) + "\t" + p)

sys.stdout.write("\n".join(lines) + "\n")
PYEOF

cases=$(wc -l < "$OUT/corpus" | tr -d ' ')

# ── the reference ────────────────────────────────────────────────────────────
SUB_GITDIR=$(git -C "$SUB" rev-parse --absolute-git-dir 2>/dev/null)
if [ -n "$SUB_GITDIR" ] && [ -d "$SUB_GITDIR/info" ]; then
  grep -qx '/oracle/' "$SUB_GITDIR/info/exclude" 2>/dev/null \
    || echo '/oracle/' >> "$SUB_GITDIR/info/exclude"
fi

mkdir -p "$SUB/oracle/paths"
cp "$PKG/tests/oracle/paths.go" "$SUB/oracle/paths/main.go"
( cd "$SUB" && go build -o "$REPO/$OUT/oracle_paths" ./oracle/paths ) \
  > "$OUT/oracle-build.log" 2>&1
orc=$?
rm -rf "$SUB/oracle"
if [ $orc -ne 0 ]; then
  red "the paths oracle failed to build:"; sed 's/^/    /' "$OUT/oracle-build.log"; exit 2
fi
if submodule_dirty; then
  red "the submodule is dirty AFTER the oracle build — a bug in this script."
  git -C "$SUB" status --short | sed 's/^/    /'
  exit 2
fi

# ── our side ─────────────────────────────────────────────────────────────────
"$SCALYC" -c --no-prelude -o "$OUT/tscaly.o" "$PKG/0.1.0/tscaly.scaly" \
  > "$OUT/pkg-build.log" 2>&1
if [ $? -ne 0 ]; then
  red "the tscaly package failed to compile:"; sed 's/^/    /' "$OUT/pkg-build.log"; exit 2
fi
"$SCALYC" -c -o "$OUT/tscaly_paths.o" "$PKG/0.1.0/tscaly_paths.scaly" \
  > "$OUT/prog-build.log" 2>&1
if [ $? -ne 0 ]; then
  red "tscaly_paths failed to compile:"; sed 's/^/    /' "$OUT/prog-build.log"; exit 2
fi
clang -o "$OUT/tscaly_paths" "$OUT/tscaly_paths.o" "$OUT/tscaly.o" "$LIBSCALY" -lm \
  > "$OUT/link.log" 2>&1
if [ $? -ne 0 ]; then
  red "the tscaly_paths link failed:"; sed 's/^/    /' "$OUT/link.log"; exit 2
fi

# ── the comparison ───────────────────────────────────────────────────────────
#
# No pipeline around either binary: `rc=$?` after `$(prog | …)` reads the last
# stage's status.
"$OUT/oracle_paths" "$OUT/corpus" > "$OUT/ref" 2> "$OUT/ref.err"
rrc=$?
"$OUT/tscaly_paths" "$OUT/corpus" > "$OUT/ours" 2> "$OUT/ours.err"
orc=$?
if [ $rrc -ne 0 ]; then
  red "the oracle exited $rrc — suspect the harness, not the port:"
  sed 's/^/    /' "$OUT/ref.err"; exit 2
fi
if [ $orc -ne 0 ]; then
  red "tscaly_paths exited $orc:"; sed 's/^/    /' "$OUT/ours.err"; exit 1
fi

diff "$OUT/ref" "$OUT/ours" > "$OUT/diff" 2>&1
if [ $? -ne 0 ]; then
  n=$(grep -c '^<' "$OUT/diff")
  red "$n of $cases paths differ from the reference:"
  head -20 "$OUT/diff" | sed 's/^/    /'
  echo "  full diff: $OUT/diff (the corpus line numbers are $OUT/corpus's)"
  exit 1
fi

green "OK — $cases paths, byte-identical to the reference's own tspath."
