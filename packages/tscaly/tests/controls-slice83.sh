#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice83.sh — the slice-83 battery: THE CLASS'S LAST MEMBERS, and three
# findings that are all one shape — a claim about the reference that nobody re-read.
#
# ★★★ THE SLICE CLOSES A ROW RATHER THAN SHRINKING ONE. `check <kind>` — the tag
# check_source_element_worker records for a kind whose arm this port has not written
# — was 104 units over eight kinds and is now ZERO: the constructor, the accessor
# pair, the class static block and the missing declaration are arms, and three kinds
# the reference's switch has NO case for went to kind_has_no_check_arm. Every one of
# checkSourceElementWorker's fifty-nine case labels is reached at stage 1.
#
# ★★★ THREE OF THE SLICE'S FOUR FINDINGS CAME FROM A FIXTURE READ AGAINST THE
# REFERENCE BY HAND, and each one is invisible to diagcheck by construction:
#
#   1. TS2378's test is a BINDER FLAG this port never writes. NodeFlagsHasImplicitReturn
#      is declared in NodeFlags.scaly (*set by the binder*) and set NOWHERE; upstream
#      it comes out of the flow graph. Writing the four-term test answers FALSE on
#      every input — a LOSS, and **diagcheck compares a SUBSEQUENCE, so a line this
#      port never emits is invisible to it.** The first draft was green on all 1 371
#      units with the report dead. g24 is that draft.
#   2. TS2390 reached its report and was DROPPED: error_range_for_node has no
#      Constructor arm, so error_on_node recorded `error-range 177` instead. The
#      deferral note on error_range_needs_rescan had named this exact reader —
#      *the grammar checks report on … a constructor* — two slices before it came
#      due. g10 and g11 are that arm.
#   3. The constructor arm's first draft claimed its extends test is taken on every
#      reachable input, because check_class_like_declaration RETURNS at its own
#      stop. It does; it does not stop its CALLER. **A `return` inside a callee is
#      not an exit from the walk.** g08 lifts the walk and is what prices the claim.
#
# ★★★ AND THE FOURTH IS THE INSTRUMENT, WHICH IS WHY g09 EXISTS. `is_unported()`
# answers *has this UNIT stopped* and `unported_mark()` answers *did THIS call stop*;
# the two are indistinguishable at any call site that is the unit's FIRST stop, which
# is every site the class and interface arms have. This slice's is not — the class
# arm stopped before the member walk reached it — so the wrong one logged five units'
# worth of a stop that had already reported.
#
# ★★ MOST ROWS HERE ARE A LOSS AND THE DIAGPIN IS THE POSITIVE INSTRUMENT. The
# slice's product is fifteen grammar and semantic reports; breaking one removes a
# line, which a subsequence cannot see. Only g04, g20 and g26 can INVENT.
#
# ★★★ ITERATE AT STAGE 1 AND CONFIRM AT STAGE 2 ONCE — slice 64's rule. The recorded
# verdicts are stage 1's.
#
# Usage (nothing may edit the tree while this runs, and no second harness may own
# tests/out — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # stage 1, ~35 s
#   packages/tscaly/tests/controls-slice83.sh 2>&1 | tee /tmp/battery83.log

set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.0/tscaly/checker.scaly
BINDER=$PKG/0.1.0/tscaly/binder.scaly
FIX=$PKG/tests/fixtures

LIBSCALY=${LIBSCALY:-/tmp/libscaly.a}
SCALYC=${SCALYC:-$REPO/scalyc/build/scalyc}

# ★ ONE MECHANISM PER FILE (slice 72's rule): the tagpin is first-wins, so a fixture
# naming two mechanisms is a fixture nobody can read a red row off.
#
# ★★ EVERY ONE OF THESE STOPS AT THE CLASS'S OWN `check-index-constraints`, so the
# TAGPIN is nearly inert here and the STOPPIN — the whole stop log, in order — is
# what carries the walk. Said once rather than re-derived from a column that does
# not move.
PINFILES="
$FIX/checker_ctor_type_parameters.ts
$FIX/checker_ctor_type_annotation.ts
$FIX/checker_ctor_grammar_pair.ts
$FIX/checker_ctor_overload.ts
$FIX/checker_ctor_overload_modifiers.ts
$FIX/checker_ctor_derived.ts
$FIX/checker_ctor_derived_overload.ts
$FIX/checker_class_static_block.ts
$FIX/checker_accessor_missing_body.ts
$FIX/checker_accessor_abstract_body.ts
$FIX/checker_accessor_ambient_body.ts
$FIX/checker_accessor_type_parameters.ts
$FIX/checker_accessor_getter_parameters.ts
$FIX/checker_accessor_setter_arity.ts
$FIX/checker_accessor_setter_return_type.ts
$FIX/checker_accessor_setter_rest.ts
$FIX/checker_accessor_setter_optional.ts
$FIX/checker_accessor_setter_initializer.ts
$FIX/checker_accessor_named_constructor.ts
$FIX/checker_accessor_interface_constructor.ts
$FIX/checker_accessor_implicit_return.ts
$FIX/checker_accessor_abstract_mismatch.ts
$FIX/checker_accessor_accessibility.ts
$FIX/checker_accessor_computed_name.ts
$FIX/checker_accessor_this_parameter.ts
$FIX/checker_semicolon_class_element.ts
$FIX/checker_missing_declaration.ts
$FIX/checker_jsdoc_optional_variadic.js
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
    echo "  diagpin   unmoved — all twenty-eight pin files answer the same C section."
  else
    green "diagpin   RED"
    diff "$WORK/base.diags" "$WORK/ctl.diags" | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.tags" "$WORK/ctl.tags"; then
    echo "  tagpin    unmoved — all twenty-eight fixtures answer the same tag."
  else
    green "tagpin    RED"
    diff "$WORK/base.tags" "$WORK/ctl.tags" | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.stops" "$WORK/ctl.stops"; then
    echo "  stoppin   unmoved — all twenty-eight fixtures log the same stops, in order."
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
# ★★★ THE PREMISE ROW: the four arms reverted to the stop they replaced.
# PREDICTION: DIAGPIN RED at a LOSS on nearly every pin file, diagcheck ungated with
# a NUMBER, stopgate MOVED by the whole chapter, and `check <kind>` back on the work
# list at 104 units.
old = """        if k = KindClassStaticBlockDeclaration
            return true
        if k = KindConstructor
            return true
        if k = KindGetAccessor
            return true
        if k = KindSetAccessor
            return true
        if k = KindMissingDeclaration
            return true"""
new = """        if k = KindClassStaticBlockDeclaration
            return false"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g02.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# checkGrammarConstructorTypeParameters removed. PREDICTION: DIAGPIN RED at a LOSS on
# checker_ctor_type_parameters (TS1092) and on nothing else; diagcheck ungated.
old = """        if this.check_grammar_constructor_type_parameters(node) = false
            this.check_grammar_constructor_type_annotation(node)"""
new = """        this.check_grammar_constructor_type_annotation(node)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g03.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# checkGrammarConstructorTypeAnnotation removed. PREDICTION: DIAGPIN RED at a LOSS on
# checker_ctor_type_annotation (TS1093) alone.
old = """        if this.check_grammar_constructor_type_parameters(node) = false
            this.check_grammar_constructor_type_annotation(node)"""
new = """        this.check_grammar_constructor_type_parameters(node)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g04.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The `&&` read as two INDEPENDENT checks. PREDICTION: diagcheck RED by INVENTION —
# `constructor<T>(): void` gets TS1092 AND TS1093 where the reference gives one, and
# a diagnostic we emit that the reference does not is the one direction a subsequence
# catches. ★It came back UNGATED on the battery's first run and the cause was a
# MISSING FIXTURE — no file carried both violations. checker_ctor_grammar_pair is
# that file, and it is what turns this row from a hope into a measurement.
old = """        if this.check_grammar_constructor_type_parameters(node) = false
            this.check_grammar_constructor_type_annotation(node)"""
new = """        this.check_grammar_constructor_type_parameters(node)
        this.check_grammar_constructor_type_annotation(node)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g05.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# checkFunctionOrConstructorSymbol removed from the constructor arm. PREDICTION:
# DIAGPIN RED at a LOSS on both overload fixtures (TS2390) and STOPPIN RED (the
# `get-signatures-of-symbol` arrival goes with it).
old = """        let symbol this.symbol_of_declaration(node)
        if symbol <> null
            this.check_function_or_constructor_symbol(symbol as ref[Symbol])
        ; The reference's own comment at the line: *exit early in the case of"""
new = """        let symbol this.symbol_of_declaration(node)
        if false
            this.check_function_or_constructor_symbol(symbol as ref[Symbol])
        ; The reference's own comment at the line: *exit early in the case of"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g06.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The constructor's BODY WALK removed. PREDICTION: STOPPIN RED on checker_ctor_derived
# (the `super()` call's check-call-expression disappears) and stopgate MOVED.
old = """        this.check_source_element(AstNode.body_of(node))
        ; getSymbolOfDeclaration is total upstream;"""
new = """        ; getSymbolOfDeclaration is total upstream;"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g07.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The missing-body early return dropped, so an overload SIGNATURE walks into the
# super-call block. PREDICTION: STOPPIN RED on checker_ctor_derived_overload and
# stopgate MOVED — the reference's own comment says the block is *not relevant to
# them*. ★★★It came back UNGATED against the base-less overload fixtures alone, and
# that silence is a PROOF rather than a gap: for a class with no `extends` the very
# next test returns anyway, so the two guards are indistinguishable and only a
# DERIVED class with an overload separates them.
old = """        if Binder.node_is_missing(AstNode.body_of(node))
            return
        let containing_class AstNode.parent_node_of(node)"""
new = """        if false
            return
        let containing_class AstNode.parent_node_of(node)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g08.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE REACHABILITY ROW, AND IT IS THE ONE THAT PRICES THE FIRST DRAFT'S WRONG
# CLAIM. The class's member walk removed — the line slice 82 added. PREDICTION:
# DIAGPIN RED at a LOSS on EVERY class fixture here, because nothing then hands a
# constructor or an accessor to check_source_element at all. It is what makes every
# other row in this battery a measurement rather than a hope.
old = """        this.check_source_elements(AstNode.member_list_of(node))
        ; `c.registerForUnusedIdentifiersCheck(node)` is omitted for the reason"""
new = """        ; `c.registerForUnusedIdentifiersCheck(node)` is omitted for the reason"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g09.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE INSTRUMENT ROW: the mark read as `is_unported()`, which is the mistake the
# first draft made. PREDICTION: STOPPIN RED on checker_ctor_derived — the unit has
# already stopped at the class arm, so the bool cannot change and a
# `find-first-super-call` stop is logged behind a report that already fired.
old = """        let mark this.unported_mark()
        let extends_null this.class_declaration_extends_null(containing_class as ref[AstNode])
        if this.unported_mark() <> mark
            return"""
new = """        let mark this.is_unported()
        let extends_null this.class_declaration_extends_null(containing_class as ref[AstNode])
        if this.is_unported() <> mark
            return"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g10.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE ERROR-RANGE ROW: the Constructor arm removed from error_range_for_node —
# the state this port was in until this slice. PREDICTION: DIAGPIN RED at a LOSS on
# both overload fixtures (TS2390 vanishes) and STOPPIN RED, because error_on_node
# then records `error-range 177` in the report's place. **The report REACHED its
# reporter and was dropped; nothing in diagcheck could see it.**
old = """        if k = KindConstructor
        {
            if (AstNode.flags_of(n) & NodeFlagsReparsed) = 0
            {
                this.range_of_constructor_keyword(AstNode.pos_of(n), out_start, out_end)
                return true
            }
        }"""
new = """        if k = KindConstructor
        {
            if (AstNode.flags_of(n) & NodeFlagsReparsed) = 0
            {
                this.record_unported("error-range", k)
                return false
            }
        }"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g11.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The scan LOOP replaced by ONE scan — the shape a reader would write without the
# reference's own loop. PREDICTION: DIAGPIN RED on checker_ctor_overload_modifiers
# ALONE, at a WRONG SPAN rather than a loss: `private constructor` starts at
# `private`, so the single scan ends at the modifier and reports 272..279 instead of
# 272..291. ★checker_ctor_overload has no modifier and both spellings agree on it,
# which is why the two overload fixtures are a PAIR.
old = """        var k trivia.token()
        while k <> KindConstructorKeyword
        {
            if k = KindStringLiteral
                set k: KindConstructorKeyword
            else
            {
                if k = KindEndOfFile
                    set k: KindConstructorKeyword
                else
                {
                    trivia.scan()
                    set k: trivia.token()
                }
            }
        }
        set *out_end: trivia.token_end()"""
new = """        set *out_end: trivia.token_end()"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g12.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The loop's STRING-LITERAL terminator dropped. PREDICTION: UNGATED on this corpus —
# the terminator is for a quoted member name in a class body, which no fixture here
# carries; the EndOfFile guard catches the same shape one token later. It is a row
# about the loop being the reference's rather than about a corpus gap, and its
# silence is the measurement.
old = """            if k = KindStringLiteral
                set k: KindConstructorKeyword
            else
            {
                if k = KindEndOfFile"""
new = """            if false
                set k: KindConstructorKeyword
            else
            {
                if k = KindEndOfFile"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g13.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# checkGrammarModifiers removed from the static block. PREDICTION: UNGATED with
# nothing moving on this corpus — checker_class_static_block carries no modifier and
# a `static` block's own `static` is not a modifier NODE. The row is here because the
# arm is two lines and the OTHER one is g14, so a silent pair would leave the arm
# untested; read the two together.
old = """    procedure check_class_static_block_declaration(this, node: ref[AstNode])
    {
        this.check_grammar_modifiers(node)
        this.check_each_child_source_element(node)
    }"""
new = """    procedure check_class_static_block_declaration(this, node: ref[AstNode])
    {
        this.check_each_child_source_element(node)
    }"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g14.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The static block's CHILD WALK removed. PREDICTION: STOPPIN RED on
# checker_class_static_block — its `let x = 1` is what reaches
# check-type-assignable-to — and stopgate MOVED.
old = """    procedure check_class_static_block_declaration(this, node: ref[AstNode])
    {
        this.check_grammar_modifiers(node)
        this.check_each_child_source_element(node)
    }"""
new = """    procedure check_class_static_block_declaration(this, node: ref[AstNode])
    {
        this.check_grammar_modifiers(node)
    }"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g15.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# checkGrammarAccessor's MISSING-BODY branch removed. PREDICTION: DIAGPIN RED at a
# LOSS on checker_accessor_missing_body (TS1005) alone.
old = """                if body = null
                {
                    if b.has_syntactic_modifier(accessor, ModifierFlagsAbstract) = false
                        return this.grammar_error_at_pos(AstNode.end_of(accessor) - 1, 1, DiagX_0_expected)
                }"""
new = """                if false
                {
                    if b.has_syntactic_modifier(accessor, ModifierFlagsAbstract) = false
                        return this.grammar_error_at_pos(AstNode.end_of(accessor) - 1, 1, DiagX_0_expected)
                }"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g16.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The missing-body branch's `abstract` term dropped, so an ABSTRACT accessor with no
# body reports too. PREDICTION: diagcheck RED by INVENTION on
# checker_accessor_abstract_mismatch, whose `abstract get x(): number;` is exactly
# that shape — one of the three rows in this battery that can invent.
old = """                    if b.has_syntactic_modifier(accessor, ModifierFlagsAbstract) = false
                        return this.grammar_error_at_pos(AstNode.end_of(accessor) - 1, 1, DiagX_0_expected)"""
new = """                    if true
                        return this.grammar_error_at_pos(AstNode.end_of(accessor) - 1, 1, DiagX_0_expected)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g17.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The abstract-with-implementation branch removed. PREDICTION: DIAGPIN RED at a LOSS
# on checker_accessor_abstract_body (TS1318) alone.
old = """            if b.has_syntactic_modifier(accessor, ModifierFlagsAbstract)
                return this.grammar_error_on_node(accessor, DiagAn_abstract_accessor_cannot_have_an_implementation)
            if in_type_container"""
new = """            if false
                return this.grammar_error_on_node(accessor, DiagAn_abstract_accessor_cannot_have_an_implementation)
            if in_type_container"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g18.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The ambient-container branch removed. PREDICTION: DIAGPIN RED at a LOSS on
# checker_accessor_ambient_body (TS1183) alone — the accessor with a body inside an
# INTERFACE, which is what the in_type_container flag is for on both of its readings.
old = """            if in_type_container
                return this.grammar_error_on_node(body as ref[AstNode], DiagAn_implementation_cannot_be_declared_in_ambient_contexts)"""
new = """            if false
                return this.grammar_error_on_node(body as ref[AstNode], DiagAn_implementation_cannot_be_declared_in_ambient_contexts)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g19.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The accessor's TYPE-PARAMETER branch removed. PREDICTION: DIAGPIN RED at a LOSS on
# checker_accessor_type_parameters (TS1094) alone.
old = """        if AstNode.type_parameters_of(accessor) <> null
            return this.grammar_error_on_node_or_null(name, DiagAn_accessor_cannot_have_type_parameters)"""
new = """        if false
            return this.grammar_error_on_node_or_null(name, DiagAn_accessor_cannot_have_type_parameters)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g20.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# doesAccessorHaveCorrectParameterCount's `this`-parameter arm dropped. PREDICTION:
# diagcheck RED by INVENTION on checker_accessor_this_parameter — `get x(this: C)`
# has arity 1 where a getter's plain arity is 0, so without the arm it gets a
# spurious TS1054 and the setter a TS1049. **The reference's own comment is the
# specification and this row is what holds it to a number.**
old = """        if n <> plain + 1
            return false
        AstNode.is_this_parameter(AstNode.child_in_list(parameters, 0))"""
new = """        if n <> plain + 1
            return false
        false"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g21.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The get/set message choice inverted. PREDICTION: DIAGPIN RED on
# checker_accessor_getter_parameters and checker_accessor_setter_arity, each at the
# OTHER'S code — a wrong code at a right span, which is the failure diagcheck was
# built to catch and which a LOSS-only battery would miss.
old = """            var code: int DiagA_set_accessor_must_have_exactly_one_parameter
            if AstNode.kind_of(accessor) = KindGetAccessor
                set code: DiagA_get_accessor_cannot_have_parameters"""
new = """            var code: int DiagA_get_accessor_cannot_have_parameters
            if AstNode.kind_of(accessor) = KindGetAccessor
                set code: DiagA_set_accessor_must_have_exactly_one_parameter"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g22.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The setter's RETURN-TYPE branch removed. PREDICTION: DIAGPIN RED at a LOSS on
# checker_accessor_setter_return_type (TS1095) alone.
old = """        if AstNode.type_of(accessor) <> null
            return this.grammar_error_on_node_or_null(name, DiagA_set_accessor_cannot_have_a_return_type_annotation)"""
new = """        if false
            return this.grammar_error_on_node_or_null(name, DiagA_set_accessor_cannot_have_a_return_type_annotation)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g23.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# GetSetAccessorValueParameter's `this` SKIP removed, so the parameter examined is
# the `this` one. PREDICTION: UNGATED with nothing moving — checker_accessor_this_parameter's
# `this: C` carries no dot-dot-dot, no question mark and no initializer, so reading
# the wrong parameter gives the same three answers. **It is the row that shows a
# fixture can pin an ARITY and still not pin a SELECTION**, and its silence is the
# measurement rather than a hole.
old = """        var i 0
        if n = 2
        {
            if AstNode.is_this_parameter(AstNode.child_in_list(parameters, 0))
                set i: 1
        }
        AstNode.child_in_list(parameters, i)"""
new = """        var i 0
        AstNode.child_in_list(parameters, i)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g24.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE SLICE'S FIRST FINDING, PUT BACK: TS2378 written as the reference's
# four-term test on flags this port never sets. PREDICTION: STOPPIN RED on every
# getter fixture (the `flow-graph` arrival vanishes) and stopgate MOVED — and
# **diagcheck UNGATED and DIAGPIN UNMOVED, which is the whole row**: the report is
# dead, the port loses TS2378 corpus-wide, and no subsequence instrument can tell.
old = """            if (AstNode.flags_of(node) & NodeFlagsAmbient) = 0
            {
                if Binder.node_is_missing(AstNode.body_of(node)) = false
                    this.record_unported("flow-graph", AstNode.kind_of(node))
            }"""
new = """            let f AstNode.flags_of(node)
            if (f & NodeFlagsAmbient) = 0
            {
                if Binder.node_is_missing(AstNode.body_of(node)) = false
                {
                    if (f & NodeFlagsHasImplicitReturn) <> 0
                    {
                        if (f & NodeFlagsHasExplicitReturn) = 0
                            this.error_on_node_or_null(name, DiagA_get_accessor_must_return_a_value)
                    }
                }
            }"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g25.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The `constructor`-named-accessor report removed. PREDICTION: DIAGPIN RED at a LOSS
# on checker_accessor_named_constructor (TS1341) alone. ★It is the one report of this
# arm that is a `c.error` and not a grammar error, so it survives a file with parse
# diagnostics — which is why it is written where the reference writes it rather than
# folded into check_grammar_accessor.
old = """            if Checker.identifier_text_equals(name as ref[AstNode], "constructor", 11)
            {
                if Parser.is_class_like_node(AstNode.parent_node_of(node))
                    this.error_on_node(name as ref[AstNode], DiagClass_constructor_may_not_be_an_accessor)
            }"""
new = """            if false
            {
                if Parser.is_class_like_node(AstNode.parent_node_of(node))
                    this.error_on_node(name as ref[AstNode], DiagClass_constructor_may_not_be_an_accessor)
            }"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g26.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The CLASS-LIKE term of that report dropped, so a `get constructor()` in an
# interface reports too. PREDICTION: diagcheck RED by INVENTION on
# checker_accessor_interface_constructor. ★It came back UNGATED on the first run for
# §3.5v's FIRST reason — no fixture carried the shape — and that fixture is the row's
# whole content.
old = """                if Parser.is_class_like_node(AstNode.parent_node_of(node))
                    this.error_on_node(name as ref[AstNode], DiagClass_constructor_may_not_be_an_accessor)"""
new = """                if true
                    this.error_on_node(name as ref[AstNode], DiagClass_constructor_may_not_be_an_accessor)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g27.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# hasBindableName's guard inverted, so the accessibility block runs for a COMPUTED
# name too. PREDICTION: STOPPIN RED on checker_accessor_computed_name — the
# `is-late-bindable-name` arrival is replaced by whatever the block reaches — and the
# stopgate MOVED. ★The pair to it is g28, which removes the block from the other
# side.
old = """        if b.has_dynamic_name(node)
            this.record_unported("is-late-bindable-name", AstNode.kind_of(node))
        else
            this.check_accessor_declaration_flags(node)"""
new = """        if false
            this.record_unported("is-late-bindable-name", AstNode.kind_of(node))
        else
            this.check_accessor_declaration_flags(node)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g28.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The accessibility block removed entirely. PREDICTION: DIAGPIN RED at a LOSS on
# checker_accessor_abstract_mismatch (two TS2676) and checker_accessor_accessibility
# (two TS2808), and on nothing else; diagcheck ungated.
old = """        if b.has_dynamic_name(node)
            this.record_unported("is-late-bindable-name", AstNode.kind_of(node))
        else
            this.check_accessor_declaration_flags(node)"""
new = """        if b.has_dynamic_name(node)
            this.record_unported("is-late-bindable-name", AstNode.kind_of(node))"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g29.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE ONCE-BIT REMOVED. PREDICTION: diagcheck RED by INVENTION — the pair is
# reached through BOTH of its declarations, so every one of the four reports fires
# TWICE. It is the third of the three rows here that can invent, and the reason the
# bit needed a fourth links table rather than a local.
old = """        let links this.node_link_of(g)
        if links.type_checked
            return
        set links.type_checked: true"""
new = """        let links this.node_link_of(g)
        if false
            return
        set links.type_checked: true"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g30.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The once-bit taken on the SETTER instead of the getter. PREDICTION: UNGATED with
# nothing moving — with one getter and one setter per symbol the two keys are
# reached in the same order and either bit suppresses the second visit. The row is
# here because the reference is specific (`c.nodeLinks.Get(getter)`) and a reader
# would want to know whether the choice is load-bearing on this corpus; it is not,
# and a merged declaration with two getters is the shape that would separate them.
old = """        let links this.node_link_of(g)"""
new = """        let links this.node_link_of(s)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g31.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The ABSTRACT-mismatch test removed. PREDICTION: DIAGPIN RED at a LOSS on
# checker_accessor_abstract_mismatch (two TS2676) alone — its pair is g32, and the
# two show the block's two findings are independent.
old = """        if (gf & ModifierFlagsAbstract) <> (sf & ModifierFlagsAbstract)
        {
            this.error_on_node_or_null(AstNode.name_of(g), DiagAccessors_must_both_be_abstract_or_non_abstract)
            this.error_on_node_or_null(AstNode.name_of(s), DiagAccessors_must_both_be_abstract_or_non_abstract)
        }"""
new = """        if false
        {
            this.error_on_node_or_null(AstNode.name_of(g), DiagAccessors_must_both_be_abstract_or_non_abstract)
            this.error_on_node_or_null(AstNode.name_of(s), DiagAccessors_must_both_be_abstract_or_non_abstract)
        }"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g32.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The PRIVATE half of the accessibility test dropped. PREDICTION: DIAGPIN RED at a
# LOSS on checker_accessor_accessibility (two TS2808) alone — its getter is `private`
# and its setter is not, which is the second of the reference's two disjuncts. ★The
# PROTECTED half has no fixture here and is deliberately left to the disjunct's own
# shape rather than given a row that could only come back silent.
old = """        if (gf & ModifierFlagsPrivate) <> 0
        {
            if (sf & ModifierFlagsPrivate) = 0
                set accessibility_mismatch: true
        }"""
new = """        if false
        {
            if (sf & ModifierFlagsPrivate) = 0
                set accessibility_mismatch: true
        }"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g33.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The getTypeOfAccessors stop removed. PREDICTION: STOPPIN RED on every accessor
# fixture and stopgate MOVED — it is the arm's terminal stop, and removing it claims
# the accessor's TYPE is answered.
old = """        this.record_unported("get-type-of-accessors", AstNode.kind_of(node))"""
new = """        if false
            this.record_unported("get-type-of-accessors", AstNode.kind_of(node))"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g34.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The accessor's BODY WALK removed. PREDICTION: STOPPIN RED and stopgate MOVED — the
# walk runs PAST the stop above it, which is check_source_elements' discipline and
# the only reason an accessor body's statements are measured at all.
old = """        this.check_source_element(AstNode.body_of(node))
        ; setNodeLinksForPrivateIdentifierScope(node) — check_property_declaration's
        ; header carries the argument for all three call sites.
    }"""
new = """        ; setNodeLinksForPrivateIdentifierScope(node) — check_property_declaration's
        ; header carries the argument for all three call sites.
    }"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g35.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# SemicolonClassElement taken back out of kind_has_no_check_arm. PREDICTION: STOPPIN
# RED on checker_semicolon_class_element — `check 241` comes back, a row naming a
# function the reference does not have — and the stopgate MOVED.
old = """        if k = KindSemicolonClassElement
            return true
        if k = KindJSDocOptionalType"""
new = """        if k = KindJSDocOptionalType"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g36.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The two JSDoc kinds taken back out. PREDICTION: STOPPIN RED on
# checker_jsdoc_optional_variadic.js — `check 313` and `check 314` come back — and the
# stopgate MOVED. ★They are ONE row because they are one reading of the reference's
# `case` label: it names NonNullable, Nullable, All and TypeLiteral, and neither of
# these two is on it.
old = """        if k = KindJSDocOptionalType
            return true
        if k = KindJSDocVariadicType
            return true"""
new = """        if false
            return true"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g37.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The MissingDeclaration TABLE ENTRY removed. PREDICTION: STOPPIN RED on
# checker_missing_declaration — `check 283` comes back — and the stopgate MOVED.
# ★★★It is the TABLE that is observable and not the arm: kind_has_ported_check_arm is
# what decides whether the walk records `check <kind>`, so removing the arm alone
# leaves the dispatch falling through in silence. The first draft of this row removed
# the arm and came back UNGATED for exactly that reason; g38 is what is left of it.
old = """        if k = KindSetAccessor
            return true
        if k = KindMissingDeclaration
            return true"""
new = """        if k = KindSetAccessor
            return true"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g38.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The MissingDeclaration arm's checkDecorators call removed. PREDICTION: UNGATED with
# nothing moving, and it is a PROOF rather than a corpus gap: ast.can_have_decorators
# enumerates seven kinds — Parameter, PropertyDeclaration, MethodDeclaration, the two
# accessors, ClassExpression, ClassDeclaration — and MissingDeclaration is not among
# them, so checkDecorators returns at its first line for every input this arm can
# receive. **checkMissingDeclaration is one line upstream and that line is inert
# here.** The arm exists so the kind stops being a work-list row, and g37 is the half
# that measures that.
old = """        if k = KindMissingDeclaration
        {
            this.check_decorators(node)
            return
        }"""
new = """        if k = KindMissingDeclaration
            return"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

# ── the dry run ─────────────────────────────────────────────────────────────
#
# ★ Every patch is applied against a COPY of its target before a single build is
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
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g04.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g04 applies"; else red "  g04 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g05.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g05 applies"; else red "  g05 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g06.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g06 applies"; else red "  g06 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g07.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g07 applies"; else red "  g07 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g08.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g08 applies"; else red "  g08 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g09.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g09 applies"; else red "  g09 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$BINDER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g10.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g10 applies"; else red "  g10 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$BINDER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g11.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g11 applies"; else red "  g11 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$BINDER" "$DRY/f.scaly"
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
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g29.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g29 applies"; else red "  g29 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g30.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g30 applies"; else red "  g30 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g31.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g31 applies"; else red "  g31 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g32.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g32 applies"; else red "  g32 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g33.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g33 applies"; else red "  g33 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g34.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g34 applies"; else red "  g34 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g35.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g35 applies"; else red "  g35 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g36.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g36 applies"; else red "  g36 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g37.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g37 applies"; else red "  g37 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g38.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g38 applies"; else red "  g38 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"

baseline

control "g01 the four arms reverted to their stop (the premise)"                     "$CHECKER" "$PATCHDIR/g01.py"
control "g02 checkGrammarConstructorTypeParameters removed"                          "$CHECKER" "$PATCHDIR/g02.py"
control "g03 checkGrammarConstructorTypeAnnotation removed"                          "$CHECKER" "$PATCHDIR/g03.py"
control "g04 the constructor's grammar && read as two independent checks"            "$CHECKER" "$PATCHDIR/g04.py"
control "g05 checkFunctionOrConstructorSymbol removed from the constructor"          "$CHECKER" "$PATCHDIR/g05.py"
control "g06 the constructor's body walk removed"                                    "$CHECKER" "$PATCHDIR/g06.py"
control "g07 the missing-body early return dropped"                                  "$CHECKER" "$PATCHDIR/g07.py"
control "g08 the class's member walk removed (the reachability premise)"             "$CHECKER" "$PATCHDIR/g08.py"
control "g09 the mark read as is_unported() — the first draft's mistake"             "$CHECKER" "$PATCHDIR/g09.py"
control "g10 error_range_for_node's Constructor arm removed"                         "$BINDER" "$PATCHDIR/g10.py"
control "g11 the constructor span's scan LOOP replaced by one scan"                  "$BINDER" "$PATCHDIR/g11.py"
control "g12 the scan loop's string-literal terminator dropped"                      "$BINDER" "$PATCHDIR/g12.py"
control "g13 checkGrammarModifiers removed from the static block"                    "$CHECKER" "$PATCHDIR/g13.py"
control "g14 the static block's child walk removed"                                  "$CHECKER" "$PATCHDIR/g14.py"
control "g15 checkGrammarAccessor's missing-body branch removed"                     "$CHECKER" "$PATCHDIR/g15.py"
control "g16 that branch's `abstract` term dropped"                                  "$CHECKER" "$PATCHDIR/g16.py"
control "g17 the abstract-with-implementation branch removed"                        "$CHECKER" "$PATCHDIR/g17.py"
control "g18 the ambient-container branch removed"                                   "$CHECKER" "$PATCHDIR/g18.py"
control "g19 the accessor's type-parameter branch removed"                           "$CHECKER" "$PATCHDIR/g19.py"
control "g20 doesAccessorHaveCorrectParameterCount's `this` arm dropped"             "$CHECKER" "$PATCHDIR/g20.py"
control "g21 the get/set message choice inverted"                                    "$CHECKER" "$PATCHDIR/g21.py"
control "g22 the setter's return-type branch removed"                                "$CHECKER" "$PATCHDIR/g22.py"
control "g23 GetSetAccessorValueParameter's `this` skip removed"                     "$CHECKER" "$PATCHDIR/g23.py"
control "g24 TS2378 written as the reference's four-term test (the first finding)"   "$CHECKER" "$PATCHDIR/g24.py"
control "g25 the `constructor`-named-accessor report removed"                        "$CHECKER" "$PATCHDIR/g25.py"
control "g26 that report's class-like term dropped"                                  "$CHECKER" "$PATCHDIR/g26.py"
control "g27 hasBindableName's guard inverted"                                       "$CHECKER" "$PATCHDIR/g27.py"
control "g28 the accessibility block removed"                                        "$CHECKER" "$PATCHDIR/g28.py"
control "g29 the once-bit removed"                                                   "$CHECKER" "$PATCHDIR/g29.py"
control "g30 the once-bit taken on the setter instead of the getter"                 "$CHECKER" "$PATCHDIR/g30.py"
control "g31 the abstract-mismatch test removed"                                     "$CHECKER" "$PATCHDIR/g31.py"
control "g32 the private half of the accessibility test dropped"                     "$CHECKER" "$PATCHDIR/g32.py"
control "g33 the getTypeOfAccessors stop removed"                                    "$CHECKER" "$PATCHDIR/g33.py"
control "g34 the accessor's body walk removed"                                       "$CHECKER" "$PATCHDIR/g34.py"
control "g35 SemicolonClassElement taken out of kind_has_no_check_arm"               "$CHECKER" "$PATCHDIR/g35.py"
control "g36 the two JSDoc kinds taken out of the same"                              "$CHECKER" "$PATCHDIR/g36.py"
control "g37 the MissingDeclaration table entry removed"                                     "$CHECKER" "$PATCHDIR/g37.py"

control "g38 the MissingDeclaration arm's checkDecorators call removed" "$CHECKER" "$PATCHDIR/g38.py"
echo
echo "################################################################"
bold "DONE — read every row against its PREDICTION, not against its colour."
