#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice84.sh — the slice-84 battery: THE SIGNATURE, and a slice most of
# whose product no instrument in this suite can see.
#
# ★★★ THE SLICE CLOSES A ROW. `get-signature-from-declaration` was 244 events over
# 163 unit-rows and SIX kinds (FunctionDeclaration, MethodDeclaration, GetAccessor,
# SetAccessor, Constructor, TypePredicate) and is now ZERO on both aggregations. It
# is the first REACHABLE row of the work list: the four above it are the flow graph,
# the members dimension, the globals table and the assignability relation, and the
# first of those four needs THIS one (getSignaturesOfSymbol).
#
# ★★★ AND ITS ONE DIAGNOSTIC COMES FROM THE CALLER, NOT FROM EITHER PORTED
# FUNCTION. Neither getSignatureFromDeclaration nor getReturnTypeOfSignature can
# report anything this corpus can reach — the second's two reports need a CIRCULAR
# return annotation, and the only way to write one is `typeof f`, whose type node
# stops one call earlier. What the slice buys a report for is checkReturnStatement's
# tail: TS2408, *setters cannot return a value*, which reads no type at all.
#
# ★★★ THREE FINDINGS, AND EACH IS A ROW HERE.
#
#   1. THE RETURN TYPE'S STOP IS NOT AN EXIT (g03). getReturnTypeOfSignature stops
#      for every function with a BODY and no annotation — a setter is always one —
#      so the first draft's `if return_type = null return` took the setter arm with
#      it and TS2408 was a report this port can reach and does not make. **The
#      reference reads returnType at exactly two places below, and neither is the
#      reason the guard passes.** diagcheck cannot see that: a LOSS is invisible to
#      a subsequence, which is why the DIAGPIN is the instrument that catches it.
#   2. THE REPORT REACHED ITS REPORTER AND WAS DROPPED (g04) — slice 83's TS2390
#      finding arriving a second time at the same seam. error_range_for_node had no
#      ReturnStatement arm, so error_on_node recorded `error-range 254` where TS2408
#      belongs. The deferral note on error_range_needs_rescan had named this exact
#      reader — *the grammar checks report on … a return statement* — and it came due
#      exactly there. The list of deferred arms is now THREE.
#   3. MOST OF THE SLICE HAS NO READER, AND THE BATTERY IS WHERE THAT IS PRICED.
#      A Signature's parameters, its minimum argument count, its type parameters,
#      its `this` parameter and its four flag bits are WRITTEN by this slice and read
#      by nobody until the call-resolution and members chapters land. Nine rows below
#      are ungated for that one reason, each naming the reader that would move it.
#      **A slice whose product is a data structure is measured by what asks it, and
#      this one is asked for its DECLARATION and nothing else.**
#
# ★★★ ITERATE AT STAGE 1 AND CONFIRM AT STAGE 2 ONCE — slice 64's rule. The recorded
# verdicts are stage 1's.
#
# Usage (nothing may edit the tree while this runs, and no second harness may own
# tests/out — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # stage 1, ~35 s
#   packages/tscaly/tests/controls-slice84.sh 2>&1 | tee /tmp/battery84.log

set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.1/tscaly/checker.scaly
BINDER=$PKG/0.1.1/tscaly/binder.scaly
FIX=$PKG/tests/fixtures

. packages/tscaly/tests/toolchain.sh || exit 2

# ★ ONE MECHANISM PER FILE (slice 72's rule): the tagpin is first-wins, so a fixture
# naming two mechanisms is a fixture nobody can read a red row off.
#
# ★★ THE STOPPIN IS THE INSTRUMENT THAT CARRIES THIS SLICE. Almost every fixture
# here stops first at the CLASS's own `check-index-constraints`, so the tagpin is
# nearly inert; what the slice moves is what the walk reaches AFTER that stop, which
# only the whole log in order can show.
PINFILES="
$FIX/checker_setter_returns_value.ts
$FIX/checker_setter_returns_bare.ts
$FIX/checker_return_annotated.ts
$FIX/checker_return_annotated_async.ts
$FIX/checker_return_annotated_generator.ts
$FIX/checker_return_in_constructor.ts
$FIX/checker_signature_parameter_property.ts
$FIX/checker_signature_this_parameter.ts
$FIX/checker_signature_accessor_this.ts
$FIX/checker_signature_setter_borrows_getter.ts
$FIX/checker_signature_generic_constructor.ts
$FIX/checker_signature_type_predicate.ts
$FIX/checker_signature_iife.ts
$FIX/checker_signature_rest_and_optional.ts
$FIX/checker_signature_abstract_construct.ts
$FIX/checker_return_path_generator_body.ts
$FIX/checker_return_path_generator_overload.ts
$FIX/checker_return_path_overload_annotated.ts
$FIX/checker_ctor_overload.ts
$FIX/checker_accessor_setter_return_type.ts
"
red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl83)

PATCHED_FILES=""
cleanup() {
  local f i=0
  for f in $PATCHED_FILES; do
    [ -f "$WORK/orig.$i" ] && cp "$WORK/orig.$i" "$f"
    i=$((i+1))
  done
  [ -n "$PATCHED_FILES" ] && red "INTERRUPTED — $PATCHED_FILES restored from the row that was running."
  rm -rf "$WORK"
}
trap cleanup EXIT INT TERM

build_bins() {
  "$SCALYC" -c --no-prelude -o "$WORK/pkg.o" "$PKG/0.1.1/tscaly.scaly" > "$WORK/build.log" 2>&1 || return 1
  "$SCALYC" -c -o "$WORK/types.o" "$PKG/0.1.1/tscaly_types.scaly" >> "$WORK/build.log" 2>&1 || return 1
  clang -o "$WORK/tscaly_types" "$WORK/types.o" "$WORK/pkg.o" "$LIBSCALY" -lm >> "$WORK/build.log" 2>&1
}

# The DIAGPIN: the C section of each pin file, one line each. `--diags` rather than
# the dump, because every one of these units stops somewhere and the dump prints
# nothing for such a unit (TypeDump.emit's own note).
#
# ★★★ ONLY TWO OF THE TWENTY CARRY A C SECTION, AND THAT IS THE SLICE. Its whole
# diagnostic product is TS2408 on one fixture, so the DIAGPIN is what a LOSING row
# moves (g01, g03, g04, g07, g24 — every one of them invisible to diagcheck, which
# compares a SUBSEQUENCE) and diagcheck itself can only be moved by an INVENTION
# (g08). The other eighteen empty rows are what says an inventing row is confined.
diags_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$("$WORK/tscaly_types" --diags "$f" 2>/dev/null | tr '\n' '|')"
  done
}

# The TAGPIN: the first unported tag of each fixture, read off the DUMP the way the
# artifact tree records it.
tags_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$("$WORK/tscaly_types" "$f" 2>/dev/null | grep '^UNPORTED ' | head -1 | cut -d' ' -f3-)"
  done
}

# The STOPPIN: the WHOLE stop log of each pin file, in order — slice 82's fifth
# instrument, and the ONE that carries this battery.
#
# ★★★ WHY IT AND NOT THE OTHER FOUR. What this slice moves is where the walk gets
# to, not what it says: eleven of the twenty-eight rows below change a stop and
# nothing else. The tagpin reads only the FIRST stop, which for almost every fixture
# here is the CLASS's own `check-index-constraints` and never moves; the stopgate
# sees COUNTS, which a row that swaps one stop for another leaves alone; and
# diagcheck sees only an invention. **A battery is worth what its sharpest instrument
# can see, and for a slice whose product is a work list that instrument is the log.**
stops_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$("$WORK/tscaly_types" --stops "$f" 2>/dev/null | tr '\n' '|')"
  done
}

# The STOPGATE: stops.sh's internal agreement plus the counts it prints.
stopgate() {   # writes "matched units speaking events other" to stdout
  BIN=$WORK/tscaly_types packages/tscaly/tests/stops.sh > "$WORK/stops.out" 2>&1
  local m u s e o
  m=$(sed -n 's/^  agreeing with the work list  *\([0-9]*\)$/\1/p' "$WORK/stops.out")
  u=$(sed -n 's/^  units compared  *\([0-9]*\)$/\1/p' "$WORK/stops.out")
  s=$(sed -n 's/^  units with a stop  *\([0-9]*\)$/\1/p' "$WORK/stops.out")
  e=$(sed -n 's/^  stop events  *\([0-9]*\)$/\1/p' "$WORK/stops.out")
  o=$(sed -n 's/^  parse\/bind stop  *\([0-9]*\).*$/\1/p' "$WORK/stops.out")
  echo "$m $u $s $e $o"
}

DIAG_BASE=""; DIAG_LINES=""; DIAG_DIAGS=""; STOP_BASE=""

baseline() {
  echo "################################################################"
  bold "BASELINE — five instruments"
  if ! build_bins; then
    red "the unpatched tree did not build — every row below would be measuring that."
    sed 's/^/    /' "$WORK/build.log"
    exit 2
  fi
  BIN=$WORK/tscaly_types "$DIAGCHECK" > "$WORK/base.diag" 2>&1
  local rc=$?
  DIAG_BASE=$(sed -n 's/^  consistent  *\([0-9]*\)$/\1/p' "$WORK/base.diag")
  DIAG_LINES=$(sed -n 's/^  units we speak on  *\([0-9]*\).*$/\1/p' "$WORK/base.diag")
  DIAG_DIAGS=$(sed -n 's/^.*(\([0-9]*\) diagnostics.*$/\1/p' "$WORK/base.diag")
  if [ "$rc" != 0 ]; then
    red "the diagnostics instrument is already red on the unpatched tree — fix that first."
    exit 2
  fi
  tags_of > "$WORK/base.tags"
  diags_of > "$WORK/base.diags"
  stops_of > "$WORK/base.stops"
  STOP_BASE=$(stopgate)
  echo
  echo "  the DIAGPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.diags"
  echo
  echo "  the TAGPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.tags"
  echo
  echo "  BASELINE   diagcheck $DIAG_BASE consistent, $DIAG_LINES speaking, $DIAG_DIAGS diagnostics"
  echo "             stopgate  (matched units speaking events other) = $STOP_BASE"
}

control() {   # $1 = label, $2 = files, $3 = patch
  echo
  echo "################################################################"
  bold "CONTROL: $1"
  local files="$2" f i=0
  for f in $files; do cp "$f" "$WORK/orig.$i"; i=$((i+1)); done
  PATCHED_FILES="$files"
  if ! python3 "$3" $files; then
    red "the patch did not apply — the anchor moved. The row measures nothing."
    i=0; for f in $files; do cp "$WORK/orig.$i" "$f"; i=$((i+1)); done
    PATCHED_FILES=""; return 1
  fi
  echo "  patched $files"
  if ! build_bins; then
    red "the patched tree did not build — the row measures nothing:"
    tail -5 "$WORK/build.log" | sed 's/^/    /'
    i=0; for f in $files; do cp "$WORK/orig.$i" "$f"; i=$((i+1)); done
    PATCHED_FILES=""; return 1
  fi
  BIN=$WORK/tscaly_types "$DIAGCHECK" > "$WORK/ctl.diag" 2>&1
  local rc=$?
  local consistent differing speaking diags stop
  consistent=$(sed -n 's/^  consistent  *\([0-9]*\)$/\1/p' "$WORK/ctl.diag")
  differing=$(sed -n 's/^  differing  *\([0-9]*\)$/\1/p' "$WORK/ctl.diag")
  speaking=$(sed -n 's/^  units we speak on  *\([0-9]*\).*$/\1/p' "$WORK/ctl.diag")
  diags=$(sed -n 's/^.*(\([0-9]*\) diagnostics.*$/\1/p' "$WORK/ctl.diag")
  tags_of > "$WORK/ctl.tags"
  diags_of > "$WORK/ctl.diags"
  stops_of > "$WORK/ctl.stops"
  stop=$(stopgate)
  local restored=1
  i=0
  for f in $files; do
    cp "$WORK/orig.$i" "$f"
    cmp -s "$WORK/orig.$i" "$f" || restored=0
    i=$((i+1))
  done
  if [ "$restored" != 1 ]; then
    red "the source did NOT come back — every number below is suspect."
    return 1
  fi
  PATCHED_FILES=""
  echo "  RESTORE VERIFIED   $files byte-identical"
  echo
  local moved=0
  if [ "$rc" != 0 ]; then
    green "diagcheck RED $differing   (consistent $consistent, was $DIAG_BASE; speaking on $speaking/$diags, was $DIAG_LINES/$DIAG_DIAGS)"
    moved=1
  else
    echo "  diagcheck ungated — speaking on $speaking units with $diags diagnostics, was $DIAG_LINES/$DIAG_DIAGS."
  fi
  if cmp -s "$WORK/base.diags" "$WORK/ctl.diags"; then
    echo "  diagpin   unmoved — all twenty pin files answer the same C section."
  else
    green "diagpin   RED"
    diff "$WORK/base.diags" "$WORK/ctl.diags" | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.tags" "$WORK/ctl.tags"; then
    echo "  tagpin    unmoved — all twenty fixtures answer the same tag."
  else
    green "tagpin    RED"
    diff "$WORK/base.tags" "$WORK/ctl.tags" | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.stops" "$WORK/ctl.stops"; then
    echo "  stoppin   unmoved — all twenty fixtures log the same stops, in order."
  else
    green "stoppin   RED"
    diff "$WORK/base.stops" "$WORK/ctl.stops" | sed 's/^/    /'
    moved=1
  fi
  if [ "$stop" = "$STOP_BASE" ]; then
    echo "  stopgate  unmoved — $stop"
  else
    green "stopgate  MOVED   $STOP_BASE -> $stop   (matched units speaking events other)"
    moved=1
  fi
  if [ "$moved" = 0 ]; then
    if [ "$speaking" != "$DIAG_LINES" ] || [ "$diags" != "$DIAG_DIAGS" ]; then
      echo "  ungated on all five, WITH A NUMBER: $DIAG_LINES/$DIAG_DIAGS -> $speaking/$diags."
    else
      red "UNGATED ON ALL FIVE AND NOTHING MOVED AT ALL."
      echo "  Decide which of §3.5v's four kinds this is. A row that predicted"
      echo "  this is a measurement; a row that did not is a hole in the battery."
    fi
  fi
  return 0
}


PATCHDIR=$WORK/patches
mkdir -p "$PATCHDIR"

cat > "$PATCHDIR/g01.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# THE PREMISE ROW: the chapter reverted to the stop the slice retires.
# PREDICTION: STOPPIN RED on nearly every pin file, DIAGPIN RED at a LOSS (TS2408
# goes with it), diagcheck ungated with a NUMBER, stopgate MOVED by the whole
# chapter, and `get-signature-from-declaration` back on the work list at 163 units.
old = """        let fn container as ref[AstNode]
        let signature this.get_signature_from_declaration(fn)"""
new = """        let fn container as ref[AstNode]
        this.record_unported("get-signature-from-declaration", AstNode.kind_of(fn))
        let signature this.get_signature_from_declaration(fn)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g02.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# Every ask mints a fresh Signature.
# PREDICTION: STOPGATE MOVED with more EVENTS and the same unit count — a fresh
# Signature carries a fresh `resolved_return_type` cell, so getReturnTypeOfSignature
# would re-run and log its stop again for every second ask of one declaration.
# ★★★ WRONG, AND THE SILENCE IS THE MEASUREMENT: nothing in this port asks one
# declaration for its signature TWICE. The four callers are a `return` statement's
# container, a type predicate's parent, an accessor's partner and a generator, and no
# two of them meet on one node. This is declared_type_links' situation exactly (slice
# 66: *nothing in this slice can observe a hit*) — the memo is written for fidelity
# and its READER is the members dimension, where getSignaturesOfSymbol asks every
# declaration of an overload set and the assignability relation asks again.
old = """        let links this.signature_link_of(declaration)
        if links.resolved_signature <> null
            return links.resolved_signature
"""
new = """        let links this.signature_link_of(declaration)
        if false
            return links.resolved_signature
"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g03.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# THE FIRST FINDING, PUT BACK.
# PREDICTION: DIAGPIN RED at a LOSS on checker_setter_returns_value (TS2408 vanishes)
# and STOPPIN RED wherever the tail's own stops disappear, with diagcheck UNGATED —
# because a subsequence cannot see a line that is no longer emitted. That silence
# IS the row: the first draft of this slice was green on every instrument but one.
old = """        let return_type this.get_return_type_of_signature(signature as ref[Signature])
        let function_flags b.get_function_flags(fn)"""
new = """        let return_type this.get_return_type_of_signature(signature as ref[Signature])
        if return_type = null
            return
        let function_flags b.get_function_flags(fn)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g04.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# THE SECOND FINDING, PUT BACK: the kind goes back on the deferred-rescan list.
# PREDICTION: DIAGPIN RED at a LOSS (TS2408 disappears) and STOPPIN RED (`error-range
# 254` takes its place), diagcheck UNGATED. The report REACHES its reporter and is
# dropped, which is exactly what slice 83 measured for TS2390.
old = """        if k = KindReturnStatement
        {
            this.range_of_token_at_position(this.skip_trivia_at(AstNode.pos_of(n)), out_start, out_end)
            return true
        }
"""
new = """        if k = KindReturnStatement
        {
            this.record_unported("error-range-rescan", k)
            return false
        }
"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g05.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PREDICTION: UNGATED on all five. checkYieldExpression is the expression dimension
# and nothing here hands a YieldExpression to error_on_node — the arm is ported
# because it is ONE case label upstream, not because this port can reach it. Read it
# beside g04, which is the same two lines with a reader.
old = """        if k = KindYieldExpression
        {
            this.range_of_token_at_position(this.skip_trivia_at(AstNode.pos_of(n)), out_start, out_end)
            return true
        }
"""
new = """        if k = KindYieldExpression
        {
            this.record_unported("error-range-rescan", k)
            return false
        }
"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g06.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PREDICTION: UNGATED, and it is a PROOF rather than a gap —
# range_of_token_at_position resets the scanner and SCANS, so it skips the same
# trivia on its own. The call is kept because the reference has two lines here and
# transcribing them costs one pass over whitespace already scanned.
old = """        if k = KindReturnStatement
        {
            this.range_of_token_at_position(this.skip_trivia_at(AstNode.pos_of(n)), out_start, out_end)"""
new = """        if k = KindReturnStatement
        {
            this.range_of_token_at_position(AstNode.pos_of(n), out_start, out_end)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g07.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PREDICTION: DIAGPIN RED at a LOSS on checker_setter_returns_value and nothing else;
# diagcheck ungated with a number. The slice's only report.
old = """            if ck = KindSetAccessor
            {
                if expr_node <> null
                    this.error_on_node(node, DiagSetters_cannot_return_a_value)
                return
            }"""
new = """            if ck = KindSetAccessor
                return"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g08.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PREDICTION: diagcheck RED by INVENTION on checker_setter_returns_bare, whose
# `return;` is legal — the one direction a subsequence instrument can catch, and the
# reason that fixture exists at all.
old = """            if ck = KindSetAccessor
            {
                if expr_node <> null
                    this.error_on_node(node, DiagSetters_cannot_return_a_value)"""
new = """            if ck = KindSetAccessor
            {
                if true
                    this.error_on_node(node, DiagSetters_cannot_return_a_value)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g09.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PREDICTION: STOPPIN RED on checker_return_in_constructor, whose SECOND class has a
# bare `return;` — the stop appears for a constructor the reference says nothing
# about. It is g08 on the neighbouring arm, and the two together show the guard is
# per-arm and not shared.
old = """            if ck = KindConstructor
            {
                if expr_node <> null
                    this.record_unported("check-type-assignable-to-and-optionally-elaborate", ck)"""
new = """            if ck = KindConstructor
            {
                if true
                    this.record_unported("check-type-assignable-to-and-optionally-elaborate", ck)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g10.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PREDICTION: STOPPIN RED on checker_return_annotated — its UNANNOTATED sibling would
# get `check-return-expression` too.
# ★★★ WRONG, AND THE TWO SPELLINGS PROVABLY COINCIDE HERE. The defensive `if
# return_type = null return` three lines below does the same work: an unannotated
# function's return type is a STOP, so it is null, so the branch exits before the
# report. **A line written *tested rather than asserted* turned out to be the thing
# that makes the test above it redundant** — which is only visible from a row aimed
# at the wrong one of the two.
old = """            if annotated <> null
            {"""
new = """            if true
            {"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g11.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PREDICTION: STOPPIN RED on the two ANNOTATED fixtures — a generator's return type
# is unwrapped through getIterationTypeOfGeneratorFunctionReturnType and an async
# one through getAwaitedTypeNoAlias, so their own stops are what the caller would
# otherwise log, and dropping the call replaces both with `check-return-expression`.
# Two chapters, told apart by one call (slice 82).
# ★★★ IT CAME BACK SILENT ON THE FIRST RUN AND THE CAUSE WAS A MISSING FIXTURE, not a
# working guard (3.5v's first kind, slice 83's finding three times over). The two
# generator files in this list have no `return` STATEMENT at all — one is empty and
# one yields — so nothing reached checkReturnStatement's annotated branch.
# checker_return_annotated_async and _generator are that fixture, and their
# annotation is `any` rather than `Promise<number>` because a TypeReference stops one
# call earlier and the file would then measure the globals table.
old = """                this.unwrap_return_type(return_type as ref[Type], function_flags, fn)
                if this.unported_mark() <> mark
                    return
"""
new = """                if false
                    return
"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g12.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# Slice 82's assertion shape, re-run one arm along.
# PREDICTION: STOPPIN RED with `is-unwrapped-return-type-undefined-void-or-any`
# appearing. The branch is DOUBLY unreachable (the outer guard's first disjunct is a
# constant true as well), so this row prices only the inner option; g13 prices the
# outer one, and only the two together show the branch cannot run.
old = """    function no_implicit_returns() returns bool
        false"""
new = """    function no_implicit_returns() returns bool
        true"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g13.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PREDICTION: STOPPIN RED. With the first disjunct gone, a bare `return;` no longer
# enters the block at all, so the constructor fixture loses the arm behind it — which
# is what says the disjunct is load-bearing rather than decorative. Read beside g12:
# together they are the proof that the TS7030 branch cannot be entered.
old = """        var outer false
        if Checker.strict_null_checks()
            set outer: true
        if expr_node <> null
            set outer: true"""
new = """        var outer false
        if expr_node <> null
            set outer: true"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g14.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The PUSH removed and the POP left standing.
# PREDICTION: UNGATED on all five, on the argument that no input can make the pop
# answer false.
# ★★★ WRONG, AND FOR A REASON THAT HAS NOTHING TO DO WITH CYCLES: RED ON ALL FIVE,
# 146 units of diagcheck. A push and a pop are ONE object, and removing half of one
# underflows the stack for every later question — `type_resolution_count` goes
# negative and every memoised type answer after it is read out of a row nobody wrote.
# **A guard removed from one end of a stack is not a guard removed; it is a different
# defect.** g28 is the row this one was meant to be.
old = """        if this.push_type_resolution(null, null, sig, TypeSystemPropertyNameResolvedReturnType) = false
            return error_type"""
new = """        if false
            return error_type"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g15.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# An OVERLOAD signature no longer answers `any`.
# PREDICTION: STOPPIN RED on checker_ctor_overload and
# checker_return_path_overload_annotated — a declaration with no body is the ordinary
# shape of an overload set and of every `.d.ts`.
# ★★★ WRONG, AND WHAT REPLACES IT IS A PROOF ABOUT THE FOUR CALLERS. The arm is
# entered only when getReturnTypeFromAnnotation answers nil AND the body is missing,
# and no caller in this port can hand it that pair: checkReturnStatement needs a
# BODY to hold the `return`; the generator site is guarded on the body being present;
# check_type_predicate never asks for a return type; and the set-accessor arm hands a
# GETTER, which takes getReturnTypeFromAnnotation's own GetAccessor arm and stops
# there. **It is unreachable rather than uncovered, and the difference is a property
# of the callers rather than of the corpus** (3.5v's second row).
old = """            set t: any_type
        }
        ; The two call-chain arms."""
new = """            this.record_unported("get-return-type-of-signature-missing-body", AstNode.kind_of(decl))
            return null
        }
        ; The two call-chain arms."""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g16.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PREDICTION: TAGPIN + STOPPIN RED on checker_signature_type_predicate. The row is
# worth moving even though the chapter behind it is one function: everything
# checkTypePredicate reports reads `typePredicate.parameterIndex`, so a stop naming
# the signature named the wrong wall.
old = """        let signature this.get_signature_from_declaration(parent as ref[AstNode])
        if signature = null
            return
        this.record_unported("get-type-predicate-of-signature", KindTypePredicate)"""
new = """        this.record_unported("get-signature-from-declaration", KindTypePredicate)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g17.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# A setter's parameter no longer borrows the getter's RETURN type.
# PREDICTION: STOPPIN RED on checker_signature_setter_borrows_getter — the walk stops
# at `get-signature-from-declaration` where it now reaches `get-type-of-accessors`.
old = """                        let getter_signature this.get_signature_from_declaration(getter as ref[AstNode])
                        if getter_signature = null
                            return null"""
new = """                        this.record_unported("get-signature-from-declaration", KindGetAccessor)
                        let getter_signature this.get_signature_from_declaration(getter as ref[AstNode])
                        if getter_signature = null
                            return null"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g18.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PREDICTION: STOPPIN RED on checker_return_path_generator_body — the reference
# discards the answer there and the CALL is the statement, so what moves is the tag
# and not a value.
old = """                    let gsig this.get_signature_from_declaration(node)
                    if gsig <> null
                        this.get_return_type_of_signature(gsig as ref[Signature])"""
new = """                    this.record_unported("get-signature-from-declaration", AstNode.kind_of(node))"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g19.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PREDICTION: UNGATED on all five, and checker_signature_iife is what makes that a
# measurement. Nothing in this port walks into a function EXPRESSION's body, so no
# signature is ever asked for one and the term cannot be reached — the fixture holds
# an IIFE and the whole file stops at checkCallExpression, twice.
old = """            if iife <> null
            {
                if type_node = null
                {
                    if (parameters.get_length() as int) > AstNode.list_count(AstNode.call_arguments_of(iife as ref[AstNode]))
                        set is_optional_parameter: true
                }
            }"""
new = """            if false
                set is_optional_parameter: true"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g20.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PREDICTION: UNGATED on all five, WITH THE READER NAMED: `minArgumentCount` is read
# by getMinArgumentCount and by hasCorrectArity, both of which are the call-resolution
# chapter. A slot this slice writes and nothing asks about is invisible by
# construction, and saying so is what the row buys (3.5be).
old = """            if is_optional_parameter = false
                set min_argument_count: parameters.get_length() as int"""
new = """            if false
                set min_argument_count: parameters.get_length() as int"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g21.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# `constructor(private x: number)` keeps the binder's property symbol.
# PREDICTION: UNGATED, reader named — the list it writes is `parameters`, whose only
# readers are the call-resolution and assignability chapters.
# checker_signature_parameter_property is the file that HOLDS the shape, which is
# what separates *uncovered* from *unreachable* here (3.5v).
old = """                if (Symbol.flags_of(ps) & SymbolFlagsProperty) <> 0
                {
                    if AstNode.is_binding_pattern(AstNode.name_of(param)) = false
                    {"""
new = """                if false
                {
                    if AstNode.is_binding_pattern(AstNode.name_of(param)) = false
                    {"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g22.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# Every first parameter counts as `this`.
# PREDICTION: UNGATED, reader named. `thisParameter` is read by getThisTypeOfSignature
# and by the assignability relation's this-argument comparison; neither exists here.
# checker_signature_this_parameter carries the shape.
old = """                    if SymbolTable.names_equal(Symbol.name_data_of(ps2), Symbol.name_len_of(ps2), this_data, this_len)
                        set is_this_symbol: true"""
new = """                    if true
                        set is_this_symbol: true"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g23.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PREDICTION: UNGATED, reader named — same slot as g22, and
# checker_signature_accessor_this is the file that reaches the branch. The branch is
# entered by EVERY accessor (the guard is `!hasThisParameter || thisParameter ==
# nil`), so what is unobservable is the ANSWER and not the visit.
old = """                    let other Checker.declaration_of_kind(acc_sym as ref[Symbol], other_kind)
                    if other <> null
                        set this_parameter: Checker.get_annotated_accessor_this_parameter(other as ref[AstNode])"""
new = """                    let other Checker.declaration_of_kind(acc_sym as ref[Symbol], other_kind)
                    if false
                        set this_parameter: Checker.get_annotated_accessor_this_parameter(other as ref[AstNode])"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g24.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# Every accessor takes the late-bound stop.
# PREDICTION: STOPPIN RED — `has-late-bindable-name` appears on every accessor
# fixture. It is the one part of the accessor branch that IS observable, and only
# because a stop is observable where a slot is not.
old = """                if b.has_dynamic_name(declaration)
                {
                    this.record_unported("has-late-bindable-name", dk)
                    return null
                }"""
new = """                if true
                {
                    this.record_unported("has-late-bindable-name", dk)
                    return null
                }"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g25.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PREDICTION: UNGATED, reader named. `typeParameters` is read by
# getSignatureInstantiation and by the generic-call inference; a constructor has no
# type parameters of its own, so the substitute answers nil for
# checker_signature_generic_constructor where the class's `T` belongs.
# local_type_parameters_of exists ONLY for this line — slice 66 left it unwritten
# saying its readers were elsewhere, and this is the one it did not name.
old = """                        if class_type <> null
                            set type_parameters: this.local_type_parameters_of(class_type as ref[Type])"""
new = """                        if class_type <> null
                            set type_parameters: this.get_type_parameters_from_declaration(declaration)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g26.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PREDICTION: UNGATED, readers named. HasRestParameter is read by
# getRestTypeAtPosition and by hasEffectiveRestParameter, both call resolution.
# checker_signature_rest_and_optional holds the shape.
old = """        if Checker.has_rest_parameter(declaration)
            set flags: flags | SignatureFlagsHasRestParameter"""
new = """        if false
            set flags: flags | SignatureFlagsHasRestParameter"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g27.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PREDICTION: UNGATED with a NUMBER at most — the guard's three conjuncts are a JS
# file, one of four kinds and a filled FullSignature slot, and the same guard stands
# twice already in this file under the same tag. The `.js` half of the corpus is
# where it can move at all, and only for a function whose signature is asked for.
old = """            if full_kind
            {
                if AstNode.full_signature_of(declaration) <> null
                {
                    this.record_unported("get-signature-of-full-signature-type", fk)
                    return null
                }
            }"""
new = """            if full_kind
            {
                if false
                {
                    this.record_unported("get-signature-of-full-signature-type", fk)
                    return null
                }
            }"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g28.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# What g14 was meant to be. The push still happens — so the stack stays balanced and
# the frames are still MARKED — and only the cycle's early exit is gone.
# PREDICTION: UNGATED on all five, and a PROOF. A self-referential return annotation
# is the only input that can make the push answer false, and the only way to write
# one is `function f(): typeof f {}` — a TypeQuery, which getTypeFromTypeNode stops
# on one call earlier. Read it against g14, whose 146 red units measure the STACK and
# not the cycle: **the two rows differ by one `pop`, and only one of them is about
# the thing they were both aimed at.**
old = """        if this.push_type_resolution(null, null, sig, TypeSystemPropertyNameResolvedReturnType) = false
            return error_type"""
new = """        this.push_type_resolution(null, null, sig, TypeSystemPropertyNameResolvedReturnType)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

# ── the dry run ─────────────────────────────────────────────────────────────
#
# ★ Every patch is applied against a COPY of its own target before a single build is
# spent (slice 57), and the two targets are kept apart: three rows patch binder.scaly
# and the rest checker.scaly, so a dry run against one file would report the other's
# anchors as moved.
bold "DRY RUN — every patch against a copy of its own target"
DRY=$WORK/dry
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g01.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g01 applies"; else red "  g01 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g02.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g02 applies"; else red "  g02 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g03.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g03 applies"; else red "  g03 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$BINDER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g04.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g04 applies"; else red "  g04 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$BINDER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g05.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g05 applies"; else red "  g05 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$BINDER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g06.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g06 applies"; else red "  g06 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g07.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g07 applies"; else red "  g07 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g08.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g08 applies"; else red "  g08 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g09.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g09 applies"; else red "  g09 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g10.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g10 applies"; else red "  g10 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g11.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g11 applies"; else red "  g11 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g12.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g12 applies"; else red "  g12 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g13.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g13 applies"; else red "  g13 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g14.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g14 applies"; else red "  g14 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g15.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g15 applies"; else red "  g15 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g16.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g16 applies"; else red "  g16 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g17.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g17 applies"; else red "  g17 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g18.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g18 applies"; else red "  g18 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g19.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g19 applies"; else red "  g19 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g20.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g20 applies"; else red "  g20 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g21.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g21 applies"; else red "  g21 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g22.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g22 applies"; else red "  g22 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g23.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g23 applies"; else red "  g23 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g24.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g24 applies"; else red "  g24 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g25.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g25 applies"; else red "  g25 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g26.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g26 applies"; else red "  g26 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g27.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g27 applies"; else red "  g27 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g28.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g28 applies"; else red "  g28 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"

baseline

control "g01 the four call sites reverted to their stop (the premise)"                $CHECKER "$PATCHDIR/g01.py"
control "g02 the signature memo removed"                                              $CHECKER "$PATCHDIR/g02.py"
control "g03 the return type's stop read as an EXIT (the first finding)"              $CHECKER "$PATCHDIR/g03.py"
control "g04 error_range_for_node's ReturnStatement arm removed (the second finding)" $BINDER "$PATCHDIR/g04.py"
control "g05 the YieldExpression half of the same case label removed"                 $BINDER "$PATCHDIR/g05.py"
control "g06 the SkipTrivia in front of the range scan dropped"                       $BINDER "$PATCHDIR/g06.py"
control "g07 TS2408 removed"                                                          $CHECKER "$PATCHDIR/g07.py"
control "g08 TS2408's expression guard dropped"                                       $CHECKER "$PATCHDIR/g08.py"
control "g09 the constructor arm's expression guard dropped"                          $CHECKER "$PATCHDIR/g09.py"
control "g10 the annotated branch's annotation test dropped"                          $CHECKER "$PATCHDIR/g10.py"
control "g11 unwrapReturnType's call removed"                                         $CHECKER "$PATCHDIR/g11.py"
control "g12 noImplicitReturns forced true"                                           $CHECKER "$PATCHDIR/g12.py"
control "g13 strictNullChecks dropped from the outer guard"                           $CHECKER "$PATCHDIR/g13.py"
control "g14 the cycle guard removed"                                                 $CHECKER "$PATCHDIR/g14.py"
control "g15 the missing-body arm turned into a stop"                                 $CHECKER "$PATCHDIR/g15.py"
control "g16 check_type_predicate's stop reverted to the signature's"                 $CHECKER "$PATCHDIR/g16.py"
control "g17 the set-accessor parameter arm reverted to its stop"                     $CHECKER "$PATCHDIR/g17.py"
control "g18 the generator site reverted to its stop"                                 $CHECKER "$PATCHDIR/g18.py"
control "g19 the IIFE term removed from the minimum argument count"                   $CHECKER "$PATCHDIR/g19.py"
control "g20 the minimum argument count frozen at zero"                               $CHECKER "$PATCHDIR/g20.py"
control "g21 the parameter-property detour removed"                                   $CHECKER "$PATCHDIR/g21.py"
control "g22 the `this`-parameter test inverted"                                      $CHECKER "$PATCHDIR/g22.py"
control "g23 the accessor's borrowed `this` parameter removed"                        $CHECKER "$PATCHDIR/g23.py"
control "g24 hasBindableName's guard inverted in the accessor branch"                 $CHECKER "$PATCHDIR/g24.py"
control "g25 the constructor's local type parameters replaced"                        $CHECKER "$PATCHDIR/g25.py"
control "g26 the rest-parameter flag computation removed"                             $CHECKER "$PATCHDIR/g26.py"
control "g27 getTypeParametersFromDeclaration's full-signature guard removed"         $CHECKER "$PATCHDIR/g27.py"
control "g28 the cycle guard's EARLY RETURN removed, stack kept balanced"             $CHECKER "$PATCHDIR/g28.py"

echo
echo "################################################################"
bold "DONE — read every row against its PREDICTION, not against its colour."
