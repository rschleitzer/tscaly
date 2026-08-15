#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# run.sh — the scanner yardstick.
#
# Scans each case with OUR scanner and with the REFERENCE scanner, and compares
# the token streams token for token: kind, start, end, flags. The reference is
# built from the pinned submodule, so "green" means our scanner agrees with the
# TypeScript compiler's, not with an expectation someone typed.
#
# Three outcomes per case, and the third is the point:
#
#   MATCH      identical token streams
#   UNPORTED   our scanner met a construct this slice does not implement and
#              said so; no claim is made about the case
#   FAIL       the streams differ, and no accepted.txt entry explains it
#
# UNPORTED is not a pass. It is counted, printed, and the totals show it — an
# incomplete port that reported "all green" would be worth less than no runner.
#
# Usage:  packages/tscaly/tests/run.sh [filter]
#
# Harness rules observed here, each one paid for by an earlier suite in this repo
# (root CLAUDE.md): no `git checkout -- .`; a per-case scratch directory; no
# pipeline around a binary whose exit code is read; nothing writes to an absolute
# POSIX path.

set -u

cd "$(dirname "$0")/../../.."
REPO=$(pwd)

PKG=packages/tscaly
SUB=$PKG/_submodules/typescript-go
OUT=$PKG/tests/out
ACCEPTED=$PKG/tests/accepted.txt
FILTER=${1:-}

LIBSCALY=${LIBSCALY:-/tmp/libscaly.a}
SCALYC=${SCALYC:-$REPO/scalyc/build/scalyc}

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }

# ── preconditions ────────────────────────────────────────────────────────────
# Each one reports what is missing and how to get it. A runner that dies with a
# tool's own error message makes the caller diagnose the harness instead of the
# port.

if [ ! -f "$SUB/go.mod" ]; then
  red "corpus not present: the reference submodule is not initialized."
  echo "  git submodule update --init $SUB"
  exit 2
fi

if ! command -v go >/dev/null 2>&1; then
  red "oracle unavailable: no Go toolchain on PATH (the reference needs go 1.26)."
  echo "  brew install go        # or however this machine installs it"
  echo
  echo "This is a missing dependency, not a test result — nothing was measured."
  exit 2
fi

if [ ! -x "$SCALYC" ]; then
  red "compiler not built: $SCALYC"
  echo "  ./build.sh"
  exit 2
fi

if [ ! -f "$LIBSCALY" ]; then
  red "runtime archive missing: $LIBSCALY"
  echo "  see the recipe in the root CLAUDE.md, or set LIBSCALY=<path>"
  exit 2
fi

mkdir -p "$OUT"

# ── build the oracle ─────────────────────────────────────────────────────────
#
# The oracle source is ours and lives in this repository, but it can only be
# BUILT from inside the submodule's module: every upstream package is under
# internal/, and Go admits those imports only from within the module rooted
# above internal/. So it is copied in, built, and removed again — inward only,
# and the submodule is checked clean on both sides of that.

submodule_dirty() {
  [ -n "$(git -C "$SUB" status --porcelain 2>/dev/null)" ]
}

if submodule_dirty; then
  red "the reference submodule has local changes — refusing to run."
  git -C "$SUB" status --short | sed 's/^/    /'
  echo
  echo "  A submodule carrying edits no longer says what the pin says, and every"
  echo "  comparison against it is worthless. Clean it, then re-run."
  exit 2
fi

# Keep a stray copy from a killed run out of the submodule's own git status.
#
# ★ A submodule's `.git` is a FILE holding a gitdir: pointer, not a directory —
# so "$SUB/.git/info/exclude" is "Not a directory", not a path that can be
# appended to. Ask git where its directory actually is.
SUB_GITDIR=$(git -C "$SUB" rev-parse --absolute-git-dir 2>/dev/null)
if [ -n "$SUB_GITDIR" ] && [ -d "$SUB_GITDIR/info" ]; then
  grep -qx '/oracle/' "$SUB_GITDIR/info/exclude" 2>/dev/null \
    || echo '/oracle/' >> "$SUB_GITDIR/info/exclude"
fi

mkdir -p "$SUB/oracle"
cp "$PKG/tests/oracle/tokens.go" "$SUB/oracle/main.go"
( cd "$SUB" && go build -o "$REPO/$OUT/oracle_tokens" ./oracle ) > "$OUT/oracle-build.log" 2>&1
orc=$?
rm -rf "$SUB/oracle"

if [ $orc -ne 0 ]; then
  red "the oracle failed to build:"
  sed 's/^/    /' "$OUT/oracle-build.log"
  exit 2
fi

if submodule_dirty; then
  red "the reference submodule is dirty AFTER the oracle build — this is a bug in"
  red "this script, and every result it would print is untrustworthy."
  git -C "$SUB" status --short | sed 's/^/    /'
  exit 2
fi

# ── build our side ───────────────────────────────────────────────────────────
#
# Two objects, the way the opensp drop-in is built: the package object carries
# the bodies, the program object the entry point.

"$SCALYC" -c --no-prelude -o "$OUT/tscaly.o" "$PKG/0.1.0/tscaly.scaly" \
  > "$OUT/pkg-build.log" 2>&1
if [ $? -ne 0 ]; then
  red "the tscaly package failed to compile:"; sed 's/^/    /' "$OUT/pkg-build.log"; exit 2
fi

"$SCALYC" -c -o "$OUT/tscaly_tokens.o" "$PKG/0.1.0/tscaly_tokens.scaly" \
  > "$OUT/prog-build.log" 2>&1
if [ $? -ne 0 ]; then
  red "tscaly_tokens failed to compile:"; sed 's/^/    /' "$OUT/prog-build.log"; exit 2
fi

clang -o "$OUT/tscaly_tokens" "$OUT/tscaly_tokens.o" "$OUT/tscaly.o" "$LIBSCALY" -lm \
  > "$OUT/link.log" 2>&1
if [ $? -ne 0 ]; then
  red "the link failed:"; sed 's/^/    /' "$OUT/link.log"; exit 2
fi

# ── the cases ────────────────────────────────────────────────────────────────
#
# Our own fixtures first — small, and each one aimed at a specific construct —
# then the repo-local corpus cases, read in place out of the submodule.

# ★ conformance/ is NESTED — a flat glob finds 2 of its 19 cases and the run
# looks complete. Both trees are walked recursively.
#
# .tsx is deliberately excluded: those cases are scanned under the JSX language
# variant, which changes what `<` and `{` mean, and neither our scanner nor this
# oracle selects it. Comparing them would measure a scan neither side intends.
cases=()
while IFS= read -r f; do cases+=("$f"); done < <(
  find "$PKG/tests/fixtures" -name '*.ts' 2>/dev/null | sort
  find "$SUB/testdata/tests/cases/compiler" "$SUB/testdata/tests/cases/conformance" \
    -name '*.ts' 2>/dev/null | sort
)

is_accepted() {
  [ -f "$ACCEPTED" ] || return 1
  grep -q "^$1	" "$ACCEPTED" 2>/dev/null
}

# Clear the whole per-case tree, not just the cases about to run. Renaming the
# case key once already left a previous run's directories behind, and a stale
# result directory is indistinguishable from a fresh one when something later
# reads them.
rm -rf "$OUT/cases"

matched=0; unported=0; failed=0; accepted=0; stale=0
failures=()
stales=()

for case_file in "${cases[@]}"; do
  # Path-derived, not basename: conformance/ nests, and two directories there
  # can hold the same file name. A basename key would let one case's accepted.txt
  # entry silently excuse a different case.
  name=${case_file#"$SUB/testdata/tests/cases/"}
  name=${name#"$PKG/tests/"}
  name=${name%.ts}
  name=${name//\//_}
  [ -n "$FILTER" ] && case "$name" in *"$FILTER"*) ;; *) continue ;; esac

  work="$OUT/cases/$name"
  rm -rf "$work"; mkdir -p "$work"

  # No pipeline around either binary: `rc=$?` after `$(prog | tr ...)` reads the
  # LAST command's status, which has silently disabled two suites in this repo.
  "$OUT/tscaly_tokens" "$case_file" > "$work/ours.txt" 2> "$work/ours.err"
  ours_rc=$?
  "$OUT/oracle_tokens" "$case_file" > "$work/ref.txt" 2> "$work/ref.err"
  ref_rc=$?

  if [ $ours_rc -ne 0 ]; then
    failures+=("$name: our dumper exited $ours_rc")
    failed=$((failed + 1)); continue
  fi
  if [ $ref_rc -ne 0 ]; then
    failures+=("$name: the ORACLE exited $ref_rc — suspect the harness, not the port")
    failed=$((failed + 1)); continue
  fi

  if grep -q '^UNPORTED ' "$work/ours.txt"; then
    unported=$((unported + 1)); continue
  fi

  # The oracle's fifth column is the kind NAME, carried for readability only.
  cut -d' ' -f1-4 < "$work/ref.txt" > "$work/ref4.txt"

  if diff -q "$work/ref4.txt" "$work/ours.txt" > /dev/null 2>&1; then
    if is_accepted "$name"; then
      # A deviation that no longer deviates. Left unreported, accepted.txt rots
      # into a list of things that used to be true.
      stales+=("$name")
      stale=$((stale + 1))
    fi
    matched=$((matched + 1))
    continue
  fi

  if is_accepted "$name"; then
    accepted=$((accepted + 1)); continue
  fi

  diff "$work/ref.txt" "$work/ours.txt" > "$work/diff.txt" 2>&1
  failures+=("$name: $(head -1 "$work/diff.txt" 2>/dev/null)")
  failed=$((failed + 1))
done

# ── report ───────────────────────────────────────────────────────────────────

total=$((matched + unported + failed + accepted))
echo
echo "scanner yardstick — $total cases"
echo "  matched            $matched"
echo "  unported           $unported   (this slice does not implement the construct)"
echo "  accepted deviation $accepted"
echo "  UNEXPLAINED        $failed"

if [ $stale -ne 0 ]; then
  echo
  red "$stale accepted.txt entries now MATCH — remove them:"
  printf '    %s\n' "${stales[@]}"
fi

if [ $failed -ne 0 ]; then
  echo
  red "unexplained failures:"
  printf '    %s\n' "${failures[@]}"
  echo
  echo "  full diffs under $OUT/cases/<name>/diff.txt"
  exit 1
fi

if [ $stale -ne 0 ]; then
  exit 1
fi

green "OK"
exit 0
