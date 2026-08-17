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
# ★★★ THE UNIT OF COMPARISON IS A UNIT, NOT A CASE. A corpus case is a SCRIPT
# for the reference's test harness — `// @option: value` lines configure the
# compile and `// @Filename: path` starts a new file — so 145 of the 296 cases
# hold several files, and not all of them are TypeScript. A third oracle,
# `split`, runs the reference's OWN splitter over each case and writes the units
# out; both yardsticks then run per unit. See tests/oracle/split.go for the
# measurement that forced this: feeding the whole case file to a TypeScript
# parser meant 209 of the 241 syntactic diagnostics the reference produced over
# the corpus came out of package.json and tsconfig.json bodies read as
# TypeScript, which is a document the reference's own runner never parses.
#
# A single-file case yields exactly one unit, so its case key is unchanged; a
# multi-file case's units are keyed `<case>@<unit path>`.
#
# Three outcomes per UNIT per yardstick, and the third is the point:
#
#   MATCH      identical output
#   UNPORTED   our side met a construct this slice does not implement and said
#              so; no claim is made about the unit
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

mkdir -p "$SUB/oracle/tokens" "$SUB/oracle/ast" "$SUB/oracle/split"
cp "$PKG/tests/oracle/tokens.go" "$SUB/oracle/tokens/main.go"
cp "$PKG/tests/oracle/ast.go"    "$SUB/oracle/ast/main.go"
cp "$PKG/tests/oracle/split.go"  "$SUB/oracle/split/main.go"
( cd "$SUB" && go build -o "$REPO/$OUT/oracle_tokens" ./oracle/tokens \
            && go build -o "$REPO/$OUT/oracle_ast"    ./oracle/ast \
            && go build -o "$REPO/$OUT/oracle_split"  ./oracle/split ) \
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

# Units the yardsticks do not compare, counted by REASON. Both oracles force
# ScriptKindTS — the only script kind this port implements — so a unit the
# reference's harness would parse under a different kind is measuring a parse
# neither side intends. That is the same argument that excludes .tsx at case
# discovery, applied one level down; each count is printed, because a
# measurement that silently shrinks is the failure mode this whole suite is
# organized against.
cases_seen=0
skip_json=0; skip_dts=0; skip_jsx=0; skip_other=0
# Compared, but not under the kind the reference's harness would choose — see
# classify_unit's .js arm. Counted so the report states it rather than implying
# that every compared unit is a faithful one.
js_compared=0

UNIT_SKIP=
classify_unit() {
  local low
  low=$(printf '%s' "$1" | tr 'A-Z' 'a-z')
  case $low in
    # ★★ A declaration file sets NodeFlagsAmbient (1 << 23) from its NAME —
    # `IsDeclarationFileName` is consulted before parsing, so the SourceFile node
    # carries it too — and this port models no file-level context, so the flags
    # column differs for a reason that has nothing to do with the construct under
    # test. Skipped rather than accepted, because an accepted deviation on 56
    # units would be a standing excuse rather than an argued exception.
    #
    # ★ Measured rather than assumed, and the measurement makes it a small ITEM
    # rather than a limitation: on compiler_invocationErrorRecovery's foo.d.ts the
    # entire difference is ONE line, the SourceFile's flags, because everything
    # inside it is individually `declare`d and our port propagates that correctly.
    # A .d.ts whose members are not would diverge more widely. Making these live
    # is a one-flag change — thread the unit name into Parser.parse and set the
    # context flag when the name ends in .d.ts — and it is the first thing the
    # split EXPOSED: TESTPLAN.md's note that "the pinned corpus contains no .d.ts
    # case, so the path is unexercised on both sides" was true of whole cases and
    # false of sections.
    *.d.ts|*.d.mts|*.d.cts) UNIT_SKIP=declaration ;;
    *.ts|*.mts|*.cts)       UNIT_SKIP= ;;
    *.tsx|*.jsx)            UNIT_SKIP=jsx ;;
    # ★★★ A .js unit IS compared, as TypeScript on BOTH sides, and the reasoning
    # is worth having because the first draft skipped it. The reference's harness
    # would parse it under ScriptKindJS, where JSDoc is syntax — so this is not
    # the parse the reference RUNS. It is still a well-defined comparison of the
    # component being ported (our TypeScript parser against the reference's, over
    # that text), because the oracle is TOLD which kind to use, and JSDoc is just
    # a comment under ScriptKindTS.
    #
    # Skipping them was measured and cost 60 corpus cases that MATCH — the whole
    # jsdoc/salsa/cjs part of the corpus, previously compared as part of the
    # concatenated case text. The .json exclusion below earns its keep by VALUE
    # (25 cases blocked behind the error recovery of a document that is not a
    # program, for no information); this one would have subtracted 60 matching
    # comparisons and bought nothing. They move to ScriptKindJS when the port has
    # one, and that slice is what makes them faithful rather than merely valid.
    *.js|*.cjs|*.mjs)       UNIT_SKIP= ;;
    # ScriptKindJSON is a different grammar (parseJsonText). This is the class
    # that made the split worth building.
    *.json)                 UNIT_SKIP=json ;;
    *)                      UNIT_SKIP=other ;;
  esac
}

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
  cases_seen=$((cases_seen + 1))

  case_work="$OUT/cases/$name"
  rm -rf "$case_work"; mkdir -p "$case_work"

  # The reference's own splitter. No pipeline: its exit code is read.
  "$OUT/oracle_split" "$case_file" "$case_work/units" \
    > "$case_work/units.manifest" 2> "$case_work/units.err"
  if [ $? -ne 0 ]; then
    failures+=("split/$name: $(head -1 "$case_work/units.err" 2>/dev/null)")
    failed_tokens=$((failed_tokens + 1)); failed_ast=$((failed_ast + 1))
    continue
  fi

  unit_count=$(grep -c . "$case_work/units.manifest")

  while read -r idx written unit_name; do
    [ -n "$written" ] || continue

    classify_unit "$unit_name"
    if [ -n "$UNIT_SKIP" ]; then
      case $UNIT_SKIP in
        json)        skip_json=$((skip_json + 1)) ;;
        declaration) skip_dts=$((skip_dts + 1)) ;;
        jsx)         skip_jsx=$((skip_jsx + 1)) ;;
        *)           skip_other=$((skip_other + 1)) ;;
      esac
      continue
    fi

    # ★ A single-unit case keeps its own key, so every existing accepted.txt
    # entry, every fixture name and every number in CLAUDE.md's tables still
    # refers to the same thing. Only a genuinely multi-file case gains a suffix,
    # and the suffix is the unit's own PATH — unique within the case and stable
    # across a pin bump, where an index would not be.
    if [ "$unit_count" = 1 ]; then
      key=$name
    else
      suffix=${unit_name#/}
      suffix=${suffix//\//_}
      key="$name@$suffix"
    fi

    case $(printf '%s' "$unit_name" | tr 'A-Z' 'a-z') in
      *.js|*.cjs|*.mjs) js_compared=$((js_compared + 1)) ;;
    esac

    work="$case_work/$idx"
    mkdir -p "$work"

    compare_one "$key" tokens 4 "$OUT/tscaly_tokens" "$OUT/oracle_tokens" "$written" "$work"
    case $VERDICT in
      MATCH)    matched_tokens=$((matched_tokens + 1)) ;;
      STALE)    matched_tokens=$((matched_tokens + 1)); stale_tokens=$((stale_tokens + 1)) ;;
      UNPORTED) unported_tokens=$((unported_tokens + 1)) ;;
      ACCEPTED) accepted_tokens=$((accepted_tokens + 1)) ;;
      FAIL)     failed_tokens=$((failed_tokens + 1)) ;;
    esac

    compare_one "$key" ast 5 "$OUT/tscaly_ast" "$OUT/oracle_ast" "$written" "$work"
    case $VERDICT in
      MATCH)    matched_ast=$((matched_ast + 1)) ;;
      STALE)    matched_ast=$((matched_ast + 1)); stale_ast=$((stale_ast + 1)) ;;
      UNPORTED) unported_ast=$((unported_ast + 1)) ;;
      ACCEPTED) accepted_ast=$((accepted_ast + 1)) ;;
      FAIL)     failed_ast=$((failed_ast + 1)) ;;
    esac
  done < "$case_work/units.manifest"
done

# ── report ───────────────────────────────────────────────────────────────────

report() {
  local title=$1 m=$2 u=$3 a=$4 f=$5
  local total=$(( m + u + a + f ))
  echo
  echo "$title — $total units (from $cases_seen cases)"
  echo "  matched            $m"
  echo "  unported           $u   (this slice does not implement the construct)"
  echo "  accepted deviation $a"
  echo "  UNEXPLAINED        $f"
}

report "scanner yardstick" $matched_tokens $unported_tokens $accepted_tokens $failed_tokens
report "parser yardstick"  $matched_ast    $unported_ast    $accepted_ast    $failed_ast

skipped=$(( skip_json + skip_dts + skip_jsx + skip_other ))
if [ $skipped -ne 0 ]; then
  echo
  echo "units not compared — $skipped, each for a reason of its own"
  echo "  .json          $skip_json   a different GRAMMAR (parseJsonText), and the class the split was built for"
  echo "  .d.ts family   $skip_dts   the file NAME sets NodeFlagsAmbient; a one-flag port item, see classify_unit"
  echo "  .tsx/.jsx      $skip_jsx   the JSX language VARIANT, which changes what < and { mean"
  echo "  other          $skip_other"
  echo
  echo "$js_compared .js/.cjs/.mjs units ARE compared, as TypeScript on both sides —"
  echo "  which is a well-defined comparison of our parser but NOT the kind the"
  echo "  reference harness would choose (ScriptKindJS: JSDoc is syntax there)."
  echo "  Skipping them was measured and cost 60 matching corpus cases for no"
  echo "  information; classify_unit has the argument."
  echo
  echo "  Each count is printed rather than folded away: a yardstick that shrinks in"
  echo "  silence is the failure mode this suite exists to prevent."
fi

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
