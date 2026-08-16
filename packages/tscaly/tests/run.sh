#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# run.sh — the tscaly yardsticks.
#
# TWO yardsticks over one corpus, both built from the pinned submodule, so
# "green" means our port agrees with the TypeScript compiler's own output and
# not with an expectation someone typed:
#
#   scanner   the token stream — kind, start, end, flags, token for token
#   parser    the parse tree — a pre-order walk of kind, pos, end, flags,
#             through the reference's own child ORDER, plus the syntactic
#             diagnostics (code and span)
#
# They share one runner rather than one each, because the expensive and
# error-prone part is not the comparison — it is the submodule discipline
# around the oracle build (materialize in, build, remove, verify clean on both
# sides). One copy of that is one place to get it right.
#
# Three outcomes per case per yardstick, and the third is the point:
#
#   MATCH      identical output
#   UNPORTED   our side met a construct this slice does not implement and said
#              so; no claim is made about the case
#   FAIL       the outputs differ, and no accepted.txt entry explains it
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

# ── build the oracles ────────────────────────────────────────────────────────
#
# The oracle sources are ours and live in this repository, but they can only be
# BUILT from inside the submodule's module: every upstream package is under
# internal/, and Go admits those imports only from within the module rooted
# above internal/. So they are copied in, built, and removed again — inward
# only, and the submodule is checked clean on both sides of that.
#
# Each oracle goes into its OWN directory under oracle/: two `package main`
# files in one directory is not a Go package.

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

mkdir -p "$SUB/oracle/tokens" "$SUB/oracle/ast"
cp "$PKG/tests/oracle/tokens.go" "$SUB/oracle/tokens/main.go"
cp "$PKG/tests/oracle/ast.go"    "$SUB/oracle/ast/main.go"
( cd "$SUB" && go build -o "$REPO/$OUT/oracle_tokens" ./oracle/tokens \
            && go build -o "$REPO/$OUT/oracle_ast"    ./oracle/ast ) \
  > "$OUT/oracle-build.log" 2>&1
orc=$?
rm -rf "$SUB/oracle"

if [ $orc -ne 0 ]; then
  red "an oracle failed to build:"
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
# Two objects per program, the way the opensp drop-in is built: the package
# object carries the bodies, the program object the entry point.

"$SCALYC" -c --no-prelude -o "$OUT/tscaly.o" "$PKG/0.1.0/tscaly.scaly" \
  > "$OUT/pkg-build.log" 2>&1
if [ $? -ne 0 ]; then
  red "the tscaly package failed to compile:"; sed 's/^/    /' "$OUT/pkg-build.log"; exit 2
fi

for prog in tscaly_tokens tscaly_ast; do
  "$SCALYC" -c -o "$OUT/$prog.o" "$PKG/0.1.0/$prog.scaly" > "$OUT/$prog-build.log" 2>&1
  if [ $? -ne 0 ]; then
    red "$prog failed to compile:"; sed 's/^/    /' "$OUT/$prog-build.log"; exit 2
  fi
  clang -o "$OUT/$prog" "$OUT/$prog.o" "$OUT/tscaly.o" "$LIBSCALY" -lm \
    > "$OUT/$prog-link.log" 2>&1
  if [ $? -ne 0 ]; then
    red "the $prog link failed:"; sed 's/^/    /' "$OUT/$prog-link.log"; exit 2
  fi
done

# ── the cases ────────────────────────────────────────────────────────────────
#
# Our own fixtures first — small, and each one aimed at a specific construct —
# then the repo-local corpus cases, read in place out of the submodule.

# ★ conformance/ is NESTED — a flat glob finds 2 of its 19 cases and the run
# looks complete. Both trees are walked recursively.
#
# .tsx is deliberately excluded: those cases are scanned under the JSX language
# variant, which changes what `<` and `{` mean, and neither our port nor these
# oracles select it. Comparing them would measure a parse neither side intends.
cases=()
while IFS= read -r f; do cases+=("$f"); done < <(
  find "$PKG/tests/fixtures" -name '*.ts' 2>/dev/null | sort
  find "$SUB/testdata/tests/cases/compiler" "$SUB/testdata/tests/cases/conformance" \
    -name '*.ts' 2>/dev/null | sort
)

# accepted.txt is <case>\t<artifact>\t<reason> — the artifact column is what
# lets a case deviate on one yardstick and match on the other, which is the
# normal state while a slice is in flight.
is_accepted() {
  [ -f "$ACCEPTED" ] || return 1
  grep -q "^$1	$2	" "$ACCEPTED" 2>/dev/null
}

# Clear the whole per-case tree, not just the cases about to run. Renaming the
# case key once already left a previous run's directories behind, and a stale
# result directory is indistinguishable from a fresh one when something later
# reads them.
rm -rf "$OUT/cases"

# ★ Plain counters per artifact, not an associative array: macOS ships bash
# 3.2, which has none — and a `declare -A` there fails at the line that USES
# it, so the run would report zeros rather than refusing.
matched_tokens=0; unported_tokens=0; failed_tokens=0; accepted_tokens=0; stale_tokens=0
matched_ast=0;    unported_ast=0;    failed_ast=0;    accepted_ast=0;    stale_ast=0
failures=()
stales=()

# Compare one artifact of one case and leave the verdict in VERDICT, so the
# caller can bump its own counters. $1 case name, $2 artifact (tokens|ast),
# $3 the number of oracle fields to keep, $4 our binary, $5 the oracle,
# $6 the case file, $7 the work directory.
VERDICT=
compare_one() {
  local name=$1 art=$2 keep=$3 ours_bin=$4 ref_bin=$5 case_file=$6 work=$7

  # No pipeline around either binary: `rc=$?` after `$(prog | tr ...)` reads the
  # LAST command's status, which has silently disabled two suites in this repo.
  "$ours_bin" "$case_file" > "$work/$art.ours" 2> "$work/$art.ours.err"
  local ours_rc=$?
  "$ref_bin" "$case_file" > "$work/$art.ref" 2> "$work/$art.ref.err"
  local ref_rc=$?

  if [ $ours_rc -ne 0 ]; then
    failures+=("$art/$name: our dumper exited $ours_rc")
    VERDICT=FAIL; return
  fi
  if [ $ref_rc -ne 0 ]; then
    failures+=("$art/$name: the ORACLE exited $ref_rc — suspect the harness, not the port")
    VERDICT=FAIL; return
  fi

  if grep -q '^UNPORTED ' "$work/$art.ours"; then
    VERDICT=UNPORTED; return
  fi

  # The oracle's last column is the kind NAME, carried for readability only.
  # A diagnostic line (`D pos end code`) has four fields either way and is
  # unaffected by a cut that keeps more.
  cut -d' ' -f1-$keep < "$work/$art.ref" > "$work/$art.ref.cut"

  if diff -q "$work/$art.ref.cut" "$work/$art.ours" > /dev/null 2>&1; then
    if is_accepted "$name" "$art"; then
      # A deviation that no longer deviates. Left unreported, accepted.txt rots
      # into a list of things that used to be true.
      stales+=("$art/$name")
      VERDICT=STALE; return
    fi
    VERDICT=MATCH; return
  fi

  if is_accepted "$name" "$art"; then
    VERDICT=ACCEPTED; return
  fi

  diff "$work/$art.ref" "$work/$art.ours" > "$work/$art.diff" 2>&1
  failures+=("$art/$name: $(head -1 "$work/$art.diff" 2>/dev/null)")
  VERDICT=FAIL
}

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

  compare_one "$name" tokens 4 "$OUT/tscaly_tokens" "$OUT/oracle_tokens" "$case_file" "$work"
  case $VERDICT in
    MATCH)    matched_tokens=$((matched_tokens + 1)) ;;
    STALE)    matched_tokens=$((matched_tokens + 1)); stale_tokens=$((stale_tokens + 1)) ;;
    UNPORTED) unported_tokens=$((unported_tokens + 1)) ;;
    ACCEPTED) accepted_tokens=$((accepted_tokens + 1)) ;;
    FAIL)     failed_tokens=$((failed_tokens + 1)) ;;
  esac

  compare_one "$name" ast 5 "$OUT/tscaly_ast" "$OUT/oracle_ast" "$case_file" "$work"
  case $VERDICT in
    MATCH)    matched_ast=$((matched_ast + 1)) ;;
    STALE)    matched_ast=$((matched_ast + 1)); stale_ast=$((stale_ast + 1)) ;;
    UNPORTED) unported_ast=$((unported_ast + 1)) ;;
    ACCEPTED) accepted_ast=$((accepted_ast + 1)) ;;
    FAIL)     failed_ast=$((failed_ast + 1)) ;;
  esac
done

# ── report ───────────────────────────────────────────────────────────────────

report() {
  local title=$1 m=$2 u=$3 a=$4 f=$5
  local total=$(( m + u + a + f ))
  echo
  echo "$title — $total cases"
  echo "  matched            $m"
  echo "  unported           $u   (this slice does not implement the construct)"
  echo "  accepted deviation $a"
  echo "  UNEXPLAINED        $f"
}

report "scanner yardstick" $matched_tokens $unported_tokens $accepted_tokens $failed_tokens
report "parser yardstick"  $matched_ast    $unported_ast    $accepted_ast    $failed_ast

total_stale=$(( stale_tokens + stale_ast ))
total_failed=$(( failed_tokens + failed_ast ))

if [ $total_stale -ne 0 ]; then
  echo
  red "$total_stale accepted.txt entries now MATCH — remove them:"
  printf '    %s\n' "${stales[@]}"
fi

if [ $total_failed -ne 0 ]; then
  echo
  red "unexplained failures:"
  printf '    %s\n' "${failures[@]}"
  echo
  echo "  full diffs under $OUT/cases/<name>/<artifact>.diff"
  exit 1
fi

if [ $total_stale -ne 0 ]; then
  exit 1
fi

green "OK"
exit 0
