#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice64.sh — the slice-64 battery: the LOOP, RETURN and SWITCH arms,
# i.e. the ForStatement / ForInStatement / ForOfStatement / ReturnStatement /
# SwitchStatement cases of checkSourceElement and the six reference functions
# behind them (checkForStatement, checkForInStatement, checkForOfStatement,
# checkGrammarForInOrForOfStatement, checkReturnStatement, checkSwitchStatement),
# plus the two things they needed elsewhere: statements_of's missing clause arms
# and error_range_for_node's DefaultClause arm.
#
# ★★★ THIRTY-ONE ROWS, AND THE BATTERY'S OWN SHAPE IS THE OPTION DIMENSION. Slice
# 63 deferred these three loop arms because checkGrammarForInOrForOfStatement reads
# `c.moduleKind`, `c.languageVersion` and the file's implied node format — and seven
# rows here (g10..g16) are about nothing else. They matter because the dimension
# COLLAPSES under this harness: of its three diagnostics only TS1431 survives, and a
# collapse asserted is worth nothing. Each of the two dead ones is brought to life by
# MOVING THE FIELD the harness fixes, which is the only way to tell *unreachable*
# from *not written*.
#
# ★★★ THE PAIR THAT CARRIES THE MOST IS g15/g16, and it is about a predicate that
# LOOKS like another one. isCommonJSContainingModuleKind admits CommonJS = 1 and the
# switch's Node label does not, so the two differ on exactly one member — and with
# module_kind moved to CommonJS the correct predicate reports TS1432 (g15, RED) while
# the tempting one reports nothing (g16, silent). **Two ranges one member apart with
# two different answers are two functions**, and no fixture can show that: only a
# premise on the field can.
#
# ★★ TWO INSTRUMENTS, as in slices 56–63. diagcheck gates the reports; a PIN over the
# ten fixtures' unported TAGS gates the arms and the wirings that produce no
# diagnostic at all.
#
# ★ THREE FILES ARE PATCHED — checker.scaly, ast.scaly and binder.scaly — because two
# of this slice's changes are not in the checker: the clause arms of statements_of
# (g28) and the DefaultClause arm of error_range_for_node (g27), which is the first
# instalment of a deferral slice 45 wrote and dated. Every patch is dry-run against a
# copy of the tree before a single build is spent (slice 57), and the restore is
# proven with `cmp` and survives a kill (slice 58).
#
# ★★★ THIS BATTERY IS MEASURED ON THE STAGE-2 TREE, which every battery before it was
# not, and two of its rows are the reason. g03 and g17 were both UNGATED against the
# whole 17 950-unit corpus and are gated by one fixture line each — a verdict that can
# only be read as *the corpus does not hold this input* if the corpus was actually
# asked. It costs the run: 7 min for the tree plus ~25 min for the thirty-one rows,
# against ~90 s at stage 1. Run it at stage 1 for a quick regression and at stage 2
# before believing an UNGATED verdict.
#
# Usage (nothing may edit the tree while this runs — §3.5y):
#
#   TSCALY_STAGE=2 packages/tscaly/tests/run.sh       # the artifact tree, first
#   packages/tscaly/tests/controls-slice64.sh 2>&1 | tee /tmp/battery64.log

set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.0/tscaly/checker.scaly
AST=$PKG/0.1.0/tscaly/ast.scaly
BINDER=$PKG/0.1.0/tscaly/binder.scaly
FIX=$PKG/tests/fixtures

LIBSCALY=${LIBSCALY:-/tmp/libscaly.a}
SCALYC=${SCALYC:-$REPO/scalyc/build/scalyc}

# The fixtures the PIN reads — all eleven of this slice's.
TAGFILES="
$FIX/checker_statement_for_grammar.ts
$FIX/checker_statement_for_head.ts
$FIX/checker_statement_for_in_destructuring.ts
$FIX/checker_statement_for_of_async.ts
$FIX/checker_statement_for_await_top_level.ts
$FIX/checker_statement_for_await_unreachable.ts
$FIX/checker_statement_return_outside_function.ts
$FIX/checker_statement_switch_duplicate_default.ts
$FIX/checker_statement_loop_body_walk.ts
$FIX/checker_statement_ambient_loops.d.ts
$FIX/checker_statement_namespace_export.d.ts
"

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  echo "Both instruments compare against the reference dumps that run produced."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl64)

PATCHED_FILE=""
PATCHED_ORIG=""
cleanup() {
  if [ -n "$PATCHED_FILE" ] && [ -f "$PATCHED_ORIG" ]; then
    cp "$PATCHED_ORIG" "$PATCHED_FILE"
    red "INTERRUPTED — $PATCHED_FILE restored from the row that was running."
  fi
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

control() {   # $1 = label, $2 = space-separated files, $3 = python patch file, $4 = optional tag file
  echo
  echo "################################################################"
  bold "CONTROL: $1"
  local files="$2" f i=0
  for f in $files; do cp "$f" "$WORK/orig.$i"; i=$((i+1)); done
  PATCHED_ORIG=$WORK/orig.0
  PATCHED_FILE=$(echo "$files" | awk '{print $1}')
  if ! python3 "$3" $files; then
    red "the patch did not apply — the anchor moved. The row measures nothing."
    i=0; for f in $files; do cp "$WORK/orig.$i" "$f"; i=$((i+1)); done
    PATCHED_FILE=""
    return 1
  fi
  echo "  patched $files"
  if ! build_diag_bin; then
    red "the patched tree did not build — the row measures nothing:"
    tail -5 "$WORK/build.log" | sed 's/^/    /'
    i=0; for f in $files; do cp "$WORK/orig.$i" "$f"; i=$((i+1)); done
    PATCHED_FILE=""
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
  PATCHED_FILE=""
  echo "  RESTORE VERIFIED   $files byte-identical"
  echo
  if [ "$rc" != 0 ]; then
    green "diagcheck RED $differing   (consistent $consistent, was $DIAG_BASE; speaking on $speaking/$diags, was $DIAG_LINES/$DIAG_DIAGS)"
  else
    echo "  diagcheck ungated — speaking on $speaking units with $diags diagnostics, was $DIAG_LINES/$DIAG_DIAGS."
  fi
  local against=${4:-$WORK/base.tags}
  local againstname="the baseline"
  [ "$against" = "$WORK/base.tags" ] || againstname="$(basename "$against" .tags)"
  if cmp -s "$against" "$WORK/ctl.tags"; then
    echo "  pin       unmoved against $againstname — all eleven fixtures answer the same tag."
  else
    green "pin       RED against $againstname"
    diff "$against" "$WORK/ctl.tags" | sed 's/^/    /'
  fi
  cp "$WORK/ctl.tags" "$WORK/last.tags"
  if [ "$rc" = 0 ] && cmp -s "$against" "$WORK/ctl.tags"; then
    if [ "$speaking" != "$DIAG_LINES" ] || [ "$diags" != "$DIAG_DIAGS" ]; then
      echo "  ungated on both, WITH A NUMBER: $DIAG_LINES/$DIAG_DIAGS -> $speaking/$diags."
      echo "  A control which REMOVES a diagnostic is ungated on diagcheck by"
      echo "  construction (its header), and the falling count is then the row."
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
# copy of the tree before a single build is spent.

cat > "$PATCHDIR/g01.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE TWO-DECLARATION MESSAGES SWAPPED — TS1188 for a for-in and TS1091 for a
# for-of. The reference chooses between them on the loop's KIND and on nothing else,
# so the swap is invisible to every MATCH counter and to any test that only asks
# whether a diagnostic was produced. checker_statement_for_grammar.ts holds both
# spellings of all three reports for exactly this class of row.
old = """            if k = KindForInStatement
                return this.grammar_error_on_first_token(AstNode.child_in_list(declarations, 1), DiagOnly_a_single_variable_declaration_is_allowed_in_a_for_in_statement)
            return this.grammar_error_on_first_token(AstNode.child_in_list(declarations, 1), DiagOnly_a_single_variable_declaration_is_allowed_in_a_for_of_statement)"""
new = """            if k = KindForInStatement
                return this.grammar_error_on_first_token(AstNode.child_in_list(declarations, 1), DiagOnly_a_single_variable_declaration_is_allowed_in_a_for_of_statement)
            return this.grammar_error_on_first_token(AstNode.child_in_list(declarations, 1), DiagOnly_a_single_variable_declaration_is_allowed_in_a_for_in_statement)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g02.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THAT REPORT ON declarations[0] INSTEAD OF [1]. `for (var a, b in {})` reports on
# `b`, not on `a` — the message says *only a single declaration is allowed* and points
# at the one that is too many. A port that reached for the first element would be
# right about the code and wrong about the span, which is the half only a
# span-comparing instrument can see.
old = """AstNode.child_in_list(declarations, 1), DiagOnly_a_single_variable_declaration_is_allowed_in_a_for_in_statement"""
new = """AstNode.child_in_list(declarations, 0), DiagOnly_a_single_variable_declaration_is_allowed_in_a_for_in_statement"""
assert s.count(old) == 1, s.count(old)
s = s.replace(old, new)
old2 = """AstNode.child_in_list(declarations, 1), DiagOnly_a_single_variable_declaration_is_allowed_in_a_for_of_statement"""
new2 = """AstNode.child_in_list(declarations, 0), DiagOnly_a_single_variable_declaration_is_allowed_in_a_for_of_statement"""
assert s.count(old2) == 1, s.count(old2)
open(p, "w").write(s.replace(old2, new2))
PY

cat > "$PATCHDIR/g03.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THAT REPORT THROUGH grammar_error_on_node INSTEAD OF ON THE FIRST TOKEN, and the
# row is worth its own paragraph because it was UNGATED until a fixture line was
# written for it. The reference uses grammarErrorOnFirstToken here and
# grammarErrorOnNode two reports later, four lines apart — and for a BARE identifier
# the two answer the same span, because error_range_for_node resolves a
# VariableDeclaration to its NAME and a bare name's first token is the name. Over 17 950
# corpus units nothing separated them. `for (var a2, [b2] in {})` does: the first token
# of `[b2]` is `[`, one character against three. **A distinction that looks stylistic is
# a different answer on exactly the inputs the corpus does not hold.**
old = """                return this.grammar_error_on_first_token(AstNode.child_in_list(declarations, 1), DiagOnly_a_single_variable_declaration_is_allowed_in_a_for_in_statement)"""
new = """                return this.grammar_error_on_node(AstNode.child_in_list(declarations, 1), DiagOnly_a_single_variable_declaration_is_allowed_in_a_for_in_statement)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g04.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE INITIALIZER REPORT MOVED FROM THE NAME TO THE DECLARATION — AND IT CANNOT BE
# GATED, WITH A PROOF RATHER THAN FOR WANT OF A FIXTURE. The reference writes
# `grammarErrorOnNode(firstVariableDeclaration.Name(), …)` and this patch writes
# `…(firstVariableDeclaration, …)`, which reads like two different spans and is one:
# error_range_for_node's declaration-name arm resolves a VariableDeclaration to its
# name before doing anything else, so `on_node(decl)` and `on_node(decl.Name())` are
# the SAME RANGE for every declaration there is, bare name or destructuring pattern
# (`for (var [e2] = 1 in {})` in the fixture is the line that shows the pattern case
# too). This is §3.5v's fourth kind — two spellings that provably coincide — and the
# reference's choice is kept because it is the reference's, not because this port can
# tell the difference.
old = """                return this.grammar_error_on_node(AstNode.name_of(first), DiagThe_variable_declaration_of_a_for_in_statement_cannot_have_an_initializer)"""
new = """                return this.grammar_error_on_node(first, DiagThe_variable_declaration_of_a_for_in_statement_cannot_have_an_initializer)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g05.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE ANNOTATION REPORT MOVED FROM THE DECLARATION TO THE NAME, i.e. the OPPOSITE
# of g04 — and the pair is what turns g04's proof into a general statement. The
# reference points these two reports at two DIFFERENT nodes twelve lines apart
# (`…Name()` for the initializer, `…AsNode()` for the annotation), so a reader would
# expect at least one of the two swaps to be visible. Neither is: the declaration-name
# arm collapses both spellings onto the name, so the reference's own distinction has no
# consequence in this port at all. **A faithful port can carry a difference it is
# incapable of getting wrong**, and the honest thing is to say so at the row rather
# than to leave two silent controls in the battery.
old = """                return this.grammar_error_on_node(first, DiagThe_left_hand_side_of_a_for_in_statement_cannot_use_a_type_annotation)"""
new = """                return this.grammar_error_on_node(AstNode.name_of(first), DiagThe_left_hand_side_of_a_for_in_statement_cannot_use_a_type_annotation)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g06.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE ANNOTATION MESSAGES SWAPPED — TS2483 for a for-in and TS2404 for a for-of.
# g01 for the third of the three pairs; it is a separate row because the three pairs
# are three independent choices in the reference's text and a port could get any one
# of them backwards on its own.
old = """                return this.grammar_error_on_node(first, DiagThe_left_hand_side_of_a_for_in_statement_cannot_use_a_type_annotation)
            return this.grammar_error_on_node(first, DiagThe_left_hand_side_of_a_for_of_statement_cannot_use_a_type_annotation)"""
new = """                return this.grammar_error_on_node(first, DiagThe_left_hand_side_of_a_for_of_statement_cannot_use_a_type_annotation)
            return this.grammar_error_on_node(first, DiagThe_left_hand_side_of_a_for_in_statement_cannot_use_a_type_annotation)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g07.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE GUARD ON checkGrammarVariableDeclarationList INVERTED — the declaration
# branch entered only when the list check DID report. The reference's `if
# !c.checkGrammarVariableDeclarationList(list)` is what stops a second report on a
# list that has already produced one, and inverting it silences all six of this
# family's diagnostics on the fixture. Ungated by construction (a control that REMOVES
# a diagnostic is), and the falling count is the row.
old = """        if this.check_grammar_variable_declaration_list(initializer)
            return false"""
new = """        if this.check_grammar_variable_declaration_list(initializer) = false
            return false"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g08.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE `async` TEXT TEST DROPPED — TS1106 for EVERY for-of whose left side is a
# bare identifier. `async` is not a keyword in that position and the reference
# compares the identifier's TEXT, so a port that read the shape instead of the
# spelling would report on `for (x of [])` too. The corpus is full of those, which is
# why this row is the loudest of the battery.
old = """                    if Checker.identifier_text_equals(initializer, "async", 5)
                        return this.grammar_error_on_node(initializer, DiagThe_left_hand_side_of_a_for_of_statement_may_not_be_async)"""
new = """                    return this.grammar_error_on_node(initializer, DiagThe_left_hand_side_of_a_for_of_statement_may_not_be_async)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g09.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★ THE `async` REPORT MOVED FROM THE INITIALIZER TO THE STATEMENT. Same code, same
# unit, five characters against a whole `for (async of []) { }` — the cheapest kind of
# wrong answer and the one a count-based instrument cannot see at all.
old = """                        return this.grammar_error_on_node(initializer, DiagThe_left_hand_side_of_a_for_of_statement_may_not_be_async)"""
new = """                        return this.grammar_error_on_node(node, DiagThe_left_hand_side_of_a_for_of_statement_may_not_be_async)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g10.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ is_effective_external_module FORCED TRUE — TS1431 disappears. It is the one
# diagnostic of the await branch that survives this harness, and the row is what says
# so: with the test forced the fixture falls silent and the corpus loses five. Ungated
# by construction; the number is the row.
old = """    function is_effective_external_module(this) returns bool
    {
        if b.is_external_module_of()"""
new = """    function is_effective_external_module(this) returns bool
    {
        if true
            return true
        if b.is_external_module_of()"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g11.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ PREMISE ON THE FIELD: module_kind MOVED TO ES2015, which is in NEITHER label of
# the switch. The `default` arm then fires and TS1432 is INVENTED on the for-await
# fixture — a diagnostic the reference does not have, at a position it does not have
# it, which is the only thing diagcheck fails on. This is the row that proves the ES
# label is load-bearing rather than decorative: with the field at its derived ES2022
# the same code is silent.
old = """        set c.module_kind: ModuleKindES2022"""
new = """        set c.module_kind: ModuleKindES2015"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g12.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ PREMISE ON THE OTHER FIELD: language_version MOVED BELOW ES2017. module_kind
# stays at its derived ES2022, so the ES label is taken and its `break` is NOT — the
# fallthrough reaches TS1432. Together with g11 the two rows say that the label's two
# tests are independent and that BOTH of the harness's numbers are what kill the
# report; one row could not distinguish which.
old = """        set c.language_version: ScriptTargetES2025"""
new = """        set c.language_version: ScriptTargetES2015"""
assert s.count(old) == 1, s.count(old)
s = s.replace(old, new)
old2 = """define ScriptTargetES2017: int 4"""
new2 = """define ScriptTargetES2015: int 2
define ScriptTargetES2017: int 4"""
assert s.count(old2) == 1, s.count(old2)
open(p, "w").write(s.replace(old2, new2))
PY

cat > "$PATCHDIR/g13.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ PREMISE: module_kind MOVED TO Node16, implied_node_format LEFT AT None — and
# NOTHING MOVES. That is the row, not a hole in it: the Node label's body reports only
# when the file's implied format is CommonJS, and otherwise FALLS THROUGH to the ES
# label, whose target test then breaks exactly as it does at ES2022. So the fallthrough
# is proven to be a fallthrough. Read three independent labels into the Go switch
# instead and this row goes red, which is what makes it a measurement.
old = """        set c.module_kind: ModuleKindES2022"""
new = """        set c.module_kind: ModuleKindNode16"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g14.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ g13 PLUS implied_node_format = CommonJS — and now TS1309 IS invented. Against
# g13, whose only difference is the second field, the row isolates the Node label's own
# test: a NODE module kind alone does not report and a node module whose FILE is
# CommonJS does. It is also why implied_node_format is a THIRD field rather than a
# reuse of emit_module_format: two program answers that coincide today are two
# questions, and this row is the one that would notice the fold.
old = """        set c.module_kind: ModuleKindES2022"""
new = """        set c.module_kind: ModuleKindNode16"""
assert s.count(old) == 1, s.count(old)
s = s.replace(old, new)
old2 = """        set c.implied_node_format: ModuleKindNone"""
new2 = """        set c.implied_node_format: ModuleKindCommonJS"""
assert s.count(old2) == 1, s.count(old2)
open(p, "w").write(s.replace(old2, new2))
PY

cat > "$PATCHDIR/g15.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ PREMISE: module_kind MOVED TO CommonJS, which is in NEITHER label — TS1432 is
# invented, exactly as at ES2015. The row exists for its PARTNER g16 and not for
# itself: it establishes what the correct predicate answers for the one module kind
# the two candidate predicates disagree about.
old = """        set c.module_kind: ModuleKindES2022"""
new = """        set c.module_kind: ModuleKindCommonJS"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g16.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ g15 PLUS THE NODE-LABEL PREDICATE REPLACED BY isCommonJSContainingModuleKind —
# the confusion the eye wants to make, since the two functions are five lines apart and
# read almost the same. With module_kind at CommonJS the tempting predicate takes the
# Node label, the implied format is not CommonJS, the fallthrough reaches the ES test
# and ES2025 breaks it: NO diagnostic, where g15 has one. **Two ranges one member apart
# with two different answers are two functions**, and no fixture can show that — only
# a premise on the field can, which is why this pair exists at all.
old = """        set c.module_kind: ModuleKindES2022"""
new = """        set c.module_kind: ModuleKindCommonJS"""
assert s.count(old) == 1, s.count(old)
s = s.replace(old, new)
old2 = """                            if Checker.module_kind_reaches_the_node_label(module_kind)"""
new2 = """                            if Checker.is_common_js_containing_module_kind(module_kind)"""
assert s.count(old2) == 1, s.count(old2)
open(p, "w").write(s.replace(old2, new2))
PY

cat > "$PATCHDIR/g17.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ checkForStatement's GRAMMAR-LIST CALL REMOVED — the row that had to be gated
# TWICE, and the second time is the interesting one. The plain `for` has no report of
# its own: its whole content is two delegated calls, and this patch removes the grammar
# one (slice 53's checkGrammarVariableDeclarationList). Over 17 950 corpus units
# nothing moved — not one `for` head in the submodule corpus carries a faulty
# declaration list. The first draft of checker_statement_for_head.ts did not move it
# either, because the TS1155 and TS2480 it was written for come from the OTHER call:
# checkVariableDeclarationList's per-declaration WALK. **Two delegated calls whose
# report families are disjoint look like one check until a row separates them.** What
# separates them is `for (var ;;)` — an empty declaration list, TS1123, which only the
# LIST check produces.
old = """            if Checker.kind_or_unknown(initializer) = KindVariableDeclarationList
                this.check_grammar_variable_declaration_list(initializer)"""
new = """            if Checker.kind_or_unknown(initializer) = KindVariableDeclarationList
                this.record_unported("check-grammar-variable-declaration-list", KindVariableDeclarationList)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g18.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ checkForStatement's BODY WALK REMOVED — `c.checkSourceElement(data.Statement)`,
# one line, and it is what the section header means by *the arm that moves the most is
# not an arm, it is the walk*. Every diagnostic inside a `for` body belongs to another
# slice and none of them was reachable before this one; removing the line loses them
# all again.
old = """        this.check_source_element(AstNode.statement_of(node))
        ; `if node.Locals() != nil { c.registerForUnusedIdentifiersCheck(node) }` —"""
new = """        ; `if node.Locals() != nil { c.registerForUnusedIdentifiersCheck(node) }` —"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g19.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE for-in DESTRUCTURING REPORT MOVED FROM THE NAME TO THE DECLARATION — g04's
# proof at a third site, and it is kept for the same reason: the declaration-name arm
# of error_range_for_node makes `on_node(decl)` and `on_node(decl.Name())` one range,
# so `for (var [x] in {})` answers `[x]` either way. Three rows, one cause, and none of
# the three can be gated by any input.
old = """                if AstNode.is_binding_pattern(name)
                    this.error_on_node(name, DiagThe_left_hand_side_of_a_for_in_statement_cannot_be_a_destructuring_pattern)"""
new = """                if AstNode.is_binding_pattern(name)
                    this.error_on_node(AstNode.child_in_list(declarations, 0), DiagThe_left_hand_side_of_a_for_in_statement_cannot_be_a_destructuring_pattern)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g20.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE BINDING-PATTERN TEST DROPPED — TS2491 on every for-in whose left side is a
# declaration list, pattern or not. The corpus is mostly `for (var k in o)`, so this is
# an invented diagnostic on a large population and diagcheck is the only instrument
# that can see it.
old = """                if AstNode.is_binding_pattern(name)
                    this.error_on_node(name, DiagThe_left_hand_side_of_a_for_in_statement_cannot_be_a_destructuring_pattern)"""
new = """                this.error_on_node(name, DiagThe_left_hand_side_of_a_for_in_statement_cannot_be_a_destructuring_pattern)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g21.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE EXPRESSION BRANCH'S TWO LITERAL TESTS WIDENED TO *not an identifier*, which
# is the shape of the mistake a reader makes when the else-chain's second arm is
# missing: with TS2405 unavailable it is tempting to treat everything that is not a
# plain name as a destructuring pattern. `for (1 in {})` is the fixture line that says
# no — the reference reports TS2405 there, not TS2491. **Where the port cannot decide,
# the branch that suppresses is the only sound one**, and this row is the price of the
# other choice.
old = """                if ik = KindArrayLiteralExpression
                    this.error_on_node(initializer, DiagThe_left_hand_side_of_a_for_in_statement_cannot_be_a_destructuring_pattern)
                if ik = KindObjectLiteralExpression
                    this.error_on_node(initializer, DiagThe_left_hand_side_of_a_for_in_statement_cannot_be_a_destructuring_pattern)"""
new = """                if ik <> KindIdentifier
                    this.error_on_node(initializer, DiagThe_left_hand_side_of_a_for_in_statement_cannot_be_a_destructuring_pattern)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g22.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ checkForOfStatement's BODY WALK REMOVED — g18 one kind along, and it is a separate
# row because the three loop arms each carry their own copy of the line. A port that
# wired the walk into two of the three would be green on every instrument except the
# unit that puts a diagnostic inside a `for-of`.
old = """            if subject <> null
                this.record_unported("check-expression", AstNode.kind_of(subject))
        }
        this.check_source_element(AstNode.statement_of(node))
    }"""
new = """            if subject <> null
                this.record_unported("check-expression", AstNode.kind_of(subject))
        }
    }"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g23.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ checkReturnStatement's NULL-CONTAINER BRANCH REMOVED — TS1108 is the report this
# arm exists for under this harness, and it fires precisely when the ancestor walk
# finds nothing. Ungated by construction; the number is the row.
old = """        if container = null
        {
            this.grammar_error_on_first_token(node, DiagA_return_statement_can_only_be_used_within_a_function_body)
            return
        }"""
new = """        if container = null
            return"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g24.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE TWO RETURN MESSAGES SWAPPED — TS18041 for a `return` with no container and
# TS1108 for one inside a class static block. Both branches are `grammarErrorOnFirstToken`
# on the same node, so the span is identical and the CODE is the whole difference; the
# swap is invisible to anything that does not compare it.
old = """            this.grammar_error_on_first_token(node, DiagA_return_statement_cannot_be_used_inside_a_class_static_block)"""
new = """            this.grammar_error_on_first_token(node, DiagA_return_statement_can_only_be_used_within_a_function_body)"""
assert s.count(old) == 1, s.count(old)
s = s.replace(old, new)
old2 = """            this.grammar_error_on_first_token(node, DiagA_return_statement_can_only_be_used_within_a_function_body)
            return
        }
        this.record_unported("get-signature-from-declaration", AstNode.kind_of(container))"""
new2 = """            this.grammar_error_on_first_token(node, DiagA_return_statement_cannot_be_used_inside_a_class_static_block)
            return
        }
        this.record_unported("get-signature-from-declaration", AstNode.kind_of(container))"""
assert s.count(old2) == 1, s.count(old2)
open(p, "w").write(s.replace(old2, new2))
PY

cat > "$PATCHDIR/g25.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE DUPLICATE-DEFAULT ONCE-BIT NEVER SET — the report fires on the third `default`
# as well as the second. The reference keeps the flag precisely so that it does not, and
# the fixture has three clauses for exactly this row: with two it would be a control
# that cannot fail.
old = """                        this.grammar_error_on_node(clause, DiagA_default_clause_cannot_appear_more_than_once_in_a_switch_statement)
                        set has_duplicate_default_clause: true"""
new = """                        this.grammar_error_on_node(clause, DiagA_default_clause_cannot_appear_more_than_once_in_a_switch_statement)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g26.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE PER-CLAUSE STATEMENT WALK REMOVED. A switch clause is the last statement
# container the grammar has, and the reference walks it with checkSourceElements — the
# `using` reports (TS1547/TS1548) live nowhere else, since their message is literally
# about case and default clauses. Ungated by construction; the number is the row.
old = """            this.check_source_elements(AstNode.statements_of(clause))"""
new = """            ; the walk, removed by the control"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g27.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE CLAUSE ERROR RANGE'S END LEFT AT THE CLAUSE'S OWN End — i.e. the arm written
# without its statement-list step. TS1113 then spans the whole `default: break;` instead
# of `default:`, which is the arm slice 45 deferred and this slice paid: its note said
# *CaseClause and DefaultClause need the clause's statement list, for statements[0].Pos()
# as the end*, and this row is that sentence made falsifiable.
old = """        let statements AstNode.statements_of(n)
        if AstNode.list_count(statements) <> 0
            set *out_end: AstNode.pos_of(AstNode.child_in_list(statements, 0))"""
new = """        let statements AstNode.statements_of(n)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g28.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ statements_of's TWO NEW ARMS REMOVED (ast.scaly) — and ONE deletion breaks TWO
# things, which is why it is a row of its own rather than a duplicate of g26 and g27.
# The clause walk finds an empty list and stops, and the error range's end falls back to
# the clause's End because its statement step reads the same accessor. **A narrowed
# accessor answers a well-formed WRONG answer**, §3.5bk, and here the wrongness is a
# missing walk in one caller and a wrong span in the other.
old = """            when cc: CaseClause
                return cc.statements
            when dc: DefaultClause
                return dc.statements
"""
new = ""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g29.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ NamespaceExportDeclaration PUT BACK ON THE WORK LIST — the state this slice found
# it in. The kind's arm is not unported, it does not exist upstream, and the row shows
# the difference the only way it can be shown: the fixture's tag goes back to
# `check NamespaceExportDeclaration`, a row that names no work. It is PIN-only, because
# a kind that reports nothing either way cannot move diagcheck.
old = """        if k = KindNamespaceExportDeclaration
            return true
        k = KindLiteralType
"""
new = """        k = KindLiteralType
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g30.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ PREMISE: checkFunctionOrMethodDeclaration GIVEN ITS BODY WALK, slice 63's g16
# verbatim — and here it lifts a DIFFERENT report. With a function body walked, the
# for-await in checker_statement_for_await_unreachable.ts is no longer in a top-level
# context and TS1103 fires at the reference's own span. The row measures the section
# header's claim from the live side: what this slice cannot reach is bounded by ONE
# fact, and lifting that fact brings the code alive.
#
# ★ TS18038, the other unreachable report, does NOT come alive here: a class static
# block is reached through the class MEMBER walk, which is a second premise this row
# deliberately does not make. Its obstacle is named in the fixture instead.
old = """        this.record_unported("check-function-or-constructor-symbol", AstNode.kind_of(node))
    }"""
new = """        this.check_source_element(AstNode.body_of(node))
        this.record_unported("check-function-or-constructor-symbol", AstNode.kind_of(node))
    }"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g31.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ g30 PLUS THE TS1103 REPORT'S CODE SWAPPED. Against g30 — not against the
# baseline — the only difference is the diagnostic number, and diagcheck goes red: a
# report no fixture can reach is measured after all, and the measurement needed a
# PREMISE rather than a fixture. §3.5v's distinction between UNCOVERED and UNREACHABLE,
# made with two rows.
old = """        this.record_unported("check-function-or-constructor-symbol", AstNode.kind_of(node))
    }"""
new = """        this.check_source_element(AstNode.body_of(node))
        this.record_unported("check-function-or-constructor-symbol", AstNode.kind_of(node))
    }"""
assert s.count(old) == 1, s.count(old)
s = s.replace(old, new)
old2 = """                            this.error_on_node(await_modifier, DiagX_for_await_loops_are_only_allowed_within_async_functions_and_at_the_top_levels_of_modules)"""
new2 = """                            this.error_on_node(await_modifier, DiagThe_left_hand_side_of_a_for_of_statement_may_not_be_async)"""
assert s.count(old2) == 1, s.count(old2)
open(p, "w").write(s.replace(old2, new2))
PY

# ── the dry run ─────────────────────────────────────────────────────────────

bold "DRY RUN — every patch against a COPY of the tree"
DRY=$WORK/dry
mkdir -p "$DRY"
dry_ok=1
dry_one() {   # $1 = id, rest = files
  local id=$1; shift
  local copies="" f i=0
  for f in "$@"; do cp "$f" "$DRY/copy.$i"; copies="$copies $DRY/copy.$i"; i=$((i+1)); done
  if python3 "$PATCHDIR/$id.py" $copies 2> "$DRY/err"; then
    printf '  %s  ok\n' "$id"
  else
    red "  $id  DID NOT APPLY — $(tail -1 "$DRY/err")"
    dry_ok=0
  fi
}
for id in g01 g02 g03 g04 g05 g06 g07 g08 g09 g10 g11 g13 g15 g17 g18 g19 g20 g21 g22 g23 g24 g25 g26 g29 g30 g31; do
  dry_one "$id" "$CHECKER"
done
dry_one g12 "$CHECKER"
dry_one g14 "$CHECKER"
dry_one g16 "$CHECKER"
dry_one g27 "$BINDER"
dry_one g28 "$AST"
if [ "$dry_ok" != 1 ]; then
  red "at least one anchor is wrong. Fix them before spending the battery."
  exit 2
fi

baseline

control "g01 the two-declaration messages SWAPPED"                        "$CHECKER" "$PATCHDIR/g01.py"
control "g02 that report on declarations[0] instead of [1]"               "$CHECKER" "$PATCHDIR/g02.py"
control "g03 that report through grammar_error_on_node"                   "$CHECKER" "$PATCHDIR/g03.py"
control "g04 the initializer report moved to the DECLARATION"             "$CHECKER" "$PATCHDIR/g04.py"
control "g05 the annotation report moved to the NAME"                     "$CHECKER" "$PATCHDIR/g05.py"
control "g06 the annotation messages SWAPPED"                             "$CHECKER" "$PATCHDIR/g06.py"
control "g07 the declaration-list guard INVERTED"                         "$CHECKER" "$PATCHDIR/g07.py"
control "g08 the \`async\` TEXT test DROPPED"                               "$CHECKER" "$PATCHDIR/g08.py"
control "g09 the \`async\` report moved to the STATEMENT"                   "$CHECKER" "$PATCHDIR/g09.py"
control "g10 is_effective_external_module forced TRUE"                    "$CHECKER" "$PATCHDIR/g10.py"
control "g11 PREMISE: module_kind -> ES2015 (neither label)"              "$CHECKER" "$PATCHDIR/g11.py"
control "g12 PREMISE: language_version -> below ES2017"                   "$CHECKER" "$PATCHDIR/g12.py"
control "g13 PREMISE: module_kind -> Node16, implied format left None"    "$CHECKER" "$PATCHDIR/g13.py"
cp "$WORK/last.tags" "$WORK/g13.tags"
control "g14 g13 + implied_node_format -> CommonJS"                       "$CHECKER" "$PATCHDIR/g14.py" "$WORK/g13.tags"
control "g15 PREMISE: module_kind -> CommonJS (neither label)"            "$CHECKER" "$PATCHDIR/g15.py"
cp "$WORK/last.tags" "$WORK/g15.tags"
control "g16 g15 + the node-label predicate swapped for the CommonJS one" "$CHECKER" "$PATCHDIR/g16.py" "$WORK/g15.tags"
control "g17 checkForStatement's grammar-list call REMOVED"               "$CHECKER" "$PATCHDIR/g17.py"
control "g18 checkForStatement's BODY WALK removed"                       "$CHECKER" "$PATCHDIR/g18.py"
control "g19 the for-in destructuring report moved to the DECLARATION"    "$CHECKER" "$PATCHDIR/g19.py"
control "g20 the binding-pattern test DROPPED"                            "$CHECKER" "$PATCHDIR/g20.py"
control "g21 the literal tests widened to *not an identifier*"            "$CHECKER" "$PATCHDIR/g21.py"
control "g22 checkForOfStatement's BODY WALK removed"                     "$CHECKER" "$PATCHDIR/g22.py"
control "g23 checkReturnStatement's null-container branch REMOVED"        "$CHECKER" "$PATCHDIR/g23.py"
control "g24 the two return messages SWAPPED"                             "$CHECKER" "$PATCHDIR/g24.py"
control "g25 the duplicate-default once-bit never SET"                    "$CHECKER" "$PATCHDIR/g25.py"
control "g26 the per-clause statement walk REMOVED"                       "$CHECKER" "$PATCHDIR/g26.py"
control "g27 the clause error range's END left at the clause's End"       "$BINDER"  "$PATCHDIR/g27.py"
control "g28 statements_of's two CLAUSE arms REMOVED"                     "$AST"     "$PATCHDIR/g28.py"
control "g29 NamespaceExportDeclaration put back on the work list"        "$CHECKER" "$PATCHDIR/g29.py"
control "g30 PREMISE: checkFunctionOrMethodDeclaration given its body walk" "$CHECKER" "$PATCHDIR/g30.py"
cp "$WORK/last.tags" "$WORK/g30.tags"
control "g31 g30 + the TS1103 report's CODE swapped"                      "$CHECKER" "$PATCHDIR/g31.py" "$WORK/g30.tags"

echo
echo "################################################################"
bold "RESTORED — checker.scaly, ast.scaly and binder.scaly, byte-identical"
git -C "$REPO" diff --stat -- "$CHECKER" "$AST" "$BINDER" | tail -4
