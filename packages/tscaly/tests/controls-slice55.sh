#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice55.sh — the slice-55 battery. Every row goes through
# tests/diagcheck.sh, for slices 49-54's reason: no yardstick counter can move,
# because checkVariableLikeDeclaration still stops at getSymbolOfDeclaration and a
# parameter reaches it like any other variable-like declaration. Checker matched
# is 10 / 109 before and after everything below.
#
# ★★★ THIS SLICE'S SUBJECT IS A FUNCTION WHOSE REPORTS ARE MOSTLY OUT OF REACH,
# AND THE BATTERY IS SPLIT ALONG THAT LINE. checkParameter has nine reports
# counting checkVariableLikeDeclaration's TS2371; the corpus reaches FOUR of them
# (TS2369, TS2371, TS2463, TS2680) because the only host whose parameters this
# walk enters is a FunctionDeclaration. Twelve rows break one of those four; five
# are UNGATED and each carries the number that makes it a measurement.
#
# ★★★ f13 IS THE ROW TO READ FIRST, AND IT IS UNGATED BY CONSTRUCTION. It restores
# slice 54's MERGED form of checkVariableLikeDeclaration's two
# `IsBindingPattern(name)` blocks — a transcription that was correct on the day it
# was written, because the statement between them was dead for a variable
# declaration. It is not dead for a parameter, so the merge silently DROPS a
# TS2371. diagcheck cannot see a missing diagnostic (its header says so), so the
# row is read off the falling `speaking on N units with M diagnostics` line
# instead of off the exit code. **A defect whose only symptom is a missing line is
# invisible to this instrument, and the number is the whole gate.**
#
# ★★★ THE INSTRUMENT IS ONE-DIRECTIONAL, WHICH DECIDES HOW EVERY ROW IS WRITTEN.
# diagcheck compares our C section as a SUBSEQUENCE of the reference's, so it
# cannot see a diagnostic we FAIL to report. Every gated row therefore breaks its
# claim in the direction that INVENTS a line, moves a span or changes a code.
#
# ★★ THE ROWS DO NOT GO THROUGH ctl.sh, for slice 48's reason: diagcheck reads the
# reference dumps run.sh produced, and a filtered run would rewrite part of that
# tree. Each row builds the package and the dumper into a scratch directory, points
# diagcheck's BIN at it, leaves tests/out alone, restores the source and PROVES the
# restore with `cmp`.
#
# Usage (nothing may edit the tree while this runs — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # the artifact tree, first
#   packages/tscaly/tests/controls-slice55.sh 2>&1 | tee /tmp/battery55.log

set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.0/tscaly/checker.scaly

LIBSCALY=${LIBSCALY:-/tmp/libscaly.a}
SCALYC=${SCALYC:-$REPO/scalyc/build/scalyc}

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  echo "Every row compares against the reference dumps that run produced."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl55)
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

build_diag_bin() {
  "$SCALYC" -c --no-prelude -o "$WORK/pkg.o" "$PKG/0.1.0/tscaly.scaly" > "$WORK/build.log" 2>&1 || return 1
  "$SCALYC" -c -o "$WORK/types.o" "$PKG/0.1.0/tscaly_types.scaly" >> "$WORK/build.log" 2>&1 || return 1
  clang -o "$WORK/tscaly_types" "$WORK/types.o" "$WORK/pkg.o" "$LIBSCALY" -lm >> "$WORK/build.log" 2>&1
}

DIAG_BASE=""
DIAG_LINES=""
DIAG_DIAGS=""

diag_baseline() {
  echo "################################################################"
  bold "DIAGNOSTICS BASELINE"
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
  echo "  BASELINE   $DIAG_BASE units consistent, $DIAG_LINES speaking, $DIAG_DIAGS diagnostics"
}

diag_control() {   # $1 = label, $2 = file, $3 = python patch file
  echo
  echo "################################################################"
  bold "CONTROL: $1"
  cp "$2" "$WORK/orig"
  if ! python3 "$3" "$2"; then
    red "the patch did not apply — the anchor moved. The row measures nothing."
    cp "$WORK/orig" "$2"
    return 1
  fi
  echo "  patched $2"
  if ! build_diag_bin; then
    red "the patched tree did not build — the row measures nothing:"
    tail -5 "$WORK/build.log" | sed 's/^/    /'
    cp "$WORK/orig" "$2"
    return 1
  fi
  BIN=$WORK/tscaly_types "$DIAGCHECK" > "$WORK/ctl.diag" 2>&1
  local rc=$?
  local consistent differing speaking
  consistent=$(sed -n 's/^  consistent  *\([0-9]*\)$/\1/p' "$WORK/ctl.diag")
  differing=$(sed -n 's/^  differing  *\([0-9]*\)$/\1/p' "$WORK/ctl.diag")
  speaking=$(sed -n 's/^  units we speak on  *\([0-9]*\).*$/\1/p' "$WORK/ctl.diag")
  local diags
  diags=$(sed -n 's/^.*(\([0-9]*\) diagnostics.*$/\1/p' "$WORK/ctl.diag")
  cp "$WORK/orig" "$2"
  if ! cmp -s "$WORK/orig" "$2"; then
    red "the source did NOT come back — every number below is suspect."
    return 1
  fi
  echo "  RESTORE VERIFIED   $2 byte-identical"
  echo
  if [ "$rc" != 0 ]; then
    green "RED $differing   (consistent $consistent, was $DIAG_BASE; speaking on $speaking/$diags, was $DIAG_LINES/$DIAG_DIAGS)"
  else
    red "UNGATED: every line we print is still a subsequence of the reference's."
    echo "  Speaking on $speaking units with $diags diagnostics, was $DIAG_LINES/$DIAG_DIAGS."
    echo "  Decide which of §3.5v's four kinds this is — and note that a control"
    echo "  which REMOVES a diagnostic, or narrows the port's COVERAGE, is ungated"
    echo "  here by construction (header)."
  fi
  return 0
}

diag_baseline

# ── f1: TS2369's guard is the PARAMETER-PROPERTY mask, not "any modifier" ─────

cat > "$WORK/f1.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ The block is entered on five flags — public/private/protected/readonly/
# override — and widening it to ModifierFlagsModifier makes every `declare`,
# `export`, `async` and decorated parameter a parameter property. The corpus has
# decorated parameters (checker_parameter_property_host's fourth line is one), so
# this INVENTS TS2369 where the reference has none.
old = """        if b.has_syntactic_modifier(node, ModifierFlagsParameterPropertyModifier)
"""
new = """        if b.has_syntactic_modifier(node, ModifierFlagsAll)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f1 TS2369's mask is the parameter-property one" "$CHECKER" "$WORK/f1.py"

# ── f2: TS2369's span is the NODE, not the name ──────────────────────────────

cat > "$WORK/f2.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★ A SPAN-ONLY row: the report one line below it IS on the name, so the two
# spans sit four lines apart in the same block and swapping them is the easiest
# mistake in the function. `readonly b: number` is 18 characters and its name is
# one, so the difference is wide enough for the subsequence test.
old = """            if in_constructor_implementation = false
                this.error_on_node(node, DiagA_parameter_property_is_only_allowed_in_a_constructor_implementation)
"""
new = """            if in_constructor_implementation = false
                this.error_on_node(name, DiagA_parameter_property_is_only_allowed_in_a_constructor_implementation)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f2 TS2369's span is the node" "$CHECKER" "$WORK/f2.py"

# ── f3: TS2369's CODE ────────────────────────────────────────────────────────

cat > "$WORK/f3.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★ A CODE-ONLY row, same span and same order: the cheapest demonstration that
# the dump compares the code, and the reason the eight reports of this function
# may be transcribed without their message ARGUMENTS.
old = """                this.error_on_node(node, DiagA_parameter_property_is_only_allowed_in_a_constructor_implementation)
"""
new = """                this.error_on_node(node, DiagX_constructor_cannot_be_used_as_a_parameter_property_name)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f3 TS2369's code" "$CHECKER" "$WORK/f3.py"

# ── f4: TS2369's constructor-with-a-body exemption ───────────────────────────

cat > "$WORK/f4.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ The exemption is `IsConstructorDeclaration(fn) && NodeIsPresent(fn.Body())`
# and no host this walk reaches satisfies it — so widening the KIND half to the
# one host it does reach turns the exemption on for every function declaration
# with a body, and the two live TS2369s become one. It is UNGATED in the exit
# code (it removes a line) and the falling count is the measurement: the row says
# how much of the corpus's TS2369 sits on a body-bearing function declaration.
old = """            var in_constructor_implementation false
            if fk = KindConstructor
"""
new = """            var in_constructor_implementation false
            if fk = KindFunctionDeclaration
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f4 TS2369's constructor exemption" "$CHECKER" "$WORK/f4.py"

# ── f5: TS2680's index test ──────────────────────────────────────────────────

cat > "$WORK/f5.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ `slices.Index(fn.Parameters(), node) != 0` — a `this` parameter must be
# FIRST. Inverting the comparison reports on the legal one and stays silent on
# the illegal one, which is exactly what checker_parameter_this_position.ts's two
# functions are for: the row invents a line on `ok` and the subsequence breaks.
old = """            if Checker.parameter_index_of(fn, node) <> 0
"""
new = """            if Checker.parameter_index_of(fn, node) = 0
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f5 TS2680's index test" "$CHECKER" "$WORK/f5.py"

# ── f6: TS2680's NAME ────────────────────────────────────────────────────────

cat > "$WORK/f6.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ The whole `this`/`new` block is entered on the parameter's TEXT. Pointing it
# at a one-letter name that the corpus is full of makes every second parameter
# named `a` report TS2680 — and it is also the row that says the text comparison
# is a comparison and not a null test.
old = """            if Checker.identifier_text_equals(name, "this", 4)
"""
new = """            if Checker.identifier_text_equals(name, "a", 1)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f6 TS2680's name" "$CHECKER" "$WORK/f6.py"

# ── f7: TS2680's span ────────────────────────────────────────────────────────

cat > "$WORK/f7.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★ A SPAN-ONLY row on the other live report of the `this` block: `this: any` is
# nine characters and `this` is four, so moving the span to the name is visible.
old = """                this.error_on_node(node, DiagA_0_parameter_must_be_the_first_parameter)
"""
new = """                this.error_on_node(name, DiagA_0_parameter_must_be_the_first_parameter)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f7 TS2680's span" "$CHECKER" "$WORK/f7.py"

# ── f8: TS2463 needs the `?` ─────────────────────────────────────────────────

cat > "$WORK/f8.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ Drop the optionality term and every destructuring parameter of every
# body-bearing function in the corpus reports TS2463 — by some way the loudest
# row here, and the one that says the conjunction's second term is read.
old = """            if Checker.is_optional_declaration(node)
"""
new = """            if true
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f8 TS2463 needs the question mark" "$CHECKER" "$WORK/f8.py"

# ── f9: TS2463 needs the BINDING PATTERN ─────────────────────────────────────

cat > "$WORK/f9.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ Drop the pattern term and every ordinary optional parameter reports — the
# diagnostic's subject is destructuring, and `function p(a?: any) {}` is the line
# that says so.
old = """                if AstNode.is_binding_pattern(name)
                {
                    if AstNode.body_of(fn) <> null
"""
new = """                if true
                {
                    if AstNode.body_of(fn) <> null
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f9 TS2463 needs the binding pattern" "$CHECKER" "$WORK/f9.py"

# ── f10: TS2463 needs the BODY ───────────────────────────────────────────────

cat > "$WORK/f10.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ Drop the body term and the OVERLOAD signature reports — which the
# diagnostic's own wording forbids (*in an implementation signature*).
# checker_parameter_optional_binding_pattern.ts's `r` is the whole population.
old = """                    if AstNode.body_of(fn) <> null
                        this.error_on_node(node, DiagA_binding_pattern_parameter_cannot_be_optional_in_an_implementation_signature)
"""
new = """                    if true
                        this.error_on_node(node, DiagA_binding_pattern_parameter_cannot_be_optional_in_an_implementation_signature)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f10 TS2463 needs the body" "$CHECKER" "$WORK/f10.py"

# ── f11: TS2463 needs NO INITIALIZER ─────────────────────────────────────────

cat > "$WORK/f11.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ The first term. `function s({a}?: any = {}) {}` already reports TS1015 from
# checkGrammarParameterList one slice back, so dropping this term makes our side
# print TWO diagnostics where the reference prints one — a negative half that is
# a LINE rather than a silence, which is the stronger kind.
old = """        if AstNode.initializer_of(node) = null
        {
            if Checker.is_optional_declaration(node)
"""
new = """        if true
        {
            if Checker.is_optional_declaration(node)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f11 TS2463 needs no initializer" "$CHECKER" "$WORK/f11.py"

# ── f12: TS2371 needs IsPartOfParameterDeclaration ───────────────────────────

cat > "$WORK/f12.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ The term slice 54 could only write as a comment. Drop it and every
# initialized VARIABLE declaration in the corpus reports TS2371 — a top-level
# `var x = 1` has no containing function at all, so `get_containing_function`
# answers null, `AstNode.body_of(null)` answers null and NodeIsMissing answers
# true. It is the loudest row in the battery and it is also the one that shows
# why the null direction of the guard had to be chosen deliberately.
old = """            if Binder.is_part_of_parameter_declaration(node)
"""
new = """            if true
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f12 TS2371 needs a parameter" "$CHECKER" "$WORK/f12.py"

# ── f13: the MERGE slice 54 was right to make and this slice had to undo ─────

cat > "$WORK/f13.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ EXPECTED UNGATED, AND THE FALLING NUMBER IS THE WHOLE ROW. This is the port
# slice 54 would have written if it had added TS2371 to its OWN structure: the two
# `IsBindingPattern(name)` blocks stay merged and the new statement goes after
# them, where the reference's second block ends. A binding-pattern parameter then
# takes the merged block and RETURNS before the report —
# checker_parameter_initializer_no_body.ts's `f` loses its diagnostic. diagcheck
# cannot see a missing line, so this row is read off `speaking on N units with M
# diagnostics` and nowhere else.
walk = """        if AstNode.is_binding_pattern(name)
            this.check_source_elements(AstNode.elements_of(name))
"""
assert s.count(walk) == 1, s.count(walk)
s = s.replace(walk, "")

i = s.index("        if initializer <> null\n        {\n            if Binder.is_part_of_parameter_declaration(node)")
j = s.index("        if AstNode.is_binding_pattern(name)\n        {\n            if this.is_in_ambient_or_type_node(node)", i)
ts2371 = s[i:j]
s = s[:i] + s[j:]

old2 = """        if AstNode.is_binding_pattern(name)
        {
            if this.is_in_ambient_or_type_node(node)
"""
new2 = """        if AstNode.is_binding_pattern(name)
        {
            this.check_source_elements(AstNode.elements_of(name))
            if this.is_in_ambient_or_type_node(node)
"""
assert s.count(old2) == 1, s.count(old2)
s = s.replace(old2, new2)

tail = """        this.record_unported("get-symbol-of-declaration", AstNode.kind_of(node))
"""
assert s.count(tail) == 1, s.count(tail)
open(p, "w").write(s.replace(tail, ts2371 + tail))
PY
diag_control "f13 the merged binding-pattern blocks" "$CHECKER" "$WORK/f13.py"

# ── f14: the rest-parameter hole ─────────────────────────────────────────────

cat > "$WORK/f14.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ EXPECTED UNGATED WITH A NUMBER, and the number is ZERO. The tag can never be
# first: two lines earlier checkVariableLikeDeclaration reports
# `get-symbol-of-declaration` for any parameter whose name is an identifier, and a
# rest parameter's name IS one. Removing the report therefore moves nothing at
# all — which is the claim checker_parameter_rest_type.ts makes in prose, checked
# here. ★A row that must not move is still a row: without it the shadowing is an
# argument, and with it the argument has a measurement.
old = """            if AstNode.is_binding_pattern(name) = false
                this.record_unported("get-type-of-symbol", KindParameter)
"""
new = """            if false
                this.record_unported("get-type-of-symbol", KindParameter)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f14 the rest-parameter hole" "$CHECKER" "$WORK/f14.py"

# ── f15: the reports are c.error, not grammarErrorOnNode ─────────────────────

cat > "$WORK/f15.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ EXPECTED UNGATED WITH A NUMBER, and the number is the point: routing every
# report of this arm through the GRAMMAR reporter adds the parse-diagnostic
# suppression the reference does not have here. It can only remove lines, so the
# exit code cannot see it — but the count says how many of our parameter
# diagnostics sit on a file that failed to parse, i.e. how much the distinction
# between the two reporters is worth on this corpus. ★If the number does not
# move, the distinction is UNMEASURED rather than unimportant, and the row says so
# instead of leaving a reader to assume the reporters are interchangeable.
old = """    procedure check_parameter(this, node: pointer[AstNode])
"""
assert s.count(old) == 1, s.count(old)
i = s.index(old)
j = s.index("\n    ; ast.GetContainingFunction", i)
body = s[i:j]
patched = body.replace("this.error_on_node(", "this.grammar_error_on_node(")
assert patched != body
open(p, "w").write(s[:i] + patched + s[j:])
PY
diag_control "f15 the reports are c.error" "$CHECKER" "$WORK/f15.py"

# ── f16: the whole arm, clipped ──────────────────────────────────────────────

cat > "$WORK/f16.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ THE COVERAGE CLAIM FROM THE OTHER SIDE, and it must print slice 54's
# baseline to the digit: with KindParameter off the ported list the arm is never
# entered, every parameter reports `check 170` again, and diagcheck returns to
# what §3.5cy measured. UNGATED by construction — the row is the difference
# between the two numbers.
old = """        if k = KindParameter
            return true
        false
    }
"""
new = """        false
    }
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f16 the whole parameter arm, clipped" "$CHECKER" "$WORK/f16.py"

echo
echo "################################################################"
bold "DONE — 16 rows"
echo "Eleven rows break a live report; f4/f13/f14/f15/f16 are UNGATED and each"
echo "carries its own number above. f13 is the one to read: a merge that was a"
echo "correct transcription until this slice, whose only symptom is a MISSING"
echo "line — which is the one failure mode diagcheck cannot see."
