#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice51.sh — the slice-51 battery. Every row goes through
# tests/diagcheck.sh, for slices 49 and 50's reason: no yardstick counter can
# move, because checkClassLikeDeclaration always ends in a report
# (checkCollisionsForDeclarationName), so not one class unit can be claimed.
# Checker matched is 10 / 109 before and after everything below.
#
# ★★★ THIS BATTERY IS THE FIRST ONE THAT AIMS AT A LIST'S RANGE, and that is the
# whole reason it has eighteen rows for two functions. §3.5bq built the side table
# with a measurement and no test, because no yardstick dumps a list's extent in
# either direction; slice 51's three span computations are its first readers, so
# f1 through f7 are the first controls in this package that can be red about a
# row of that table.
#
# ★★★ THE INSTRUMENT IS ONE-DIRECTIONAL, WHICH DECIDES HOW EVERY ROW IS WRITTEN.
# diagcheck compares our C section as a SUBSEQUENCE of the reference's, so it
# cannot see a diagnostic we FAIL to report. Fifteen of the twenty rows below
# therefore break their claim in the direction that INVENTS a line, moves a span
# or changes a code. Two of the rest (f16, f18) are COVERAGE claims — they can only
# be broken by making the port measure LESS — and f17's only observable is an
# UNPORTED TAG, which no counter here carries; all three are read off the numbers
# they name instead (§3.5v's fourth kind).
#
# ★★★ AND TWO ROWS CAME BACK UNGATED WITH A PROOF INSTEAD OF A GAP — f6 and f15,
# both of them SPAN rows, both of them written expecting RED. An EMPTY list's range
# is a POINT, so the empty-heritage report's two candidate positions are the same
# number; and GetErrorRangeForNode falls back to the token at the node's pos when
# there is no NAME, which is precisely the condition the missing-name report fires
# under, so its two candidate REPORTERS are the same function. Neither is missing
# coverage and neither can be fixed by a fixture. f19 and f20 gate those two
# reports on their CODE instead, which is what is left to gate. ★The lesson is the
# cheap one: for an ungated row the argument is sometimes easier to MEASURE than to
# derive — f15's fixture carried the OPPOSITE claim in a comment until this ran.
#
# ★★ THE ROWS DO NOT GO THROUGH ctl.sh, for slice 48's reason: diagcheck reads the
# reference dumps run.sh produced, and a filtered run would rewrite part of that
# tree. Each row builds the package and the dumper into a scratch directory,
# points diagcheck's BIN at it, leaves tests/out alone, restores the source and
# PROVES the restore with `cmp`.
#
# ★ f18 patches parser.scaly rather than checker.scaly — it is the row for the
# THREADING, i.e. for the table travelling on the SourceFile at all, and the only
# place that can be broken is where the parser hands it over.
#
# Usage (nothing may edit the tree while this runs — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # the artifact tree, first
#   packages/tscaly/tests/controls-slice51.sh 2>&1 | tee /tmp/battery51.log

set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.0/tscaly/checker.scaly
PARSER=$PKG/0.1.0/tscaly/parser.scaly

. packages/tscaly/tests/toolchain.sh || exit 2

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  echo "Every row compares against the reference dumps that run produced."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl51)
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

# ── f1: the empty type-parameter list's START is one character before it ──────

cat > "$WORK/f1.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ `- len("<")`. The list's range begins INSIDE the bracket, so the report has
# to step back over it; without the step the span starts one character late and
# the diagnostic is at a position the reference does not have.
old = """        let start lpos - 1
        let stop b.skip_trivia_at(lend) + 1
        this.grammar_error_at_pos(start, stop - start, DiagType_parameter_list_cannot_be_empty)
"""
new = """        let start lpos
        let stop b.skip_trivia_at(lend) + 1
        this.grammar_error_at_pos(start, stop - start, DiagType_parameter_list_cannot_be_empty)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f1 the empty type-parameter list reports from before the '<'" "$CHECKER" "$WORK/f1.py"

# ── f2: the TRIVIA SKIP between the list's end and the '>' ───────────────────

cat > "$WORK/f2.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ THE SHARPEST ROW IN THIS BATTERY AND IT REDDENS ONE UNIT. A bracketed
# list's END is the FULL START of the closing bracket, so with a comment in
# between it points at the comment and not at the `>`. Only
# checker_class_empty_type_parameter_list.ts's second class can tell the two
# spellings apart — every other empty list in the corpus has the bracket right
# there, where skipping trivia is the identity.
old = """        let stop b.skip_trivia_at(lend) + 1
        this.grammar_error_at_pos(start, stop - start, DiagType_parameter_list_cannot_be_empty)
"""
new = """        let stop lend + 1
        this.grammar_error_at_pos(start, stop - start, DiagType_parameter_list_cannot_be_empty)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f2 the empty type-parameter list's end skips trivia before the '>'" "$CHECKER" "$WORK/f2.py"

# ── f3: the empty-list test is EXISTS-AND-EMPTY, not merely EXISTS ───────────

cat > "$WORK/f3.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ THE LOUDEST INVENTION THIS SLICE CAN MAKE. Drop the emptiness test and every
# generic class in the corpus reports TS1098 — which is also the row that proves
# the check is reached at all, on thousands of units rather than on a fixture.
old = """        if type_parameters = null
            return false
        if AstNode.list_count(type_parameters) <> 0
            return false
"""
new = """        if type_parameters = null
            return false
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f3 an empty type-parameter LIST is the condition, not a present one" "$CHECKER" "$WORK/f3.py"

# ── f4: HasTrailingComma is DERIVED, and the derivation is the check ─────────

cat > "$WORK/f4.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ `last.End() < list.End()` is the whole of HasTrailingComma upstream, and it
# is the one place in this slice where a row of the side table is compared against
# a NODE. Remove the comparison and every heritage clause in the corpus invents a
# TS1009 — the difference between the two ends IS the comma.
old = """        if AstNode.end_of(AstNode.child_in_list(list, n - 1)) >= lend
            return false
        this.grammar_error_at_pos(lend - 1, 1, code)
"""
new = """        this.grammar_error_at_pos(lend - 1, 1, code)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f4 a trailing comma is the gap between the last element and the list's end" "$CHECKER" "$WORK/f4.py"

# ── f5: the trailing comma's span is the COMMA, at the list's end minus one ──

cat > "$WORK/f5.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★ `list.End()-len(",")`, one character wide. Reporting AT the end instead is the
# same code at the wrong place, which is the failure a subsequence test is
# sharpest on.
old = """        this.grammar_error_at_pos(lend - 1, 1, code)
"""
new = """        this.grammar_error_at_pos(lend, 1, code)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f5 the trailing comma is reported AT the comma" "$CHECKER" "$WORK/f5.py"

# ── f6: the empty heritage list reports at the list's START, zero-width ──────

cat > "$WORK/f6.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ UNGATED, AND WHAT IT PROVES IS THAT TWO SPELLINGS COINCIDE — §3.5v's fourth
# kind and slice 50's f11 shape, arrived at by RUNNING the row rather than by
# arguing it. An EMPTY delimited list's range is a POINT: `pos` is taken before the
# first element and `end` after the last, and with no elements between them nothing
# moves the scanner, so `lpos == lend` for every list this report can fire on.
# Reporting at the end is the same answer and no corpus can separate the two. The
# reference's spelling stays because it WOULD separate for any non-empty list; the
# report itself is gated by f19, on its code.
old = """            return this.grammar_error_at_pos(lpos, 0, DiagX_0_list_cannot_be_empty)
"""
new = """            return this.grammar_error_at_pos(lend, 0, DiagX_0_list_cannot_be_empty)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f6 the empty heritage list reports at the list's own start" "$CHECKER" "$WORK/f6.py"

# ── f7: the empty type-ARGUMENT list is a check of its own ───────────────────

cat > "$WORK/f7.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★ checkGrammarForAtLeastOneTypeArgument carries a different message from the
# type-PARAMETER twin and the same arithmetic. Swap the code and every `extends
# A<>` answers TS1098 where the reference answers TS1099.
old = """        this.grammar_error_at_pos(start, stop - start, DiagType_argument_list_cannot_be_empty)
"""
new = """        this.grammar_error_at_pos(start, stop - start, DiagType_parameter_list_cannot_be_empty)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f7 an empty type-ARGUMENT list has its own message" "$CHECKER" "$WORK/f7.py"

# ── f8: `extends` already seen versus must-precede-implements ────────────────

cat > "$WORK/f8.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★ Two reports at the same span with two codes, chosen by WHICH clause was seen
# before. Swapping them is invisible to any test that does not compare codes.
old = """                if seen_extends_clause
                    return this.grammar_error_on_first_token(clause, DiagX_extends_clause_already_seen)
                if seen_implements_clause
                    return this.grammar_error_on_first_token(clause, DiagX_extends_clause_must_precede_implements_clause)
"""
new = """                if seen_extends_clause
                    return this.grammar_error_on_first_token(clause, DiagX_extends_clause_must_precede_implements_clause)
                if seen_implements_clause
                    return this.grammar_error_on_first_token(clause, DiagX_extends_clause_already_seen)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f8 the two extends-clause reports are chosen by which clause came first" "$CHECKER" "$WORK/f8.py"

# ── f9: a class may extend ONE class, and one is not zero ────────────────────

cat > "$WORK/f9.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ `len(typeNodes) > 1`. Widen it to `> 0` and every class with an extends
# clause in the corpus reports TS1174 — and it would report it at
# `typeNodes[1]`, which for a single-type clause does not exist, so this row also
# exercises child_in_list's null answer rather than a crash.
old = """                if AstNode.list_count(types) > 1
"""
new = """                if AstNode.list_count(types) > 0
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f9 only a SECOND extends type is Classes-can-only-extend-a-single-class" "$CHECKER" "$WORK/f9.py"

# ── f10: and it is reported at the SECOND type ───────────────────────────────

cat > "$WORK/f10.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★ The report names the type that is one too many, not the clause and not the
# first type. Same code, different span.
old = """                    return this.grammar_error_on_first_token(AstNode.child_in_list(types, 1), DiagClasses_can_only_extend_a_single_class)
"""
new = """                    return this.grammar_error_on_first_token(AstNode.child_in_list(types, 0), DiagClasses_can_only_extend_a_single_class)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f10 the extra extends type is where the report lands" "$CHECKER" "$WORK/f10.py"

# ── f11: `implements` already seen is reported at the clause's FIRST TOKEN ───

cat > "$WORK/f11.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★ grammarErrorOnFirstToken is a SCAN at the clause's pos; grammarErrorOnNode is
# the error RANGE. For a heritage clause the two differ, so this is a span row
# rather than a code row.
old = """                if seen_implements_clause
                    return this.grammar_error_on_first_token(clause, DiagX_implements_clause_already_seen)
"""
new = """                if seen_implements_clause
                    return this.grammar_error_on_node(clause, DiagX_implements_clause_already_seen)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f11 a repeated implements clause reports at its first TOKEN" "$CHECKER" "$WORK/f11.py"

# ── f12: the import-keyword branch is about the `import` keyword ─────────────

cat > "$WORK/f12.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ Drop the keyword test and every heritage type carrying type arguments — a
# large part of the conformance corpus — invents TS1326. It is the row that proves
# checkGrammarExpressionWithTypeArguments runs on every type of every clause.
old = """            if Checker.kind_or_unknown(AstNode.expression_of(node)) = KindImportKeyword
            {
                if AstNode.type_arguments_of(node) <> null
                    return this.grammar_error_on_node(node, DiagThis_use_of_import_is_invalid_import_calls_can_be_written_but_they_must_have_parentheses_and_cannot_have_type_arguments)
            }
"""
new = """            if AstNode.type_arguments_of(node) <> null
                return this.grammar_error_on_node(node, DiagThis_use_of_import_is_invalid_import_calls_can_be_written_but_they_must_have_parentheses_and_cannot_have_type_arguments)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f12 the invalid-import report needs the import KEYWORD" "$CHECKER" "$WORK/f12.py"

# ── f13: the modifier check short-circuits the heritage walk ─────────────────

cat > "$WORK/f13.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ `!c.checkGrammarModifiers(node) && …`. Run the walk anyway and a class with
# both a modifier error and two extends types answers TS1174 as well, which the
# reference does not.
old = """        if this.check_grammar_modifiers(node)
            return false
        let clauses AstNode.class_heritage_clauses_of(node)
"""
new = """        this.check_grammar_modifiers(node)
        let clauses AstNode.class_heritage_clauses_of(node)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f13 a modifier error suppresses the heritage-clause walk" "$CHECKER" "$WORK/f13.py"

# ── f14: the missing-name report needs the DEFAULT modifier to be absent ────

cat > "$WORK/f14.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ `export default class {}` is the legal anonymous class. Drop the modifier
# half of the condition and it reports TS1211 too — one unit, and the only one in
# the corpus that can tell the two halves apart.
old = """            if b.has_syntactic_modifier(node, ModifierFlagsDefault) = false
                this.grammar_error_on_first_token(node, DiagA_class_declaration_without_the_default_modifier_must_have_a_name)
"""
new = """            this.grammar_error_on_first_token(node, DiagA_class_declaration_without_the_default_modifier_must_have_a_name)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f14 an anonymous class with the default modifier is legal" "$CHECKER" "$WORK/f14.py"

# ── f15: the missing-name report's span is the first TOKEN ───────────────────

cat > "$WORK/f15.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ UNGATED, AND THE REASON IS THE REPORT'S OWN CONDITION — the second row of
# this battery that had to be run to be known, and the more instructive of the two.
# What separates grammarErrorOnFirstToken from grammarErrorOnNode is that the error
# RANGE finds a declaration's NAME and reports there; with no name, GetErrorRangeForNode
# falls back to the token at the node's pos, which is exactly what the first-token
# form computes. This report fires ONLY when the class has no name. So the two
# reporters are provably the same answer here and no corpus can separate them —
# and the fixture's comment used to claim the opposite, which is why the row was
# written expecting RED. The reference's spelling stays because it separates for
# every OTHER report; the code is gated by f20.
old = """                this.grammar_error_on_first_token(node, DiagA_class_declaration_without_the_default_modifier_must_have_a_name)
"""
new = """                this.grammar_error_on_node(node, DiagA_class_declaration_without_the_default_modifier_must_have_a_name)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f15 the missing-name report is at the class's first token" "$CHECKER" "$WORK/f15.py"

# ── f16: checkGrammarHeritageClause's result is DISCARDED ────────────────────

cat > "$WORK/f16.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ UNGATED BY CONSTRUCTION, and read off the counters. The reference writes
# this call as a statement of its own, so a report inside one clause does not stop
# the walk over the rest — checker_class_heritage_both_clauses.ts is one class with
# two diagnostics. Folding it into the `||` chain REMOVES the second, and a missing
# line is a subsequence of anything (header). The number is the gate: the
# diagnostics count must fall.
old = """            this.check_grammar_heritage_clause(clause)
"""
new = """            if this.check_grammar_heritage_clause(clause)
                return true
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f16 the heritage-clause check's result is discarded, so the walk continues" "$CHECKER" "$WORK/f16.py"

# ── f17: checkDecorators' guard is what lets a plain class continue ──────────

cat > "$WORK/f17.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ UNGATED, AND ITS ARGUMENT IS THAT THE OBSERVABLE IS A TAG. Dropping the
# decorator test makes every class report `check-decorators` instead of
# `check-collisions-for-declaration-name` — a change in the UNPORTED column, which
# diagcheck cannot see and the two coverage counters cannot either, because the
# grammar diagnostics are emitted BEFORE this call. The instrument that gates it is
# tests/triage.py's histogram: 29 units carry the tag on stage 2 and 3 298 do not,
# and this patch makes it 3 327 / 0. Kept here rather than dropped so the reader
# knows which instrument to ask.
old = """        if b.has_syntactic_modifier(node, ModifierFlagsDecorator) = false
            return
"""
new = ""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f17 checkDecorators returns for a class that has no decorator" "$CHECKER" "$WORK/f17.py"

# ── f18: the side table travels on the SourceFile ───────────────────────────

cat > "$WORK/f18.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ UNGATED BY CONSTRUCTION, and it is the row for the SLICE'S OWN MECHANISM:
# the list-range table reaching the checker at all. Hand `null` over instead and
# every lookup misses, so all three span computations report `list-range` as
# unported and say NOTHING — which a subsequence test accepts. The gate is the
# counters: 36 units / 66 diagnostics becomes 31 / 53, and the `list-range` tag
# appears in the histogram where the whole corpus otherwise has none of it.
old = "this.js_diagnostics_for_file(), list_ranges))"
new = "this.js_diagnostics_for_file(), null))"
assert s.count(old) == 3, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f18 the list-range table is handed over on the SourceFile" "$PARSER" "$WORK/f18.py"


# ── f19: the empty heritage list has its own message ─────────────────────────

cat > "$WORK/f19.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★ f6 showed that this report's POSITION cannot be gated — an empty list's range
# is a point — so what is left to gate is its CODE, and that is this row. It is
# also the one report of the slice whose message upstream takes an ARGUMENT this
# port does not compute, so if a later yardstick ever compares TEXT, this is the
# row that turns red first.
old = """            return this.grammar_error_at_pos(lpos, 0, DiagX_0_list_cannot_be_empty)
"""
new = """            return this.grammar_error_at_pos(lpos, 0, DiagType_parameter_list_cannot_be_empty)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f19 the empty heritage list has its own message" "$CHECKER" "$WORK/f19.py"

# ── f20: the missing-name report has its own message ────────────────────────

cat > "$WORK/f20.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★ f15's other half, for f19's reason: the SPAN of this report is not separable
# from the error range's, so the code is what is left to gate.
old = """                this.grammar_error_on_first_token(node, DiagA_class_declaration_without_the_default_modifier_must_have_a_name)
"""
new = """                this.grammar_error_on_first_token(node, DiagType_parameter_list_cannot_be_empty)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f20 the missing-name report has its own message" "$CHECKER" "$WORK/f20.py"

echo
echo "################################################################"
bold "BATTERY 51 COMPLETE"
echo "Twenty rows. Fifteen must be RED. Five are UNGATED and each says why: f6 and"
echo "f15 with a PROOF that two spellings coincide (an empty list's range is a"
echo "point; a nameless declaration's error range IS its first token), f16 and f18"
echo "read off the two coverage counters, and f17 off tests/triage.py's histogram,"
echo "which is the only instrument that can see an UNPORTED tag."
