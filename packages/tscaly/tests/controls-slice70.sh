#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice70.sh — the slice-70 battery: THE EXPRESSION DISPATCH.
# checkExpression / checkExpressionEx / checkExpressionCached, the forty-four-arm
# checkExpressionWorker, its four ported arms and its default, the two literal
# grammar checks, and the eleven call sites that used to be a stop.
#
# ★★★ THE PIN IS THE POSITIVE INSTRUMENT HERE AND DIAGCHECK IS THE NEGATIVE ONE,
# which is the reverse of slice 69 and the same shape as slices 66 and 67: what
# this slice produces is a WORK LIST — which arm each unit reaches — and not a
# diagnostic. So most rows below move a fixture's TAG, and the three rows that
# move diagcheck do it by INVENTING a line, which is the failure the subsequence
# relation exists to catch.
#
# ★★★ g08 AND g09 ARE THE ONLY WITNESS checkGrammarNumericLiteral HAS. Its report
# is a SUGGESTION (TS80008, CategorySuggestion) and GetDiagnostics does not read
# that list, so nothing in either instrument can see the function run. g08 routes
# the suggestion into the diagnostic list and diagcheck goes red on the invented
# lines — which proves the site runs AND that routing it there would be wrong.
# g09 adds the one mistake the function is written to avoid (asking the COOKED
# text for the fractional test) and the red comes back with a DIFFERENT number:
# the difference IS the reference's own comment about `1.1e21`.
#
# ★★ THREE ROWS ARE UNGATED BY CONSTRUCTION AND EACH SAYS SO WITH AN ARGUMENT:
# the OmittedExpression arm (nothing reaches it while checkArrayLiteral reports),
# the switch DEFAULT (every expression kind has a case, so no source shape falls
# through) and TS2407 in the for-in (asked after the left-hand side, which always
# reports first). A row that predicted its own silence is a measurement; one that
# did not is a hole.
#
# ★★★ ITERATE AT STAGE 1 AND CONFIRM AT STAGE 2 ONCE — slice 64's rule.
#
# Usage (nothing may edit the tree while this runs — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # stage 1, ~25 s
#   packages/tscaly/tests/controls-slice70.sh 2>&1 | tee /tmp/battery70.log
#   TSCALY_STAGE=2 packages/tscaly/tests/run.sh       # ~7 min, ONCE
#   packages/tscaly/tests/controls-slice70.sh 2>&1 | tee /tmp/battery70-s2.log

set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.0/tscaly/checker.scaly
FIX=$PKG/tests/fixtures

LIBSCALY=${LIBSCALY:-/tmp/libscaly.a}
SCALYC=${SCALYC:-$REPO/scalyc/build/scalyc}

# The fixtures the PIN reads — the twelve this slice wrote, plus the one slice 69
# left pointing at the same place. Every one of them lands on a DIFFERENT row of
# the new work list, which is what makes a diff of this block readable: a row that
# breaks one arm moves one line.
TAGFILES="
$FIX/checker_expression_null_statement.ts
$FIX/checker_expression_parenthesized_null.ts
$FIX/checker_expression_parenthesized_unported.ts
$FIX/checker_expression_throw_and_with_null.ts
$FIX/checker_expression_extends_null.ts
$FIX/checker_expression_numeric_grammar.ts
$FIX/checker_expression_bigint_grammar.ts
$FIX/checker_expression_switch_and_condition_null.ts
$FIX/checker_expression_switch_only.ts
$FIX/checker_expression_for_in_null.ts
$FIX/checker_expression_variable_initializer_null.ts
$FIX/checker_expression_parameter_completes.ts
$FIX/checker_annotated_keyword_type.ts
"

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  echo "Both instruments compare against the reference dumps that run produced."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl70)

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

build_diag_bin() {
  "$SCALYC" -c --no-prelude -o "$WORK/pkg.o" "$PKG/0.1.0/tscaly.scaly" > "$WORK/build.log" 2>&1 || return 1
  "$SCALYC" -c -o "$WORK/types.o" "$PKG/0.1.0/tscaly_types.scaly" >> "$WORK/build.log" 2>&1 || return 1
  clang -o "$WORK/tscaly_types" "$WORK/types.o" "$WORK/pkg.o" "$LIBSCALY" -lm >> "$WORK/build.log" 2>&1
}

tags_of() {
  local f
  for f in $TAGFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$("$WORK/tscaly_types" "$f" 2>/dev/null | grep '^UNPORTED ' | head -1 | cut -d' ' -f3-)"
  done
}

DIAG_BASE=""
DIAG_LINES=""
DIAG_DIAGS=""

baseline() {
  echo "################################################################"
  bold "BASELINE — both instruments"
  if ! build_diag_bin; then
    red "the unpatched tree did not build — every row below would be measuring that."
    sed 's/^/    /' "$WORK/build.log"
    exit 2
  fi
  BIN=$WORK/tscaly_types "$DIAGCHECK" > "$WORK/base.diag" 2>&1
  local rc=$?
  DIAG_BASE=$(sed -n 's/^  consistent  *\([0-9]*\)$/\1/p' "$WORK/base.diag")
  DIAG_LINES=$(sed -n 's/^  units we speak on  *\([0-9]*\).*$/\1/p' "$WORK/base.diag")
  DIAG_DIAGS=$(sed -n 's/^.*(\([0-9]*\) diagnostics.*$/\1/p' "$WORK/base.diag")
  sed -n '/^diagcheck/,$p' "$WORK/base.diag" | sed 's/^/  /'
  if [ "$rc" != 0 ]; then
    red "the diagnostics instrument is already red on the unpatched tree — fix that first."
    exit 2
  fi
  tags_of > "$WORK/base.tags"
  echo
  echo "  the PIN — the fixtures' unported tags on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.tags"
  if grep -q '	$' "$WORK/base.tags"; then
    red "a fixture answers NO tag — the pin would be comparing two empties."
    exit 2
  fi
  echo
  echo "  BASELINE   $DIAG_BASE units consistent, $DIAG_LINES speaking, $DIAG_DIAGS diagnostics"
}

control() {   # $1 = label, $2 = space-separated files, $3 = python patch file
  echo
  echo "################################################################"
  bold "CONTROL: $1"
  local files="$2" f i=0
  for f in $files; do cp "$f" "$WORK/orig.$i"; i=$((i+1)); done
  PATCHED_FILES="$files"
  if ! python3 "$3" $files; then
    red "the patch did not apply — the anchor moved. The row measures nothing."
    i=0; for f in $files; do cp "$WORK/orig.$i" "$f"; i=$((i+1)); done
    PATCHED_FILES=""
    return 1
  fi
  echo "  patched $files"
  if ! build_diag_bin; then
    red "the patched tree did not build — the row measures nothing:"
    tail -5 "$WORK/build.log" | sed 's/^/    /'
    i=0; for f in $files; do cp "$WORK/orig.$i" "$f"; i=$((i+1)); done
    PATCHED_FILES=""
    return 1
  fi
  BIN=$WORK/tscaly_types "$DIAGCHECK" > "$WORK/ctl.diag" 2>&1
  local rc=$?
  local consistent differing speaking diags
  consistent=$(sed -n 's/^  consistent  *\([0-9]*\)$/\1/p' "$WORK/ctl.diag")
  differing=$(sed -n 's/^  differing  *\([0-9]*\)$/\1/p' "$WORK/ctl.diag")
  speaking=$(sed -n 's/^  units we speak on  *\([0-9]*\).*$/\1/p' "$WORK/ctl.diag")
  diags=$(sed -n 's/^.*(\([0-9]*\) diagnostics.*$/\1/p' "$WORK/ctl.diag")
  tags_of > "$WORK/ctl.tags"
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
  if [ "$rc" != 0 ]; then
    green "diagcheck RED $differing   (consistent $consistent, was $DIAG_BASE; speaking on $speaking/$diags, was $DIAG_LINES/$DIAG_DIAGS)"
  else
    echo "  diagcheck ungated — speaking on $speaking units with $diags diagnostics, was $DIAG_LINES/$DIAG_DIAGS."
  fi
  if cmp -s "$WORK/base.tags" "$WORK/ctl.tags"; then
    echo "  pin       unmoved — all thirteen fixtures answer the same tag."
  else
    green "pin       RED"
    diff "$WORK/base.tags" "$WORK/ctl.tags" | sed 's/^/    /'
  fi
  if [ "$rc" = 0 ] && cmp -s "$WORK/base.tags" "$WORK/ctl.tags"; then
    if [ "$speaking" != "$DIAG_LINES" ] || [ "$diags" != "$DIAG_DIAGS" ]; then
      echo "  ungated on both, WITH A NUMBER: $DIAG_LINES/$DIAG_DIAGS -> $speaking/$diags."
    else
      red "UNGATED on BOTH INSTRUMENTS AND NOTHING MOVED AT ALL."
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
# ★★★ THE WHOLE DISPATCH REMOVED — the worker reports before its first arm.
# PREDICTION: the pin goes red on EVERY fixture. This is the premise row: it
# proves the twelve fixtures are measuring this function and not something the
# corpus does around it.
old = """        let k AstNode.kind_of(node)

        if k = KindIdentifier
        {
            this.record_unported("check-identifier", k)"""
new = """        let k AstNode.kind_of(node)
        this.record_unported("check-expression", k)
        if true
            return null

        if k = KindIdentifier
        {
            this.record_unported("check-identifier", k)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g02.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The NullKeyword arm turned back into a stop.
# PREDICTION: red on the seven fixtures whose expression is `null` — the two
# statement ones, the two parenthesised ones, extends-null, the two switch ones,
# the for-in and the variable initializer.
old = """        if k = KindNullKeyword
            return null_widening_type
"""
new = """        if k = KindNullKeyword
        {
            this.record_unported("null-widening-type", k)
            return null
        }
"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g03.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The OmittedExpression arm turned into a stop.
# PREDICTION: UNGATED, and the argument is the whole row: an omitted element is
# reached only through checkArrayLiteral (an array literal's elements) or through
# a binding pattern, which is a BindingElement and not an expression — and
# checkArrayLiteral reports. So the arm is correct and currently unreachable, and
# the reader that will make it observable is named: check-array-literal.
old = """        if k = KindOmittedExpression
            return undefined_widening_type
"""
new = """        if k = KindOmittedExpression
        {
            this.record_unported("undefined-widening-type", k)
            return null
        }
"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g04.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The ParenthesizedExpression arm turned into a stop.
# PREDICTION: red on both parenthesised fixtures — and on NOTHING else, which is
# the other half of the claim: the parenthesis is transparent, so no fixture
# without one moves.
old = """        if k = KindParenthesizedExpression
        {
            let inner AstNode.expression_of(node)
            if inner = null
                return error_type
            return this.check_expression_ex(inner as ref[AstNode], check_mode)
        }
"""
new = """        if k = KindParenthesizedExpression
        {
            this.record_unported("check-parenthesized-expression", k)
            return null
        }
"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g05.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The parenthesised arm made NON-RECURSIVE — it answers a type without asking its
# operand. PREDICTION: red on exactly ONE of the two parenthesised fixtures. The
# `(null)` one does not move, because both spellings answer a type and the unit
# completes either way; `(1 + 1)` does, because the recursion is the only thing
# that makes the inner BinaryExpression visible. ★A row that moves one of a pair
# is worth more than one that moves both: it separates *answers a type* from
# *answers the RIGHT type*.
old = """            let inner AstNode.expression_of(node)
            if inner = null
                return error_type
            return this.check_expression_ex(inner as ref[AstNode], check_mode)
"""
new = """            return error_type
"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g06.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The switch's DEFAULT turned into a stop.
# PREDICTION: UNGATED. Every expression kind the grammar can put in expression
# position has a `case`, so nothing in the corpus falls through — the default
# exists for a node handed to checkExpression that is not an expression at all,
# which is a shape no source text produces. The row is here to say that this was
# measured rather than assumed.
old = """        ; The switch's default. Not a hole: `return c.errorType` is the reference's
        ; answer for every kind above, printed `any`.
        error_type
"""
new = """        this.record_unported("check-expression-default", k)
        null
"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g07.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# checkGrammarNumericLiteral's fractional and scientific exits removed, so the
# suggestion fires on every literal above the threshold AND on the fractional
# ones. PREDICTION: UNGATED on both instruments and nothing moves at all — the
# report is a suggestion and no instrument here can see one. That is the argument
# for g08, and the reason this row is in the battery rather than left out.
old = """        if (AstNode.numeric_token_flags_of(node) & TokenFlagsScientific) <> 0
            return
"""
new = """        if false
            return
"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g08.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE SUGGESTION ROUTED INTO THE DIAGNOSTIC LIST.
# PREDICTION: diagcheck RED by INVENTION. It is the only witness that
# checkGrammarNumericLiteral runs at all, and it is simultaneously the proof that
# writing a suggestion into the C section is wrong: the reference reports nothing
# there for these literals.
old = """        this.record_suggestion(DiagNumeric_literals_with_absolute_values_equal_to_2_53_or_greater_are_too_large_to_be_represented_accurately_as_integers)
"""
new = """        this.error_on_node(node, DiagNumeric_literals_with_absolute_values_equal_to_2_53_or_greater_are_too_large_to_be_represented_accurately_as_integers)
"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g09.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ g08 PLUS THE ONE MISTAKE THE FUNCTION IS WRITTEN TO AVOID: the fractional
# test asks the COOKED text instead of the raw source.
# PREDICTION: diagcheck RED again, with FEWER invented lines than g08 — because
# `1100000000000000000000` cooks to `1.1e21`, whose dot makes the cooked test
# return early on the one literal the reference's own comment is about. The
# DIFFERENCE between the two numbers is the measurement; the colour is not.
old = """        let start b.skip_trivia_at(AstNode.pos_of(node))
        let stop AstNode.end_of(node)
        var i: int start
        while i < stop
        {
            if b.byte_at(i) = 0x2E
                return
            set i: i + 1
        }
"""
new = """        let cooked AstNode.literal_text_of(node)
        let cooked_len AstNode.literal_text_length_of(node)
        var i: int 0
        while i < cooked_len
        {
            if (*(cooked + i) as int) = 0x2E
                return
            set i: i + 1
        }
"""
assert s.count(old) == 1
s = s.replace(old, new, 1)
old2 = """        this.record_suggestion(DiagNumeric_literals_with_absolute_values_equal_to_2_53_or_greater_are_too_large_to_be_represented_accurately_as_integers)
"""
new2 = """        this.error_on_node(node, DiagNumeric_literals_with_absolute_values_equal_to_2_53_or_greater_are_too_large_to_be_represented_accurately_as_integers)
"""
assert s.count(old2) == 1
open(p, "w").write(s.replace(old2, new2, 1))
PY

cat > "$PATCHDIR/g10.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# checkGrammarBigIntLiteral's literal-type exemption dropped.
# PREDICTION: UNGATED — the report the exemption stands in front of is DEAD at
# this target, so removing the exemption changes nothing. The row's content is
# that the two facts are independent: g11 makes the report live and this one
# proves the exemption is not what keeps it quiet.
old = """        if literal_type
            return false
"""
new = """        if false
            return false
"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g11.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The target comparison widened so the BigInt report fires — and NOTHING else
# changes, because the option itself is untouched (every other languageVersion
# guard in this file still reads ES2025).
# PREDICTION: diagcheck RED by invention (TS2737 on `1n`), which is the whole
# proof that the function is wired to its report.
old = """        if language_version < ScriptTargetES2020
"""
new = """        if language_version <= ScriptTargetES2025
"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g12.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# checkTruthinessExpression put back as a stop.
# PREDICTION: pin red on the if/switch fixture — its row goes from
# check-truthiness-of-type back to a tag naming the call.
old = """        let t this.check_expression(node as ref[AstNode])
        if t = null
            return
        this.record_unported("check-truthiness-of-type", AstNode.kind_of(node as ref[AstNode]))
"""
new = """        this.record_unported("check-expression", AstNode.kind_of(node as ref[AstNode]))
"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g13.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The truthiness follow-up report dropped — the condition is checked and the
# remaining half is silently skipped. PREDICTION: pin red on the if/switch
# fixture, which then falls through to the switch's row. ★This is the shape
# §3.5ae warns about — a step that is silently not taken is invisible from both
# sides — so the row exists to show the report is load-bearing.
old = """        this.record_unported("check-truthiness-of-type", AstNode.kind_of(node as ref[AstNode]))
"""
new = """        if false
            this.record_unported("check-truthiness-of-type", AstNode.kind_of(node as ref[AstNode]))
"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g14.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The switch SUBJECT's call put back as a stop.
# PREDICTION: pin red on both switch fixtures. The clause's comparability row
# needs the subject's type, so breaking the subject takes the clause's row with
# it — which is what the `expression_type <> null` guard is for.
old = """        var expression_type: ref[Type]? null
        if subject <> null
            set expression_type: this.check_expression(subject as ref[AstNode])
"""
new = """        var expression_type: ref[Type]? null
        if subject <> null
            this.record_unported("check-expression", AstNode.kind_of(subject as ref[AstNode]))
"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g15.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The primary/secondary fork INVERTED in check_variable_like_declaration.
# PREDICTION: pin red on the variable fixture — a primary declaration then takes
# the secondary branch's row (get-widened-type-for-variable-like-declaration) and
# its initializer is never checked at all.
old = """            if value_declaration = node
                set is_primary_declaration: true
"""
new = """            if value_declaration = node
                set is_primary_declaration: false
"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g16.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The for-in SUBJECT's call put back as a stop.
# PREDICTION: pin red on the for-in fixture only.
old = """        var right_type: ref[Type]? null
        if subject <> null
            set right_type: this.check_expression(subject as ref[AstNode])
"""
new = """        var right_type: ref[Type]? null
        if subject <> null
            this.record_unported("check-expression", AstNode.kind_of(subject as ref[AstNode]))
"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g17.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The trailing block's PROPERTY early return removed, so a property declaration
# and a property signature run checkExportsOnMergedDeclarations and
# checkCollisionsForDeclarationName as well.
# PREDICTION: the reference does NOT run them for a property, so any line this
# produces is invented — diagcheck red if the corpus holds a property whose name
# collides, ungated with a number otherwise. Either way the number is the content.
old = """        if nk = KindPropertyDeclaration
            return
        if nk = KindPropertySignature
            return
"""
new = """        if false
            return
"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g18.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The trailing block skipped entirely — the shape the first draft of this slice
# had, where a stop in the fork returned instead of falling through.
# PREDICTION: ungated on the pin (no fixture's FIRST report is in that block) and
# a NUMBER on diagcheck: every collision diagnostic a variable-like declaration
# would have contributed is lost. ★A lost line is a subsequence of anything, so
# the colour cannot see it and only the count can — which is the whole reason
# diagcheck prints one.
old = """        let nk AstNode.kind_of(node)
        if nk = KindPropertyDeclaration
            return
"""
new = """        let nk AstNode.kind_of(node)
        if true
            return
        if nk = KindPropertyDeclaration
            return
"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g19.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# isConstEnumObjectType forced TRUE, i.e. the gate in checkExpressionEx made to
# fire. PREDICTION: pin red on every fixture whose expression answers a type —
# the proof that the gate is on the path rather than beside it, which is what
# "provably inert" needs in order to mean anything.
old = """    function is_const_enum_object_type(t: ref[Type]) returns bool
    {
        if (t.object_flags & ObjectFlagsAnonymous) = 0
            return false
"""
new = """    function is_const_enum_object_type(t: ref[Type]) returns bool
    {
        if true
            return true
        if (t.object_flags & ObjectFlagsAnonymous) = 0
            return false
"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g20.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The generic-call-signature gate's mode test INVERTED, so it fires under
# CheckModeNormal. PREDICTION: pin red on every fixture whose expression answers
# a type. Together with g19 it says the two inert gates are both reached, which is
# the difference between a step that cannot fire and a step that was left out.
old = """        if (check_mode & (CheckModeInferential | CheckModeSkipGenericFunctions)) <> 0
"""
new = """        if (check_mode & (CheckModeInferential | CheckModeSkipGenericFunctions)) = 0
"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g21.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# getBaseConstructorTypeOfClass's call put back as a stop.
# PREDICTION: pin red on the extends-null fixture only. ★It is the row that shows
# `class C extends null {}` is a REACHED shape and not a comment: without the call
# the unit cannot get to is-constructor-type at all.
old = """        let base_ctor this.check_expression(base_expr as ref[AstNode])
        this.pop_type_resolution()
        if base_ctor = null
            return null
"""
new = """        this.pop_type_resolution()
        this.record_unported("check-expression", KindExpressionWithTypeArguments)
        if true
            return null
"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

# ── the dry run ─────────────────────────────────────────────────────────────
DRY=$WORK/dry
mkdir -p "$DRY"
dry_ok=1
dry_one() {
  local id=$1 f=$2
  cp "$f" "$DRY/copy"
  if python3 "$PATCHDIR/$id.py" "$DRY/copy" 2> "$DRY/err"; then
    printf '  %s  ok   (%s)\n' "$id" "$(basename "$f")"
  else
    red "  $id  DID NOT APPLY — $(tail -1 "$DRY/err")"
    dry_ok=0
  fi
}
echo "################################################################"
bold "DRY RUN — every patch against a copy, before a single build"
for id in g01 g02 g03 g04 g05 g06 g07 g08 g09 g10 g11 g12 g13 g14 g15 g16 g17 g18 g19 g20 g21; do
  dry_one "$id" "$CHECKER"
done
if [ "$dry_ok" != 1 ]; then
  red "at least one anchor is wrong. Fix them before spending the battery."
  exit 2
fi

baseline

control "g01 the whole dispatch removed"                           "$CHECKER" "$PATCHDIR/g01.py"
control "g02 the NullKeyword arm turned into a stop"               "$CHECKER" "$PATCHDIR/g02.py"
control "g03 the OmittedExpression arm turned into a stop"         "$CHECKER" "$PATCHDIR/g03.py"
control "g04 the parenthesised arm turned into a stop"             "$CHECKER" "$PATCHDIR/g04.py"
control "g05 the parenthesised arm made non-recursive"             "$CHECKER" "$PATCHDIR/g05.py"
control "g06 the switch DEFAULT turned into a stop"                "$CHECKER" "$PATCHDIR/g06.py"
control "g07 the numeric grammar check's two early exits removed"  "$CHECKER" "$PATCHDIR/g07.py"
control "g08 the SUGGESTION routed into the diagnostic list"       "$CHECKER" "$PATCHDIR/g08.py"
control "g09 g08 plus the fractional test on the COOKED text"      "$CHECKER" "$PATCHDIR/g09.py"
control "g10 the bigint literal-type exemption dropped"            "$CHECKER" "$PATCHDIR/g10.py"
control "g11 the bigint target comparison widened so it fires"     "$CHECKER" "$PATCHDIR/g11.py"
control "g12 checkTruthinessExpression put back as a stop"         "$CHECKER" "$PATCHDIR/g12.py"
control "g13 the truthiness follow-up report dropped"              "$CHECKER" "$PATCHDIR/g13.py"
control "g14 the switch subject's call put back as a stop"         "$CHECKER" "$PATCHDIR/g14.py"
control "g15 the primary/secondary fork inverted"                  "$CHECKER" "$PATCHDIR/g15.py"
control "g16 the for-in subject's call put back as a stop"         "$CHECKER" "$PATCHDIR/g16.py"
control "g17 the trailing block's property early return removed"   "$CHECKER" "$PATCHDIR/g17.py"
control "g18 the trailing block skipped entirely"                  "$CHECKER" "$PATCHDIR/g18.py"
control "g19 isConstEnumObjectType forced true"                    "$CHECKER" "$PATCHDIR/g19.py"
control "g20 the generic-call-signature gate's mode test inverted" "$CHECKER" "$PATCHDIR/g20.py"
control "g21 the base-constructor call put back as a stop"         "$CHECKER" "$PATCHDIR/g21.py"

echo
echo "################################################################"
bold "RESTORED — checker.scaly, byte-identical"
git -C "$REPO" diff --stat -- "$CHECKER" | tail -3
