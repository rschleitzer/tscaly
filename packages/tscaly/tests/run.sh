#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# run.sh — the tscaly yardsticks.
#
# FIVE yardsticks over one corpus, all built from the pinned submodule, so
# "green" means our port agrees with the TypeScript compiler's own output and
# not with an expectation someone typed:
#
#   scanner   the token stream — kind, start, end, flags, token for token
#   parser    the parse tree — a pre-order walk of kind, pos, end, flags,
#             through the reference's own child ORDER, plus the syntactic
#             diagnostics (code and span), plus — since slice 24 — the
#             JS-SYNTAX diagnostics, which the reference keeps in a list of
#             its own that sf.Diagnostics() does not include
#   jsdoc     the JSDoc parse — for every node the parser walk has agreed on,
#             the JSDoc trees hanging off it, in the same shape (slice 21)
#   binder    the BIND — the symbol a declaration owns, the locals/members/
#             exports tables with their entries, the merge structure (one
#             symbol, several declarations), the file's symbol counter and
#             classifiable names, and the BIND diagnostics, which live in a
#             third list of their own (slice 26)
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
# these 21 things*, which is what it did on its first pass.
#
# ★★★ SINCE SLICE 25 THE `unported` COLUMN IS ZERO IN BOTH STAGES FOR THE FIRST
# THREE YARDSTICKS, so every unit is a comparison there — and the way the last one
# was found is the argument for printing that column at all. Stage 2 reported it
# twice out of 17 634, both reports CORRECT, over a byte of scan_number that stage 1
# could not reach; an honest "not compared" is the cheapest place in this suite for a
# defect to hide, because nobody investigates a unit that declares itself uncompared.
# Five markers remain in parser.scaly and each stands where the reference PANICS.
# ★★ THE BINDER COLUMN IS THE OPPOSITE and is meant to be: slice 27 reads
# 93 / 772 / 0 on stage 1 and 1 208 / 16 396 / 0 on stage 2, and that column IS the
# work list — `triage.py` groups it by tag so it names the arm that unlocks the most
# units next. A number in it is not a failure and not a pass.
# ★It is a MEASUREMENT and not a gate, and it does not say *finished* either: the
# corpus is a SAMPLE and the reference is the SPECIFICATION (CLAUDE.md §3.5be).
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
SLOW=$PKG/tests/slow.txt
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
  shasum -a 256 "$PKG/tests/oracle/tokens.go"  "$PKG/tests/oracle/ast.go" \
                "$PKG/tests/oracle/jsdoc.go"   "$PKG/tests/oracle/split.go" \
                "$PKG/tests/oracle/symbols.go" "$PKG/tests/oracle/flow.go" \
                "$PKG/tests/oracle/types.go"   "$PKG/tests/oracle/batch.go" \
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
  for o in oracle_tokens oracle_ast oracle_jsdoc oracle_split oracle_symbols oracle_flow oracle_types oracle_batch; do
    [ -x "$OUT/$o" ] || return 1
  done
}

if [ -z "${TSCALY_FORCE_ORACLE:-}" ] && [ "$WANT" = "$HAVE" ] && oracles_present; then
  : # the seven binaries already answer to this stamp
else
  rm -f "$STAMP"
  mkdir -p "$SUB/oracle/tokens" "$SUB/oracle/ast" "$SUB/oracle/jsdoc" \
           "$SUB/oracle/split" "$SUB/oracle/symbols" "$SUB/oracle/flow" \
           "$SUB/oracle/types" "$SUB/oracle/batch"
  cp "$PKG/tests/oracle/tokens.go"  "$SUB/oracle/tokens/main.go"
  cp "$PKG/tests/oracle/ast.go"     "$SUB/oracle/ast/main.go"
  cp "$PKG/tests/oracle/jsdoc.go"   "$SUB/oracle/jsdoc/main.go"
  cp "$PKG/tests/oracle/split.go"   "$SUB/oracle/split/main.go"
  cp "$PKG/tests/oracle/symbols.go" "$SUB/oracle/symbols/main.go"
  cp "$PKG/tests/oracle/flow.go"    "$SUB/oracle/flow/main.go"
  cp "$PKG/tests/oracle/types.go"   "$SUB/oracle/types/main.go"
  cp "$PKG/tests/oracle/batch.go"   "$SUB/oracle/batch/main.go"
  ( cd "$SUB" && go build -o "$REPO/$OUT/oracle_tokens"  ./oracle/tokens \
              && go build -o "$REPO/$OUT/oracle_ast"     ./oracle/ast \
              && go build -o "$REPO/$OUT/oracle_jsdoc"   ./oracle/jsdoc \
              && go build -o "$REPO/$OUT/oracle_split"   ./oracle/split \
              && go build -o "$REPO/$OUT/oracle_symbols" ./oracle/symbols \
              && go build -o "$REPO/$OUT/oracle_flow"    ./oracle/flow \
              && go build -o "$REPO/$OUT/oracle_types"   ./oracle/types \
              && go build -o "$REPO/$OUT/oracle_batch"   ./oracle/batch ) \
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

# ── the DUPLICATE-DEFINE gate (slice 86) ─────────────────────────────────────
#
# ★★★ TWO MODULES OF ONE PACKAGE MAY DECLARE THE SAME TOP-LEVEL CONCEPT AND
# NOTHING IS REPORTED — not by the planner, not by the linker, not by any of the
# eight instruments in this directory. A top-level `define` mangles WITHOUT its
# module (`_Z17TypeParameterData`), so the emitter keeps ONE named struct for the
# pair and every field access in the other module reads the WRONG LAYOUT.
#
# ★★★ IT COST FOUR SLICES OF A SILENTLY DEAD PREDICATE. `checker.scaly`'s
# TypeParameterData (four slots, one of them a bool) collided with `ast.scaly`'s
# (five reference slots); under the AST layout `mark_this_type`'s `store i1` went
# into the low byte of a pointer and `is_this_type_of`'s `return tp.is_this_type`
# was DROPPED — the arm computed the value, branched to the tail and returned the
# literal `false`. `isThisTypeParameter` therefore answered false for every type in
# the tree from slice 66 to slice 86. **A collision whose two records happen to
# have the same LLVM shape is invisible too** — TypeReferenceData was the second
# pair and it was harmless purely by luck.
#
# ★ The check is a text scan and it is honest about that: it reads top-level
# `define` lines, which is exactly what mangles without a namespace. Nested
# concepts and generics are out of its reach and out of the hazard.
DUPES=$(grep -h '^define [A-Za-z_]' "$PKG"/0.1.0/tscaly/*.scaly \
        | awk '{print $2}' | sed 's/\[.*//' | grep -v ':' | sort | uniq -d)
if [ -n "$DUPES" ]; then
  red "two top-level concepts in packages/tscaly share a name, and the emitter keeps ONE:"
  echo "$DUPES" | sed 's/^/    /'
  echo "  Rename one of each pair. Nothing else in this tree can see this."
  exit 2
fi

# ★★★ A DEBUG PROBE ON STDERR IS INVISIBLE TO EVERY OTHER INSTRUMENT HERE, so
# this is the only place that can see one. Slice 164 committed three
# `scaly_eputs("PROBE gi …")` into checker.scaly and they survived five gates,
# diagcheck, walkcheck and two stage-2 runs: every yardstick reads the port's
# STDOUT and compares it, and nothing reads stderr at all. Slice 166 found them
# by eye while running one unit by hand.
#
# ★ A grep, because there is nothing subtler to be: this package writes its
# artifacts through the dump programs and has no legitimate use for the
# runtime's stderr printers. If one ever appears, it belongs behind an
# environment switch and this line gets the exception with a reason.
PROBES=$(grep -ln 'scaly_eput' "$PKG"/0.1.0/*.scaly "$PKG"/0.1.0/tscaly/*.scaly 2>/dev/null)
if [ -n "$PROBES" ]; then
  red "a debug probe writes to stderr in the ported sources — no yardstick reads it:"
  echo "$PROBES" | sed 's/^/    /'
  echo "  Remove it, or put it behind an environment switch and exempt the file here."
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

for prog in tscaly_tokens tscaly_ast tscaly_jsdoc tscaly_symbols tscaly_flow tscaly_types tscaly_dump; do
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
#
# ★★★ .mts FIXTURES JOINED IN SLICE 100, for the same one-line-widening reason and
# with a sharper one of its own: checkGrammarArrowFunction's FIRST report fires
# only in a `.mts` or `.cts` file, so the extension IS the input. With the glob at
# `*.ts` a fixture carrying it was invisible to every yardstick here, and the only
# witness left would have been a submodule case — which §3.5cw's rule says is a
# gate that can move under a pin bump. Both sides derive the script kind from the
# unit's NAME already, and `.mts` clamps to TS on both.
#
# ★★★ .js FIXTURES JOINED IN SLICE 50, and the reason is that the JSDOC REPARSER
# had no local fixture at all: it runs only for a JavaScript file, and this
# collector took `*.ts` and `*.tsx` only — so every one of its constructs was
# witnessed exclusively by submodule corpus cases. Slice 50 found a reparser
# defect (finish_reparsed_node did not re-parent its children) through one such
# case, `compiler_jsDocTypedefTagNamespace[1]`, and a defect whose only gate is a
# corpus case is a defect whose gate can move under a pin bump. Both sides already
# derive the script kind from the unit's NAME, which is what makes this a one-line
# widening rather than a mode.
cases=()
while IFS= read -r f; do cases+=("$f"); done < <(
  find "$PKG/tests/fixtures" \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.mts' \) 2>/dev/null | sort
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

# ★ There is no reference-dump cache any more (2026-09-02): oracle_batch answers the
# whole stage-1 reference in seconds, in-process, so there is nothing to cache and
# no 38 000-file tree under $REPO/.tscaly-refcache to scan. Its history is in
# CLAUDE-history.md under *The runner's history*.

# ── the OUTGOING store's verdicts, written out before it is destroyed ────────
#
# ★★★ THE STORE IS RE-CREATED, NOT APPENDED TO, so this run unlinks the previous
# `run.db` — and with it the only per-unit record of what the PARENT tree
# answered. Slice 190 lost a stage-2 baseline exactly here: the FAIL set had been
# clustered from a stage-2 run, the first stage-1 gate run of the slice overwrote
# it, and the transition set §3.5go calls for could not be taken by name at the
# end without a second nine-minute run. The rule that lesson states — *dump the
# parent's verdicts BEFORE the first gate run of a slice* — is something the
# runner can simply do, so it does.
#
# ★ Two files, because they answer two different questions and one would destroy
# the other: `verdicts-prev.txt` is always the run before this one (a stage-1
# iteration included), and `verdicts-stage2.txt` is only ever written from a FULL
# stage-2 store, so it survives any number of stage-1 gate runs and still names
# the tree the slice was planned against. Neither is read by anything here —
# `harness.py transitions <file>` is what reads them.
#
# ★ Over ROWS and not into a dict: five unit keys occur twice in the corpus. The
# reason is in harness.py beside write_verdicts.
if [ -f "$OUT/run.db" ]; then
  TSCALY_OUT=$OUT python3 "$PKG/tests/harness.py" verdicts "$OUT/verdicts-prev.txt" > /dev/null 2>&1
  PREV_FULL_STAGE2=$(python3 - "$OUT/run.db" <<'EOF_PREV'
import sqlite3, sys
try:
    m = dict(sqlite3.connect(sys.argv[1]).execute("select key, value from meta").fetchall())
    print("yes" if m.get("stage") == "2" and not m.get("filter") else "no")
except Exception:
    print("no")
EOF_PREV
)
  if [ "$PREV_FULL_STAGE2" = "yes" ] && [ -s "$OUT/verdicts-prev.txt" ]; then
    cp "$OUT/verdicts-prev.txt" "$OUT/verdicts-stage2.txt"
  fi
fi

TSCALY_OUT=$OUT \
TSCALY_ACCEPTED=$ACCEPTED \
  TSCALY_SLOW=$SLOW \
TSCALY_SUB_PREFIX="$SUB/testdata/tests/cases/" \
TSCALY_TS_PREFIX="$TS/tests/cases/" \
TSCALY_STAGE="$STAGE" \
TSCALY_PKG_PREFIX="$PKG/tests/" \
TSCALY_FILTER="$FILTER" \
TSCALY_ORACLE_STAMP="$WANT" \
python3 "$PKG/tests/compare.py" <<EOF_CASES
$(printf '%s\n' ${cases[@]+"${cases[@]}"})
EOF_CASES
if [ $? -ne 0 ]; then
  red "the comparator itself failed — this is a harness bug, not a result."
  exit 2
fi

# Ten counters per yardstick plus the coverage counts, written by compare.py as
# plain `name=value` lines. Sourced rather than parsed: a scalar assignment file
# is the one shape bash 3.2 reads without an associative array.
. "$OUT/counters.sh"

failures=()
while IFS= read -r l; do [ -n "$l" ] && failures+=("$l"); done < "$OUT/failures.txt"
stales=()
while IFS= read -r l; do [ -n "$l" ] && stales+=("$l"); done < "$OUT/stales.txt"
refcrashes=()
while IFS= read -r l; do [ -n "$l" ] && refcrashes+=("$l"); done < "$OUT/refcrashes.txt"
slows=()
while IFS= read -r l; do [ -n "$l" ] && slows+=("$l"); done < "$OUT/slows.txt"
staleslows=()
while IFS= read -r l; do [ -n "$l" ] && staleslows+=("$l"); done < "$OUT/staleslows.txt"

# ── report ───────────────────────────────────────────────────────────────────

echo
if [ "$STAGE" -ge 2 ]; then
  echo "corpus stage 2 — our fixtures + typescript-go's repo-local cases + the"
  echo "  TypeScript submodule's own {compiler,conformance} corpus, $cases_seen cases in all."
else
  echo "corpus stage 1 — our fixtures + typescript-go's repo-local cases, $cases_seen cases."
  echo "  TSCALY_STAGE=2 adds the submodule corpus; see TESTPLAN.md's stage table."
fi

# ★★★ THE FIFTH NUMBER IS THE UNIT TOTAL'S FIFTH TERM, and leaving it out would
# be the shrinking-total defect this suite keeps finding: a unit the REFERENCE
# cannot answer (oracle exit 3, see compare.py) belongs to none of the four
# columns, so a total of four terms silently loses it. The line only appears when
# the count is non-zero, and the units are named further down.
# ★ THE SEVENTH ARGUMENT IS `slow` AND IT GOES INTO THE TOTAL. The header above
# says why that matters: slice 26's control c4 found a column that could not fail
# the run because the sums named three yardsticks and there were four. A `slow`
# unit is not matched, not unported and not failed — it is its own outcome — so
# leaving it out of the total would make the total disagree with the corpus, which
# is the same defect one column over.
report() {
  local title=$1 m=$2 u=$3 a=$4 f=$5 r=${6:-0} sl=${7:-0}
  local total=$(( m + u + a + f + r + sl ))
  echo
  echo "$title — $total units (from $cases_seen cases)"
  echo "  matched            $m"
  echo "  unported           $u   (this slice does not implement the construct)"
  echo "  accepted deviation $a"
  echo "  UNEXPLAINED        $f"
  if [ "$r" -ne 0 ]; then
    echo "  no reference answer $r   (the ORACLE could not answer the unit)"
  fi
  if [ "$sl" -ne 0 ]; then
    echo "  slow               $sl   (terminates, but not in this gate's budget — slow.txt)"
  fi
}

report "scanner yardstick" $matched_tokens $unported_tokens $accepted_tokens $failed_tokens $refcrash_tokens $slow_tokens
report "parser yardstick"  $matched_ast    $unported_ast    $accepted_ast    $failed_ast    $refcrash_ast $slow_ast
report "jsdoc yardstick"   $matched_jsdoc  $unported_jsdoc  $accepted_jsdoc  $failed_jsdoc  $refcrash_jsdoc $slow_jsdoc
report "binder yardstick"  $matched_symbols $unported_symbols $accepted_symbols $failed_symbols $refcrash_symbols $slow_symbols
report "flow yardstick"    $matched_flow   $unported_flow   $accepted_flow   $failed_flow   $refcrash_flow $slow_flow
report "checker yardstick" $matched_types  $unported_types  $accepted_types  $failed_types  $refcrash_types $slow_types
report "emit yardstick"    $matched_emit   $unported_emit   $accepted_emit   $failed_emit   $refcrash_emit $slow_emit

echo
echo "  of those, $symbol_bearing units actually CARRY a symbol, and $bind_diag_units carry a BIND"
echo "  diagnostic ($bind_diag_lines of them). Printed for the reason the JSDoc-bearing count"
echo "  is, and slice 26's control c1 is why it is not decoration: a dump of \`f 0 0\`"
echo "  — no symbols, no tables, symbolCount 0 — MATCHED 44 of the 865 units the"
echo "  corpus held when that control ran,"
echo "  because that is exactly what the reference produces for a unit that declares"
echo "  nothing. A matched total on this yardstick therefore includes units where"
echo "  both sides agree by producing nothing."

echo
echo "  The FOURTH yardstick (slice 26) compares the BINDER: the symbol a"
echo "  declaration owns, the locals/members/exports tables, the symbol NAMES and"
echo "  the merge structure (one symbol, several declarations), the file's own"
echo "  symbol counter and classifiable names, and the BIND diagnostics — which"
echo "  the reference keeps in a third list that neither Diagnostics() nor"
echo "  JSDiagnostics() includes. None of it is in the tree the parser yardstick"
echo "  walks, so without this artifact a port producing no symbols and a port"
echo "  producing wrong ones compare exactly equal. See tests/oracle/symbols.go."

echo
echo "  The FIFTH yardstick (slice 92) compares the CONTROL FLOW GRAPH the bind"
echo "  built: the flow node reaching every statement, the four per-node slots"
echo "  (flow, end-of-body, return, fallthrough), every flow node's flags, its"
echo "  associated AST node and its antecedent list, and the three REACHABILITY"
echo "  bits the binder writes on a node. ★★★It is the only EQUALITY in this"
echo "  directory: diagcheck compares a subsequence and cannot see a line we fail"
echo "  to emit, where a missing EDGE and an invented one are both red here."
echo "  ★★★And the sentence it refutes had stood for sixty slices — the graph was"
echo "  said to be unreachable through any exported accessor, which is a claim"
echo "  about an INSTRUMENT and was simply false. See tests/oracle/flow.go."

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
echo "  $js_diag_lines JS-SYNTAX diagnostics over $js_diag_units of those units are compared, in the"
echo "  ast dump's THIRD section — checkJSSyntax, ported in slice 24. The reference"
echo "  routes them to a separate list that sf.Diagnostics() does NOT include, so"
echo "  until that section existed neither yardstick could see one in either"
echo "  direction: a port producing none of them and a port producing wrong ones"
echo "  compared exactly equal. The count is counted off the REFERENCE dump, so it"
echo "  says what the corpus contains and not what this port answered, and it is"
echo "  printed for the reason the JSDoc-bearing count is — the section is empty on"
echo "  every unit that is not JavaScript, so a matched total including it would"
echo "  read as coverage it does not have."
echo
echo "  Each count is printed rather than folded away: a yardstick that shrinks in"
echo "  silence is the failure mode this suite exists to prevent."

# ★★★ EVERY YARDSTICK'S COUNTERS BELONG IN THESE THREE SUMS, and leaving one
# out is exactly the defect slice 26's control c4 found: with the binder oracle
# patched to exit 3, the report printed **865 UNEXPLAINED** in its own column and
# the run still said OK and listed no failures, because these sums named three
# yardsticks and there were four. A column that cannot fail the run is a column
# that is not measured — the same sentence this suite keeps writing about the
# `unported` column, one level up. ★Slice 92 added the FIFTH and these are the
# three lines it had to touch; the control that proves it is s01.
total_stale=$(( stale_tokens + stale_ast + stale_jsdoc + stale_symbols + stale_flow + stale_types + stale_emit ))
total_failed=$(( failed_tokens + failed_ast + failed_jsdoc + failed_symbols + failed_flow + failed_types + failed_emit ))
total_timeout=$(( timeout_tokens + timeout_ast + timeout_jsdoc + timeout_symbols + timeout_flow + timeout_types + timeout_emit ))

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

total_slow=$(( slow_tokens + slow_ast + slow_jsdoc + slow_symbols + slow_flow + slow_types + slow_emit ))

# ★ NAMED ON EVERY RUN, like the reference-crash list and for its reason: a unit
# that is excused has to be readable, or the excuse is a suppression. Each line
# carries the MEASURED seconds the entry claims, so a reader can re-measure it.
if [ $total_slow -ne 0 ]; then
  echo
  echo "$total_slow dumps are listed in slow.txt — they TERMINATE, but not inside"
  echo "  ${TSCALY_TIMEOUT:-60}s. Not a pass and not a failure: the cause is named per entry, and"
  echo "  the run fails as soon as one of them is no longer needed."
  printf '    %s\n' "${slows[@]}"
fi

# ★★★ AND THE HALF THAT KEEPS THE LIST HONEST. An entry the run did not need is a
# claim that has stopped being true — the same rot accepted.txt's own header
# describes, one outcome over.
if [ "${staleslow:-0}" -ne 0 ]; then
  echo
  red "$staleslow slow.txt entries finished inside the budget — remove them:"
  printf '    %s\n' "${staleslows[@]}"
fi

total_refcrash=$(( refcrash_tokens + refcrash_ast + refcrash_jsdoc + refcrash_symbols + refcrash_flow + refcrash_types + refcrash_emit ))

# ★ NAMED, ALWAYS, AND NEVER SUMMARISED AWAY. A unit the reference cannot answer
# is a hole in the measurement, so the list IS the point: it has to be possible to
# read which constructs are unmeasured, and a growing count with no names would be
# the same silence this suite keeps finding in an unported column nobody reads.
if [ $total_refcrash -ne 0 ]; then
  echo
  echo "$total_refcrash units have NO reference answer — the oracle panicked inside the"
  echo "  reference and exited 3. Not a port defect and not a pass: an UNMEASURED"
  echo "  unit. tests/oracle/types.go's header bounds the shape."
  printf '    %s\n' "${refcrashes[@]}"
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
  echo "  every artifact is in $OUT/run.db: python3 $PKG/tests/harness.py show <key> <artifact> diff|ours|ref|cut"
  exit 1
fi

if [ $total_stale -ne 0 ]; then
  exit 1
fi

if [ "${staleslow:-0}" -ne 0 ]; then
  exit 1
fi

green "OK"
exit 0
