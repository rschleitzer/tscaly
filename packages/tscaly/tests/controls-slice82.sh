#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice82.sh — the slice-82 battery: THE NON-VOID RETURN PATH, and a row
# that was measured CFG-blocked and is blocked for half its population.
#
# ★★★ THE SLICE HAS TWO PRODUCTS AND EACH IS VISIBLE TO A DIFFERENT INSTRUMENT, so
# this battery reads on all four. The ROW — `get-return-type-from-annotation`, the
# largest by units the work list has had since slice 63 — is retired by the `t == nil`
# collapse and is visible to the STOPGATE and the TAGPIN only. The REPORT — TS7010 on
# an overload signature or an ambient declaration, and TS7039 on a mapped type with
# no value type — is bought by the two blocks BEHIND the chapter, and is visible to
# diagcheck and the DIAGPIN. **Reading the two as one thing is the mistake g02 and
# g14 exist to prevent: the blocks report whether or not the chapter stopped.**
#
# ★★★ AND THE BATTERY FOUND THE SLICE'S SECOND HALF BY COMING BACK SILENT. g15 drops
# isPrivateWithinAmbient — the one guard in front of TS7010 — and predicted an
# INVENTION; on the first run it moved nothing, because checkClassDeclaration's
# `c.checkSourceElements(node.Members())` was not in this file at all and no class
# member had ever reached checkFunctionOrMethodDeclaration. **A fixture that cannot
# be reached is indistinguishable from a guard that works.** The walk is g25's row
# and the line landed in the same slice; g15 is an invention test only because it did.
#
# ★★★ THREE ROWS CAN INVENT — g15, g17 and g24 — and every other losing row is a
# LOSS, which a subsequence cannot see. That is why the DIAGPIN carries as many red
# rows as diagcheck does.
#
# ★★ TWO OF THE PIN FILES CANNOT CARRY A TAG AND ARE PINNED ANYWAY. A MethodSignature
# lives in an interface or a type literal and both containers stop before the member
# walk (`check-index-constraints`), and an async or generator function with a return
# annotation is resolved one call earlier by checkSignatureDeclaration; record_unported
# is FIRST-WINS, so those fixtures contribute the STOPGATE's event count and never a
# tag. Stated here rather than left to be re-derived from a row that does not move.
#
# ★★ READING THE STOPGATE ON A ROW THAT CHANGES A TAG: its counts are contaminated,
# because stops.sh compares against the UNPORTED line the artifact tree recorded with
# the BASELINE binary — a disagreeing unit drops out of the histogram, so `matched`
# and `speaking` both fall. Read `matched` FIRST.
#
# ★★★ ITERATE AT STAGE 1 AND CONFIRM AT STAGE 2 ONCE — slice 64's rule. The recorded
# verdicts are stage 1's.
#
# Usage (nothing may edit the tree while this runs, and no second harness may own
# tests/out — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # stage 1, ~25 s
#   packages/tscaly/tests/controls-slice82.sh 2>&1 | tee /tmp/battery82.log

set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.0/tscaly/checker.scaly
FIX=$PKG/tests/fixtures

LIBSCALY=${LIBSCALY:-/tmp/libscaly.a}
SCALYC=${SCALYC:-$REPO/scalyc/build/scalyc}

# ★ ONE MECHANISM PER FILE (slice 72's rule): the tagpin is first-wins, so a fixture
# naming two mechanisms is a fixture nobody can read a red row off.
#
# The first four are the chapter WALKING OUT — void, any, a MethodSignature and an
# annotated overload, one per term of the reference's two guards. The fifth is the
# only shape that still needs the flow graph. The next four are the reports: two
# TS7010 shapes, the guard that must NOT report, and the mapped type's TS7039. The
# last three are the generator and async arms, whose witness is the stop LOG rather
# than the tag.
PINFILES="
$FIX/checker_return_path_void.ts
$FIX/checker_return_path_any.ts
$FIX/checker_return_path_method_signature.ts
$FIX/checker_return_path_overload_annotated.ts
$FIX/checker_return_path_annotated.ts
$FIX/checker_return_path_overload_implicit_any.ts
$FIX/checker_return_path_ambient_implicit_any.ts
$FIX/checker_return_path_private_ambient.ts
$FIX/checker_return_path_class_overload.ts
$FIX/checker_mapped_type_implicit_any.ts
$FIX/checker_return_path_generator_overload.ts
$FIX/checker_function_declaration_collision.ts
$FIX/checker_return_path_generator_body.ts
$FIX/checker_return_path_async_annotated.ts
$FIX/checker_return_path_generator_annotated.ts
$FIX/checker_return_path_async_generator_annotated.ts
"
red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl82)

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
  "$SCALYC" -c --no-prelude -o "$WORK/pkg.o" "$PKG/0.1.0/tscaly.scaly" > "$WORK/build.log" 2>&1 || return 1
  "$SCALYC" -c -o "$WORK/types.o" "$PKG/0.1.0/tscaly_types.scaly" >> "$WORK/build.log" 2>&1 || return 1
  clang -o "$WORK/tscaly_types" "$WORK/types.o" "$WORK/pkg.o" "$LIBSCALY" -lm >> "$WORK/build.log" 2>&1
}

# The DIAGPIN: the C section of each pin file, one line each. `--diags` rather than
# the dump, because every one of these units stops somewhere and the dump prints
# nothing for such a unit (TypeDump.emit's own note).
#
# ★★★ FIVE OF THE TWELVE CARRY A C SECTION AND SEVEN ARE EMPTY, AND BOTH HALVES ARE
# THE INSTRUMENT. The five are what a LOSING row moves (g01, g14, g16, g18 — every one
# of them invisible to diagcheck, which compares a SUBSEQUENCE); the seven are what an
# INVENTING row moves (g15, g17, g24).
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

# The STOPPIN: the WHOLE stop log of each pin file, in order — the fifth instrument,
# added by this battery because g12 needed it.
#
# ★★★ WHY THE OTHER FOUR CANNOT SEE AN ORDER. The stopgate compares stops.sh's
# COUNTS, and swapping which of two stops a unit logs leaves every count identical;
# the tagpin reads only the FIRST stop, which for an async generator with a return
# annotation is checkSignatureDeclaration's, one call earlier. So unwrapReturnType's
# two arms — and the order the reference resolves their overlap in — were
# indistinguishable on all four instruments, which is §3.5v's third row. **A row that
# comes back silent because no instrument can see it is not a measurement; it is a
# missing instrument**, and this is the cheapest one that fits.
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
    echo "  diagpin   unmoved — all sixteen pin files answer the same C section."
  else
    green "diagpin   RED"
    diff "$WORK/base.diags" "$WORK/ctl.diags" | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.tags" "$WORK/ctl.tags"; then
    echo "  tagpin    unmoved — all sixteen fixtures answer the same tag."
  else
    green "tagpin    RED"
    diff "$WORK/base.tags" "$WORK/ctl.tags" | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.stops" "$WORK/ctl.stops"; then
    echo "  stoppin   unmoved — all sixteen fixtures log the same stops, in order."
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

# ── the patches ─────────────────────────────────────────────────────────────
#
# Written first, ALL of them, so the dry run below can apply every one against a
# copy of the tree before a single build is spent (slice 57).

cat > "$PATCHDIR/g01.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE PREMISE ROW: the chapter reverted to the stop slice 63 left there, both
# blocks with it. PREDICTION: stopgate MOVED by the whole chapter, tagpin RED on the
# fixtures the slice releases, DIAGPIN RED on the four reporting ones — and diagcheck
# UNGATED, because everything lost here is a LOSS and a subsequence cannot see one.
old = """        let ret_mark this.unported_mark()
        let return_type this.get_return_type_from_annotation(node)
        if this.unported_mark() = ret_mark
            this.check_all_code_paths_in_non_void_function_return_or_throw(node, return_type)"""
new = """        this.record_unported("get-return-type-from-annotation", AstNode.kind_of(node))
        if false
            this.check_all_code_paths_in_non_void_function_return_or_throw(node, null)"""
assert s.count(old) == 1
s = s.replace(old, new, 1)
old2 = """        if AstNode.full_signature_of(node) <> null
        {"""
new2 = """        if false
        {"""
assert s.count(old2) == 1
s = s.replace(old2, new2, 1)
old3 = """        if AstNode.type_of(node) = null
        {
            let body AstNode.body_of(node)
            if Binder.node_is_missing(body)"""
new3 = """        if false
        {
            let body AstNode.body_of(node)
            if Binder.node_is_missing(body)"""
assert s.count(old3) == 1
open(p, "w").write(s.replace(old3, new3, 1))
PY

cat > "$PATCHDIR/g02.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The `t == nil` COLLAPSE removed: an unannotated function falls through to the flow
# graph the way slice 77's reading of the row predicted.
#
# ★★★ PREDICTION: stopgate MOVED and tagpin RED — and DIAGPIN UNMOVED, which is the
# row's whole content. The two blocks behind the call are OUTSIDE it and
# record_unported does not abort, so every TS7010 still fires. **The collapse buys
# the ROW; g14 is the row that buys the REPORT.**
old = """        if t = null
        {
            if Checker.no_implicit_returns()
                this.record_unported("no-implicit-returns", AstNode.kind_of(fn))
            return
        }
        let ty t as ref[Type]"""
new = """        if t = null
        {
            if Checker.no_implicit_returns()
                this.record_unported("no-implicit-returns", AstNode.kind_of(fn))
            this.record_unported("flow-graph", AstNode.kind_of(fn))
            return
        }
        let ty t as ref[Type]"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g03.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The noImplicitReturns ASSERTION removed. PREDICTION: UNGATED, nothing moving — the
# option is false under this harness, so the line cannot fire. It prices the
# assertion at ZERO and g04 is what shows it bites.
old = """            if Checker.no_implicit_returns()
                this.record_unported("no-implicit-returns", AstNode.kind_of(fn))
            return"""
new = """            return"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g04.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# noImplicitReturns answers TRUE — the option moving, which is the one thing the
# collapse is not sound under. PREDICTION: stopgate MOVED by every unannotated
# function in the corpus. This is the row that makes g03's zero a measurement rather
# than a hope.
old = """    function no_implicit_returns() returns bool
        false"""
new = """    function no_implicit_returns() returns bool
        true"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g05.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# maybeTypeOfKind's VOID test dropped. PREDICTION: tagpin RED on
# checker_return_path_void, which walks out of the chapter today and would reach the
# flow graph instead; stopgate MOVED.
old = """        if Checker.maybe_type_of_kind(ty, TypeFlagsVoid)
            return"""
new = """        if false
            return"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g06.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The Any|Undefined half of the same early return dropped. PREDICTION: tagpin RED on
# checker_return_path_any ALONE — two fixtures for two halves of one `if`, which is
# why the pair exists.
old = """        if (ty.flags & (TypeFlagsAny | TypeFlagsUndefined)) <> 0
            return"""
new = """        if false
            return"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g07.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The MethodSignature term of the second guard dropped. PREDICTION: stopgate MOVED
# and the TAGPIN UNMOVED — checker_return_path_method_signature's container stops at
# check-index-constraints before the member walk, so the fixture can never carry this
# chapter's tag. The row is the reason that is written into the header.
old = """        if AstNode.kind_of(fn) = KindMethodSignature
            return"""
new = """        if false
            return"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g08.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The MISSING-BODY term dropped. PREDICTION: stopgate MOVED — an overload signature
# with a return annotation reaches the flow graph, which is what
# checker_return_path_overload_annotated is for.
old = """        let body AstNode.body_of(fn)
        if Binder.node_is_missing(body)
            return
        if AstNode.kind_of(body as ref[AstNode]) <> KindBlock"""
new = """        let body AstNode.body_of(fn)
        if Binder.node_is_missing(body)
            this.record_unported("flow-graph", AstNode.kind_of(fn))
        if body = null
            return
        if AstNode.kind_of(body as ref[AstNode]) <> KindBlock"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g09.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The IS-A-BLOCK term dropped. PREDICTION: UNGATED, nothing moving — and it is a
# statement about the CALL GRAPH rather than about the corpus. The term exists for an
# arrow function with an EXPRESSION body, and no arrow function reaches
# checkFunctionOrMethodDeclaration; the caller that gives it input is
# checkFunctionExpressionOrObjectLiteralMethod, which this port does not have.
old = """        if AstNode.kind_of(body as ref[AstNode]) <> KindBlock
            return"""
new = """        if false
            return"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g10.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# unwrapReturnType's GENERATOR arm dropped, so a generator's declared type is handed
# back unwrapped. PREDICTION: stopgate MOVED — checker_return_path_generator_annotated
# would take the void early return instead of logging the iteration stop. ★The tagpin
# cannot see it: checkSignatureDeclaration resolves the same annotation one call
# earlier and record_unported is first-wins.
old = """        if (function_flags & FunctionFlagsGenerator) <> 0
        {
            this.record_unported("get-iteration-type-of-generator-function-return-type", AstNode.kind_of(fn))
            return null
        }"""
new = """        if false
        {
            this.record_unported("get-iteration-type-of-generator-function-return-type", AstNode.kind_of(fn))
            return null
        }"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g11.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# unwrapReturnType's ASYNC arm dropped. PREDICTION: stopgate MOVED, tagpin unmoved —
# g10's row over the other flag.
old = """        if (function_flags & FunctionFlagsAsync) <> 0
        {
            this.record_unported("get-awaited-type-no-alias", AstNode.kind_of(fn))
            return null
        }"""
new = """        if false
        {
            this.record_unported("get-awaited-type-no-alias", AstNode.kind_of(fn))
            return null
        }"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g12.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The two unwrap arms SWAPPED, so async is asked before generator. PREDICTION:
# stopgate MOVED, on ONE unit — checker_return_path_async_generator_annotated, which
# carries both flags and is the only file that can tell the order apart. It logs the
# iteration stop today and would log the awaited one.
old = """        if (function_flags & FunctionFlagsGenerator) <> 0
        {
            this.record_unported("get-iteration-type-of-generator-function-return-type", AstNode.kind_of(fn))
            return null
        }
        if (function_flags & FunctionFlagsAsync) <> 0
        {
            this.record_unported("get-awaited-type-no-alias", AstNode.kind_of(fn))
            return null
        }"""
new = """        if (function_flags & FunctionFlagsAsync) <> 0
        {
            this.record_unported("get-awaited-type-no-alias", AstNode.kind_of(fn))
            return null
        }
        if (function_flags & FunctionFlagsGenerator) <> 0
        {
            this.record_unported("get-iteration-type-of-generator-function-return-type", AstNode.kind_of(fn))
            return null
        }"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g13.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# THE MARK TAKEN AT THE TOP OF THE PROCEDURE — the mistake the first draft of this
# slice made and MEASURED ZERO with. PREDICTION: stopgate MOVED and tagpin RED,
# because everything above can stop (the signature walk, the computed name, the body)
# and a procedure-wide mark reads *somebody stopped* as *the annotation stopped*.
# ★DIAGPIN unmoved for g02's reason.
old = """        let ret_mark this.unported_mark()
        let return_type this.get_return_type_from_annotation(node)"""
new = """        let ret_mark 0
        let return_type this.get_return_type_from_annotation(node)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g14.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# THE IMPLICIT-ANY BLOCK REMOVED, and the chapter left exactly as it is. PREDICTION:
# DIAGPIN RED on three fixtures at a LOSS with diagcheck UNGATED — the pair to g02.
# Between them the two rows prove the slice's two products are independent.
old = """        if AstNode.type_of(node) = null
        {
            let body AstNode.body_of(node)
            if Binder.node_is_missing(body)
            {
                if this.is_private_within_ambient(node) = false
                    this.report_implicit_any(node, any_type, WideningKindNormal)
            }"""
new = """        if false
        {
            let body AstNode.body_of(node)
            if Binder.node_is_missing(body)
            {
                if this.is_private_within_ambient(node) = false
                    this.report_implicit_any(node, any_type, WideningKindNormal)
            }"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g15.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# isPrivateWithinAmbient dropped — the ONE guard in front of TS7010. PREDICTION:
# diagcheck RED by INVENTION and DIAGPIN RED on checker_return_path_private_ambient
# alone: the port would report a TS7010 the reference does not have. ★The only row of
# this battery that can invent through the return path, and the reason the fixture
# exists.
old = """                if this.is_private_within_ambient(node) = false
                    this.report_implicit_any(node, any_type, WideningKindNormal)"""
new = """                this.report_implicit_any(node, any_type, WideningKindNormal)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g16.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The mapped type's reportImplicitAny removed — the state this file was in for
# twenty-one slices. PREDICTION: DIAGPIN RED on checker_mapped_type_implicit_any at a
# LOSS, diagcheck ungated. ★That is exactly why the defect survived: a dropped call
# is silent in both halves.
old = """        if AstNode.type_of(node) = null
            this.report_implicit_any(node, any_type, WideningKindNormal)
        this.record_unported("get-type-from-mapped-type-node", KindMappedType)"""
new = """        this.record_unported("get-type-from-mapped-type-node", KindMappedType)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g17.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The mapped type's guard INVERTED, so a mapped type WITH a value type reports.
# PREDICTION: diagcheck RED by invention — the second of the battery's two inventing
# rows, and the one that shows the guard is a question about the node rather than a
# formality.
old = """        if AstNode.type_of(node) = null
            this.report_implicit_any(node, any_type, WideningKindNormal)"""
new = """        if AstNode.type_of(node) <> null
            this.report_implicit_any(node, any_type, WideningKindNormal)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g18.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# checkGrammarForGenerator removed from checkFunctionDeclaration — one of the two
# lines slice 52 named and handed forward. PREDICTION: DIAGPIN RED at a LOSS on
# checker_return_path_generator_overload (TS1222), diagcheck ungated.
old = """        this.check_grammar_for_generator(node)
"""
new = """"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g19.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# checkCollisionsForDeclarationName removed from checkFunctionDeclaration — the other
# named line.
#
# ★★★ PREDICTED SILENT AGAINST THE CORPUS AND IT WAS, AND THE ROW IS §3.5v's FIRST
# KIND RATHER THAN ITS SECOND. Neither of the function's two kind branches can fire
# for a function declaration (IsClassLike, IsEnumDeclaration), so the five checks in
# front of them are all this call site can add — and one of the five IS live here.
# The discriminating text is a top-level `function require()` in a module (TS2441),
# which the corpus does not contain and checker_function_declaration_collision.ts now
# does. PREDICTION with the fixture: DIAGPIN RED at a LOSS, diagcheck ungated.
old = """        this.check_collisions_for_declaration_name(node, AstNode.name_of(node))
    }

    ; ── slice 82: the non-void return path"""
new = """    }

    ; ── slice 82: the non-void return path"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g20.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# getReturnTypeFromAnnotation's CONSTRUCTOR arm dropped. PREDICTION: UNGATED, nothing
# moving — a statement about the CALL GRAPH and not about the corpus. This port's one
# caller is checkFunctionOrMethodDeclaration, which sees FunctionDeclaration,
# MethodDeclaration and MethodSignature; a constructor arrives with
# checkConstructorDeclaration or getReturnTypeOfSignature. ★The arm is written anyway
# because nil is this function's answer for *there is no annotation*, so an omission
# is a wrong answer waiting for the second caller and not a missing row.
old = """        if k = KindConstructor
        {
            ; `getDeclaredTypeOfClassOrInterface"""
new = """        if false
        {
            ; `getDeclaredTypeOfClassOrInterface"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g21.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# getReturnTypeFromAnnotation's GET-ACCESSOR stop dropped. PREDICTION: UNGATED for
# g20's reason and not a new one — the same call-graph measurement over the other
# armless arm. The two are separate rows because they get DIFFERENT treatment in the
# source (one written, one stopped) and a battery that broke only one would leave the
# reason for the difference untested.
old = """            this.record_unported("get-annotated-accessor-type", k)
            return null"""
new = """            return null
            this.record_unported("get-annotated-accessor-type", k)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g22.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# getReturnTypeOfFullSignature's stop removed. PREDICTION: stopgate MOVED with a
# SMALL number — one unit over stage 1 carries a JSDoc `@type` on a function in a
# JavaScript file, which is what the whole three-conjunct guard is for.
old = """        this.record_unported("get-signature-of-full-signature-type", k)
        null
    }"""
new = """        null
    }"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g23.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The FullSignature block's stop removed. PREDICTION: stopgate MOVED by one — the
# same JavaScript unit from the other side, and the pair is what shows the two
# guards are the same three conjuncts read twice.
old = """            this.record_unported("get-contextual-call-signature", AstNode.kind_of(node))"""
new = """"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g24.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The implicit-any block's `node.Type() == nil` guard INVERTED. PREDICTION: diagcheck
# RED by invention — every ANNOTATED overload signature would get a TS7010, which is
# what checker_return_path_overload_annotated is the witness for. The third inventing
# row, and the one that shows the two overload fixtures are a PAIR.
old = """        if AstNode.type_of(node) = null
        {
            let body AstNode.body_of(node)
            if Binder.node_is_missing(body)"""
new = """        if AstNode.type_of(node) <> null
        {
            let body AstNode.body_of(node)
            if Binder.node_is_missing(body)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g25.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# THE CLASS'S MEMBER WALK REMOVED — the state this file was in for thirty-two slices,
# under a note saying the line was *not reached*. PREDICTION: DIAGPIN RED at a LOSS on
# checker_return_path_class_overload, diagcheck ungated with a NUMBER, stopgate MOVED
# by ~700 events. ★It is the row that makes g15 an invention test rather than a
# reachability one: without the walk, g15 moves nothing at all.
old = """        this.check_source_elements(AstNode.member_list_of(node))
        ; `c.registerForUnusedIdentifiersCheck(node)` is omitted for the reason"""
new = """        ; `c.registerForUnusedIdentifiersCheck(node)` is omitted for the reason"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

# ── the dry run ─────────────────────────────────────────────────────────────
bold "DRY RUN — every patch against a copy of the tree"
DRY=$WORK/dry
for g in g01 g02 g03 g04 g05 g06 g07 g08 g09 g10 g11 g12 g13 g14 g15 g16 g17 g18 g19 g20 g21 g22 g23 g24 g25; do
  rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
  if python3 "$PATCHDIR/$g.py" "$DRY/f.scaly" >/dev/null 2>&1; then
    echo "  $g applies"
  else
    red "  $g DOES NOT APPLY — its anchor has moved."; exit 2
  fi
done
rm -rf "$DRY"

baseline

control "g01 the chapter reverted to slice 63's stop (the premise)"           "$CHECKER" "$PATCHDIR/g01.py"
control "g02 the t == nil collapse removed"                                   "$CHECKER" "$PATCHDIR/g02.py"
control "g03 the noImplicitReturns assertion removed"                         "$CHECKER" "$PATCHDIR/g03.py"
control "g04 noImplicitReturns answers TRUE"                                  "$CHECKER" "$PATCHDIR/g04.py"
control "g05 the VOID half of the first early return dropped"                 "$CHECKER" "$PATCHDIR/g05.py"
control "g06 the ANY|UNDEFINED half of the first early return dropped"        "$CHECKER" "$PATCHDIR/g06.py"
control "g07 the MethodSignature term of the second guard dropped"            "$CHECKER" "$PATCHDIR/g07.py"
control "g08 the missing-body term of the second guard dropped"               "$CHECKER" "$PATCHDIR/g08.py"
control "g09 the is-a-Block term of the second guard dropped"                 "$CHECKER" "$PATCHDIR/g09.py"
control "g10 unwrapReturnType's generator arm dropped"                        "$CHECKER" "$PATCHDIR/g10.py"
control "g11 unwrapReturnType's async arm dropped"                            "$CHECKER" "$PATCHDIR/g11.py"
control "g12 unwrapReturnType's two arms swapped"                             "$CHECKER" "$PATCHDIR/g12.py"
control "g13 the mark taken at the top of the procedure"                      "$CHECKER" "$PATCHDIR/g13.py"
control "g14 the implicit-any block removed"                                  "$CHECKER" "$PATCHDIR/g14.py"
control "g15 isPrivateWithinAmbient dropped"                                  "$CHECKER" "$PATCHDIR/g15.py"
control "g16 the mapped type's reportImplicitAny removed"                     "$CHECKER" "$PATCHDIR/g16.py"
control "g17 the mapped type's guard inverted"                                "$CHECKER" "$PATCHDIR/g17.py"
control "g18 checkGrammarForGenerator removed from checkFunctionDeclaration"  "$CHECKER" "$PATCHDIR/g18.py"
control "g19 checkCollisionsForDeclarationName removed from the same"         "$CHECKER" "$PATCHDIR/g19.py"
control "g20 getReturnTypeFromAnnotation's constructor arm dropped"           "$CHECKER" "$PATCHDIR/g20.py"
control "g21 getReturnTypeFromAnnotation's get-accessor stop dropped"         "$CHECKER" "$PATCHDIR/g21.py"
control "g22 getReturnTypeOfFullSignature's stop removed"                     "$CHECKER" "$PATCHDIR/g22.py"
control "g23 the FullSignature block's stop removed"                          "$CHECKER" "$PATCHDIR/g23.py"
control "g24 the implicit-any block's node.Type() guard inverted"             "$CHECKER" "$PATCHDIR/g24.py"
control "g25 the class's member walk removed"                                 "$CHECKER" "$PATCHDIR/g25.py"

echo
echo "################################################################"
bold "DONE — read every row against its PREDICTION, not against its colour."
