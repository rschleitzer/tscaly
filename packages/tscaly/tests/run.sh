#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# run.sh — the tscaly yardsticks.
#
# THREE yardsticks over one corpus, all built from the pinned submodule, so
# "green" means our port agrees with the TypeScript compiler's own output and
# not with an expectation someone typed:
#
#   scanner   the token stream — kind, start, end, flags, token for token
#   parser    the parse tree — a pre-order walk of kind, pos, end, flags,
#             through the reference's own child ORDER, plus the syntactic
#             diagnostics (code and span)
#   jsdoc     the JSDoc parse — for every node the parser walk has agreed on,
#             the JSDoc trees hanging off it, in the same shape (slice 21)
#
# ★★★ THE THIRD ONE IS NOT A SUBSET OF THE SECOND, and that is why it exists.
# JSDoc nodes are not in the tree the parser yardstick walks: the reference hangs
# them off the documented node through a side table, and for a TS/TSX file it
# does not parse them during ParseSourceFile at all — it sets HasLazyJSDoc and
# parses on the first access to Node.JSDoc(file). So a port producing no JSDoc
# and a port producing a WRONG one compare exactly equal on the parser
# yardstick, in both directions. See tests/oracle/jsdoc.go.
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
# ★ Since slice 19 those bodies ARE parsed — as JSON, by the second grammar, with
# the kind derived from each unit's own name on both sides. The split is what
# made that possible and the measurement above is what it was for.
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
# Usage:  packages/tscaly/tests/run.sh [filter]        TSCALY_STAGE=2 for the
#                                                     full submodule corpus
#
# ★★★ THE CORPUS HAS STAGES, AND THE REPORT SAYS WHICH ONE IT MEASURED. A count
# without its corpus is not a result — TESTPLAN.md's table names three stages and
# `TSCALY_STAGE` selects between the first two:
#
#   1 (default)  our fixtures + typescript-go's repo-local cases, under
#                testdata/tests/cases/{compiler,conformance}
#   2            + the TypeScript submodule's OWN corpus, the
#                {compiler,conformance} cases typescript-go's own runner reaches
#                through ../_submodules/TypeScript (compiler_runner.go:63), with
#                the reference's own file regex `\.tsx?$`
#
# Stage 1 is the working yardstick: 12 s, small enough to run per slice, and every
# number in CLAUDE.md's tables is one of its numbers. Stage 2 (7 min 23 s) is the
# one that can turn *it agrees over 834 units* into *the sample of 17 604 found
# these 21 things* — eleven `unported` markers stand in the code and stage 1
# reaches none of them, while stage 2 reaches exactly ONE, twice. ★It is a
# MEASUREMENT and not a gate, and it does not say *finished* either: the corpus is
# a SAMPLE and the reference is the SPECIFICATION (CLAUDE.md §3.5be).
#
# ★ A stage-2 case key is prefixed `submodule_`, mirroring the reference's own
# separation (testdata/baselines/reference/submodule/ against .../compiler/). It
# HAS to be: 15 relative paths occur in both corpora, so one shared key space
# would let one case's result overwrite another's — silently, and in the
# direction that shrinks a count. compare.py refuses a duplicate key outright
# rather than trusting today's corpus to have none.
#
# ★ What stage 2 does NOT mirror is the reference runner's `skippedTests` list
# (compiler_runner.go): those cases are skipped there because they depend on a
# built typescript.d.ts, which is a statement about the CHECKER's inputs. Both
# sides here parse the same bytes, so skipping them would only remove units from
# the yardstick.
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
TS=$SUB/_submodules/TypeScript
OUT=$PKG/tests/out
ACCEPTED=$PKG/tests/accepted.txt
FILTER=${1:-}
STAGE=${TSCALY_STAGE:-1}

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

case $STAGE in
  1|2) ;;
  *) red "TSCALY_STAGE=$STAGE: only stages 1 and 2 are built (3 is fourslash — see TESTPLAN.md)."
     exit 2 ;;
esac

# The stage-2 corpus is a submodule OF the submodule, and it is not initialized
# by the stage-1 setup. Missing it must say so: "0 failures over 0 cases" is the
# same output as success, which is the failure mode this runner exists to avoid.
if [ "$STAGE" -ge 2 ] && [ ! -d "$TS/tests/cases/compiler" ]; then
  red "stage-2 corpus not present: the TypeScript submodule is not initialized."
  echo "  git -C $SUB submodule update --init --depth 1 _submodules/TypeScript"
  echo
  echo "  A shallow clone of the pinned commit is enough (603 MB); nothing here"
  echo "  reads its history. Cleanliness is checked by the submodule_dirty test"
  echo "  below — typescript-go's own status reports a dirty nested submodule."
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
#
# ★★★ THE BUILD IS STAMPED, and the stamp is what makes a control battery
# affordable: ctl.sh patches `.scaly` files exclusively, so across all 45 controls
# the four Go binaries are bit-identical, and rebuilding them each time cost 6.2 s
# a run — a quarter of the battery's whole wall time by the end. The stamp covers
# everything a rebuild could depend on: the four oracle sources, the submodule's
# pinned commit, and the Go toolchain's own version string. Anything else moving
# is not something a rebuild would notice either.
#
# ★★★ WHAT THE STAMP SKIPS IS THE MATERIALISATION, NEVER THE CHECK. The submodule
# is asked whether it is clean on both sides regardless, because that question is
# about the CORPUS — the thing every comparison below is measured against — and
# not about the copy-in. A stamp that also silenced the check would trade 6 s for
# the possibility of measuring against a submodule someone had edited.
#
# `TSCALY_FORCE_ORACLE=1` rebuilds unconditionally.

submodule_dirty() {
  [ -n "$(git -C "$SUB" status --porcelain 2>/dev/null)" ]
}

oracle_stamp() {
  shasum -a 256 "$PKG/tests/oracle/tokens.go" "$PKG/tests/oracle/ast.go" \
                "$PKG/tests/oracle/jsdoc.go"  "$PKG/tests/oracle/split.go" \
    | awk '{print $1}'
  git -C "$SUB" rev-parse HEAD 2>/dev/null
  go version 2>/dev/null
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

STAMP=$OUT/oracle.stamp
WANT=$(oracle_stamp)
HAVE=
[ -f "$STAMP" ] && HAVE=$(cat "$STAMP")

oracles_present() {
  for o in oracle_tokens oracle_ast oracle_jsdoc oracle_split; do
    [ -x "$OUT/$o" ] || return 1
  done
}

if [ -z "${TSCALY_FORCE_ORACLE:-}" ] && [ "$WANT" = "$HAVE" ] && oracles_present; then
  : # the four binaries already answer to this stamp
else
  rm -f "$STAMP"
  mkdir -p "$SUB/oracle/tokens" "$SUB/oracle/ast" "$SUB/oracle/jsdoc" "$SUB/oracle/split"
  cp "$PKG/tests/oracle/tokens.go" "$SUB/oracle/tokens/main.go"
  cp "$PKG/tests/oracle/ast.go"    "$SUB/oracle/ast/main.go"
  cp "$PKG/tests/oracle/jsdoc.go"  "$SUB/oracle/jsdoc/main.go"
  cp "$PKG/tests/oracle/split.go"  "$SUB/oracle/split/main.go"
  ( cd "$SUB" && go build -o "$REPO/$OUT/oracle_tokens" ./oracle/tokens \
              && go build -o "$REPO/$OUT/oracle_ast"    ./oracle/ast \
              && go build -o "$REPO/$OUT/oracle_jsdoc"  ./oracle/jsdoc \
              && go build -o "$REPO/$OUT/oracle_split"  ./oracle/split ) \
    > "$OUT/oracle-build.log" 2>&1
  orc=$?
  rm -rf "$SUB/oracle"

  if [ $orc -ne 0 ]; then
    red "an oracle failed to build:"
    sed 's/^/    /' "$OUT/oracle-build.log"
    exit 2
  fi
  printf '%s\n' "$WANT" > "$STAMP"
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

for prog in tscaly_tokens tscaly_ast tscaly_jsdoc; do
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

# The binaries above have just been built from the tree as it stands, so whatever
# ctl.sh left behind is no longer true. See the "restored source is not a restored
# artifact" rule in ctl.sh's header for what the marker is for.
rm -f "$OUT/.built-from-patched-tree"

# ── the cases ────────────────────────────────────────────────────────────────
#
# Our own fixtures first — small, and each one aimed at a specific construct —
# then the repo-local corpus cases, read in place out of the submodule.

# ★ conformance/ is NESTED — a flat glob finds 2 of its 19 cases and the run
# looks complete. Both trees are walked recursively.
#
# ★★★ .tsx CASES JOINED IN SLICE 20, and until then their exclusion was the
# largest block this runner did not see: 20 case files, where the .tsx UNITS
# inside .ts cases numbered one. The line that stood here said comparing them
# "would measure a parse neither side intends", which was true while neither side
# selected the JSX variant and expired the moment both do — the same shape as the
# .json exclusion slice 19 closed. Both sides now derive the kind from the unit's
# NAME and clamp it, and .tsx clamps to itself.
cases=()
while IFS= read -r f; do cases+=("$f"); done < <(
  find "$PKG/tests/fixtures" -name '*.ts' -o -name '*.tsx' 2>/dev/null | sort
  find "$SUB/testdata/tests/cases/compiler" "$SUB/testdata/tests/cases/conformance" \
    \( -name '*.ts' -o -name '*.tsx' \) 2>/dev/null | sort
  if [ "$STAGE" -ge 2 ]; then
    find "$TS/tests/cases/compiler" "$TS/tests/cases/conformance" \
      \( -name '*.ts' -o -name '*.tsx' \) 2>/dev/null | sort
  fi
)

# accepted.txt is <case>\t<artifact>\t<reason> — the artifact column is what
# lets a case deviate on one yardstick and match on the other, which is the
# normal state while a slice is in flight. compare.py reads it.

# ── the case loop, as ONE process ────────────────────────────────────────────
#
# ★★★ THIS USED TO BE A BASH LOOP AND THE LOOP WAS THE COST. Measured on this
# tree: 88.3 s a run at 5-20 % CPU, of which 77.5 s was the loop — and almost
# none of it computing. Per artifact the loop spawned two greps, a cut, a
# `diff -q` and an accepted.txt grep; per unit two `printf | tr` subshells; per
# case an `rm`, a `mkdir` and a `grep -c`. Around 22 000 processes at ~3 ms of
# fork/exec apiece, to perform 2 502 file comparisons. compare.py does the whole
# loop in one process and runs the dumps on a thread pool.
#
# ★★★ IT CHANGES THE COST AND NOT THE MEASUREMENT, and that claim is checked
# rather than asserted: the `cut -d' ' -f1-<keep>` that drops the oracle's kind-NAME
# column is reimplemented on bytes and was diffed against BSD `cut` over all 2 502
# artifacts of a green run before the loop was retired. It is load-bearing and it
# is not a normalisation — see the root CLAUDE.md's `od -c` lesson, where a
# normalisation in the comparison hid exactly the class it hid in the comparison.
# The dump binaries are still one process per (unit, artifact), because a
# batch-mode dumper would share process state across units and that WOULD change
# what is measured.
#
# ★ `diff` is still a subprocess on the failure path: the `.diff` file is the
# diagnosis artifact and its first line is quoted into the failure message, so
# reproducing diff's own format in Python would normalise the evidence. A green
# run has no failing artifact and never spawns it.
#
# TSCALY_JOBS overrides the pool size; the default is the core count, measured
# rather than reasoned — see compare.py, where going wider is slower rather than
# neutral.
#
# ★ `${cases[@]+"${cases[@]}"}` and not `"${cases[@]}"`: macOS ships bash 3.2,
# where an EMPTY array under `set -u` is an "unbound variable" error rather than
# an empty expansion. The preconditions above make an empty list unreachable, so
# this is a guard against a cryptic failure and not a live path.

TSCALY_OUT=$OUT \
TSCALY_ACCEPTED=$ACCEPTED \
TSCALY_SUB_PREFIX="$SUB/testdata/tests/cases/" \
TSCALY_TS_PREFIX="$TS/tests/cases/" \
TSCALY_STAGE="$STAGE" \
TSCALY_PKG_PREFIX="$PKG/tests/" \
TSCALY_FILTER="$FILTER" \
python3 "$PKG/tests/compare.py" <<EOF_CASES
$(printf '%s\n' ${cases[@]+"${cases[@]}"})
EOF_CASES
if [ $? -ne 0 ]; then
  red "the comparator itself failed — this is a harness bug, not a result."
  exit 2
fi

# Nine counters per yardstick plus the coverage counts, written by compare.py as
# plain `name=value` lines. Sourced rather than parsed: a scalar assignment file
# is the one shape bash 3.2 reads without an associative array.
. "$OUT/counters.sh"

failures=()
while IFS= read -r l; do [ -n "$l" ] && failures+=("$l"); done < "$OUT/failures.txt"
stales=()
while IFS= read -r l; do [ -n "$l" ] && stales+=("$l"); done < "$OUT/stales.txt"

# ── report ───────────────────────────────────────────────────────────────────

echo
if [ "$STAGE" -ge 2 ]; then
  echo "corpus stage 2 — our fixtures + typescript-go's repo-local cases + the"
  echo "  TypeScript submodule's own {compiler,conformance} corpus, $cases_seen cases in all."
else
  echo "corpus stage 1 — our fixtures + typescript-go's repo-local cases, $cases_seen cases."
  echo "  TSCALY_STAGE=2 adds the submodule corpus; see TESTPLAN.md's stage table."
fi

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
report "jsdoc yardstick"   $matched_jsdoc  $unported_jsdoc  $accepted_jsdoc  $failed_jsdoc

echo
echo "  of those, $jsdoc_bearing units actually CARRY JSDoc — the rest match by both"
echo "  sides producing nothing, which is a real comparison and not coverage. A"
echo "  yardstick that is empty on most of the corpus has to print the number, or"
echo "  its matched count reads as evidence it does not have."

echo
echo "$json_compared .json units ARE compared, under ScriptKindJSON on both sides —"
echo "  the second grammar (parseJsonText), ported in slice 19. The kind is derived"
echo "  from the unit's NAME on both sides and decides three things at once: the"
echo "  entry point, the context flags (JavaScriptFile|JsonFile on every node) and"
echo "  the scanner's language variant (JSX — upstream's own answer for JSON)."

echo
echo "$tsx_compared .tsx units ARE compared, under ScriptKindTSX on both sides —"
echo "  the JSX grammar, ported in slice 20. The kind decides the same three things"
echo "  the JSON kind does, and one more: the four JSX TOKEN SCANNERS, which the"
echo "  PARSER drives. No token dump reaches them, so the scanner yardstick sees"
echo "  only the variant's one bit (\`</\` as one token) and the parser yardstick is"
echo "  the whole witness for this grammar."

skipped=$(( skip_jsx + skip_other ))
if [ $skipped -ne 0 ]; then
  echo
  echo "units not compared — $skipped, each for a reason of its own"
  if [ $skip_jsx -ne 0 ]; then
    echo "  .tsx/.jsx      $skip_jsx   should be 0 since slice 20 — classify_unit no longer skips these"
  fi
  echo "  other          $skip_other"
fi

echo
echo "$js_compared .js/.cjs/.mjs units ARE compared, under ScriptKindJS, and"
echo "  $jsx_compared .jsx units under ScriptKindJSX — the kind the reference's harness"
echo "  chooses, since slice 22. The kind turns on NodeFlagsJavaScriptFile, and with"
echo "  it the JSDoc REPARSER: in a JavaScript file JSDoc is not a comment but the"
echo "  type syntax, so \`@typedef\` becomes a declaration in the statement list and"
echo "  \`@param {T} x\` a type annotation on a parameter that has none. Both"
echo "  yardsticks witness it — the parser one sees the synthesized declarations,"
echo "  the jsdoc one reads the CACHE the eager parse filled rather than a lazy"
echo "  re-derivation, which is the only way a synthesized node's JSDoc is visible"
echo "  at all."
echo
echo "  NOT compared on these units: checkJSSyntax, whose diagnostics the reference"
echo "  routes to a separate list that sf.Diagnostics() does not include. Neither"
echo "  yardstick can see one, in either direction — stated because a distinction"
echo "  the dump hides hides every bug in it."
echo
echo "  Each count is printed rather than folded away: a yardstick that shrinks in"
echo "  silence is the failure mode this suite exists to prevent."

total_stale=$(( stale_tokens + stale_ast + stale_jsdoc ))
total_failed=$(( failed_tokens + failed_ast + failed_jsdoc ))
total_timeout=$(( timeout_tokens + timeout_ast + timeout_jsdoc ))

# A timed-out dump is counted in UNEXPLAINED like any other failure — it IS one —
# but it is also named separately, because "our dumper did not finish" and "our
# dumper answered differently" need different work and a mixed list hides the
# first inside the second. The bash loop had no timeout at all; over 12 444 cases
# a single non-terminating scan would have replaced the whole measurement with
# nothing.
if [ $total_timeout -ne 0 ]; then
  echo
  red "$total_timeout dumps did not finish within ${TSCALY_TIMEOUT:-60}s (counted in UNEXPLAINED above)."
  echo "  A non-terminating parse is a defect of its own class; grep 'timed out' in"
  echo "  $OUT/failures.txt for the list."
fi

if [ $total_stale -ne 0 ]; then
  echo
  red "$total_stale accepted.txt entries now MATCH — remove them:"
  printf '    %s\n' "${stales[@]}"
fi

if [ $total_failed -ne 0 ]; then
  echo
  # ★ The list is CAPPED, not summarised. Stage 2 can produce thousands of
  # failures and a wall of them is unreadable, but a count is not a diagnosis —
  # so the file holds every line and the cap says how many it is standing in for.
  # Neutral on stage 1, which has none. TSCALY_SHOW raises it.
  show=${TSCALY_SHOW:-40}
  if [ ${#failures[@]} -gt "$show" ]; then
    red "unexplained failures — ${#failures[@]}, the first $show:"
    printf '    %s\n' "${failures[@]:0:$show}"
    echo "    … $(( ${#failures[@]} - show )) more, all of them in $OUT/failures.txt"
  else
    red "unexplained failures:"
    printf '    %s\n' "${failures[@]}"
  fi
  echo
  echo "  full diffs under $OUT/cases/<name>/<artifact>.diff"
  exit 1
fi

if [ $total_stale -ne 0 ]; then
  exit 1
fi

green "OK"
exit 0
