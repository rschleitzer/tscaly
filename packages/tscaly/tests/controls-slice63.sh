#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice63.sh — the slice-63 battery: the JUMP-AND-GUARD statement arms,
# i.e. the if / do / while / (continue, break) / with / labeled / throw / try cases
# of checkSourceElement and the ten reference functions behind them
# (checkIfStatement, checkDoStatement, checkWhileStatement, checkThrowStatement,
# checkWithStatement, checkTryStatement, checkCatchClause,
# checkBreakOrContinueStatement, checkGrammarBreakOrContinueStatement,
# checkLabeledStatement).
#
# ★★★ TWENTY-FOUR ROWS, AND THE SLICE'S SHAPE IS THAT ITS REPORTS ARE FINALLY
# SYNTACTIC. Every diagnostic these arms carry is decided by the shape of the tree
# and by the binder's own tables, so twelve of the rows break a LIVE report and
# diagcheck sees it. What the slice cannot reach is bounded by ONE fact, and two
# rows measure it from both sides: **nothing in this port walks into a function
# body**, so TS1107 (jump target cannot cross a function boundary) and
# checkLabeledStatement's function-like stop are dead code — g15 and g19 remove them
# and nothing moves, while g16 adds the body walk as a PREMISE and the report comes
# alive (slice 62's g19/g20 technique).
#
# ★★★ THE ROW THAT JUSTIFIES A DIRECTION IS g20, and it is slice 62's g07 one arm
# along. checkCatchClause's annotation branch cannot decide *must be any or unknown*
# — the answer is a resolved TYPE — so it reports `get-type-from-type-node` and says
# nothing. g20 makes it report TS1196 unconditionally instead: right on
# `catch (e: string)`, and an INVENTED diagnostic on `catch (e: any)`, which the
# fixture holds for exactly this row. **Where the port cannot decide, the branch that
# suppresses is the only sound one**, because diagcheck forgives a missing line and
# fails on an invented one.
#
# ★★ TWO INSTRUMENTS, as in slices 56–62. diagcheck gates the reports; a PIN over the
# ten fixtures' unported TAGS gates the arms and the two orderings that produce no
# diagnostic at all — g05 (the `do`'s two steps swapped) is a pin row and nothing
# else, because the order of a prefix is visible in the TAG and nowhere else.
#
# ★ ONE FILE IS PATCHED, checker.scaly. Every patch is dry-run against a copy of the
# tree before a single build is spent (slice 57), and the restore is proven with
# `cmp` and survives a kill (slice 58).
#
# Usage (nothing may edit the tree while this runs — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # the artifact tree, first
#   packages/tscaly/tests/controls-slice63.sh 2>&1 | tee /tmp/battery63.log

set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.0/tscaly/checker.scaly
FIX=$PKG/tests/fixtures

LIBSCALY=${LIBSCALY:-/tmp/libscaly.a}
SCALYC=${SCALYC:-$REPO/scalyc/build/scalyc}

# The fixtures the PIN reads — all ten of this slice's. Two of them produce no
# diagnostic of their own and exist for the tag alone (the do/while order and the
# unreachable function boundary); the rest carry both.
TAGFILES="
$FIX/checker_statement_if_empty_body.ts
$FIX/checker_statement_throw_line_break.ts
$FIX/checker_statement_with_unsupported.ts
$FIX/checker_statement_break_continue_targets.ts
$FIX/checker_statement_jump_crosses_function.ts
$FIX/checker_statement_duplicate_label.ts
$FIX/checker_statement_label_through_labels.ts
$FIX/checker_statement_catch_clause.ts
$FIX/checker_statement_do_while_order.ts
$FIX/checker_statement_ambient_context.d.ts
"

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  echo "Both instruments compare against the reference dumps that run produced."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl63)

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

control() {   # $1 = label, $2 = file, $3 = python patch file, $4 = optional tag file to diff against
  echo
  echo "################################################################"
  bold "CONTROL: $1"
  cp "$2" "$WORK/orig"
  PATCHED_ORIG=$WORK/orig
  PATCHED_FILE=$2
  if ! python3 "$3" "$2"; then
    red "the patch did not apply — the anchor moved. The row measures nothing."
    cp "$WORK/orig" "$2"
    PATCHED_FILE=""
    return 1
  fi
  echo "  patched $2"
  if ! build_diag_bin; then
    red "the patched tree did not build — the row measures nothing:"
    tail -5 "$WORK/build.log" | sed 's/^/    /'
    cp "$WORK/orig" "$2"
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
  cp "$WORK/orig" "$2"
  if ! cmp -s "$WORK/orig" "$2"; then
    red "the source did NOT come back — every number below is suspect."
    return 1
  fi
  PATCHED_FILE=""
  echo "  RESTORE VERIFIED   $2 byte-identical"
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
    echo "  pin       unmoved against $againstname — all ten fixtures answer the same tag."
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
# ★★★ checkIfStatement's EMPTY-STATEMENT TEST INVERTED — TS1313 for every `if` whose
# then-branch is NOT the empty statement, which is nearly all of them. It is the
# loudest row of the battery for the same reason slice 62's g01 was: an inverted test
# is invisible to every MATCH counter, because an invented diagnostic can only be
# seen by a subsequence.
old = """        if Checker.kind_or_unknown(then_statement) = KindEmptyStatement"""
new = """        if Checker.kind_or_unknown(then_statement) <> KindEmptyStatement"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g02.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE TEST ASKED OF THE ELSE BRANCH. The reference asks it of `data.ThenStatement`
# alone, and checker_statement_if_empty_body.ts has an empty branch on BOTH sides for
# exactly this row: read the test as *an empty branch* and the port reports on the
# `else`, which the reference does not.
old = """        if Checker.kind_or_unknown(then_statement) = KindEmptyStatement
            this.error_on_node(then_statement, DiagThe_body_of_an_if_statement_cannot_be_the_empty_statement)"""
new = """        if Checker.kind_or_unknown(AstNode.else_statement_of(node)) = KindEmptyStatement
            this.error_on_node(AstNode.else_statement_of(node), DiagThe_body_of_an_if_statement_cannot_be_the_empty_statement)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g03.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ checkIfStatement's FIRST LINE REMOVED — the shared ambient-context check. The
# `if` is the first statement of the ambient fixture's namespace body, so with the
# call gone the block's once-bit is unspent when the `try` is reached and OUR TS1036
# lands on the `try` while the reference's is on the `if`. The row measures the
# sentence in the section header — *the arm that moves the most is not one of the
# arms, it is the first line they share* — and it is a WRONG SPAN rather than a
# missing line, which is what diagcheck exists for.
old = """    procedure check_if_statement(this, node: pointer[AstNode])
    {
        this.check_grammar_statement_in_ambient_context(node)"""
new = """    procedure check_if_statement(this, node: pointer[AstNode])
    {"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g04.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE IfStatement ARM UNWIRED — the kind falls back to the unported gate, which
# spends the container's ambient bit silently. Both instruments move: the fixture's
# tag becomes `check IfStatement` and its TS1313 goes with the arm.
old = """        if k = KindIfStatement
        {
            this.check_if_statement(node)
            return
        }
"""
new = ""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g05.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ checkDoStatement's TWO STEPS SWAPPED — the body walked after the condition
# instead of before it, i.e. a `do` spelled like a `while`. No diagnostic moves,
# because neither step reports; what moves is the unit's unported TAG, from
# `check-expression CallExpression` to `check-expression Identifier`, and the PIN is
# the entire gate. **The order of a prefix is visible in the tag and nowhere else**,
# which is why this file has a fixture whose whole content is that order.
old = """        this.check_grammar_statement_in_ambient_context(node)
        this.check_source_element(AstNode.statement_of(node))
        this.check_truthiness_expression(AstNode.expression_of(node))"""
new = """        this.check_grammar_statement_in_ambient_context(node)
        this.check_truthiness_expression(AstNode.expression_of(node))
        this.check_source_element(AstNode.statement_of(node))"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g06.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE THROW REPORT'S LENGTH CHANGED FROM 0 TO 1. The reference passes
# `0 /*length*/` and means it: the diagnostic sits at a position where there is no
# token at all. A one-character span is the most plausible wrong answer and no
# counter can see it — only a span comparison can.
old = """                    this.grammar_error_at_pos(AstNode.pos_of(throw_expr), 0, DiagLine_break_not_permitted_here)"""
new = """                    this.grammar_error_at_pos(AstNode.pos_of(throw_expr), 1, DiagLine_break_not_permitted_here)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g07.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE THROW REPORT'S EMPTY-TEXT TEST DROPPED — every `throw <identifier>` reports
# TS1142. The two tests are independent (an identifier that IS there must not report),
# and the corpus is full of the shape that proves it.
old = """                if AstNode.identifier_text_length_of(throw_expr) = 0
                    this.grammar_error_at_pos"""
new = """                if AstNode.identifier_text_length_of(throw_expr) >= 0
                    this.grammar_error_at_pos"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g08.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE `with` REPORT'S END TAKEN FROM THE STATEMENT INSTEAD OF FROM ITS BODY. The
# reference's span is the HEAD alone — `end := node.Statement().Pos()` — so it stops
# at the body's first character; taking the whole statement's end covers the block
# too. Right error, right file, wrong span, and the only instrument that can tell is
# this one.
old = """        this.grammar_error_at_pos(start, AstNode.pos_of(body) - start, DiagThe_with_statement_is_not_supported_All_symbols_in_a_with_block_will_have_type_any)"""
new = """        this.grammar_error_at_pos(start, AstNode.end_of(node) - start, DiagThe_with_statement_is_not_supported_All_symbols_in_a_with_block_will_have_type_any)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g09.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE `with` REPORT'S START TAKEN WITHOUT skip_trivia. `node.Pos()` is where the
# node's LEADING TRIVIA begins, not where its first token does — the reference calls
# scanner.SkipTrivia on it precisely because the two differ — and in a fixture whose
# statements are preceded by a comment block the difference is hundreds of bytes.
# **A node's pos is not its start**, and this is the row that holds the distinction to
# a number.
old = """        let start b.skip_trivia_at(AstNode.pos_of(node))"""
new = """        let start AstNode.pos_of(node)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g10.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE `with` REPORT REMOVED — a row that only takes a line away, and this time the
# line is NOT also control flow, so it is ungated by construction and the falling
# count is the row. It is the near half of slice 62's g06 lesson: the same edit is a
# measurement or a nothing depending on whether the removed line also returns.
old = """        if this.has_parse_diagnostics()
            return
        let start b.skip_trivia_at(AstNode.pos_of(node))
        this.grammar_error_at_pos(start, AstNode.pos_of(body) - start, DiagThe_with_statement_is_not_supported_All_symbols_in_a_with_block_will_have_type_any)"""
new = """        if this.has_parse_diagnostics()
            return"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g11.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE FOUR FINAL MESSAGES' LABELED/UNLABELED SPLIT SWAPPED. A jump that reached
# the top of the tree reports one of four codes, chosen by whether it named a label
# and by whether it is a `break` or a `continue`; swapping the two GROUPS makes a bare
# `break` report TS1116 (*can only jump to a label of an enclosing statement*) where
# TS1105 belongs. The four codes are one line apart in the source and nothing but the
# name distinguishes them.
old = """        if target_label <> null
        {
            if k = KindBreakStatement
                return this.grammar_error_on_node(node, DiagA_break_statement_can_only_jump_to_a_label_of_an_enclosing_statement)
            return this.grammar_error_on_node(node, DiagA_continue_statement_can_only_jump_to_a_label_of_an_enclosing_iteration_statement)
        }
        if k = KindBreakStatement
            return this.grammar_error_on_node(node, DiagA_break_statement_can_only_be_used_within_an_enclosing_iteration_or_switch_statement)
        this.grammar_error_on_node(node, DiagA_continue_statement_can_only_be_used_within_an_enclosing_iteration_statement)"""
new = """        if target_label = null
        {
            if k = KindBreakStatement
                return this.grammar_error_on_node(node, DiagA_break_statement_can_only_jump_to_a_label_of_an_enclosing_statement)
            return this.grammar_error_on_node(node, DiagA_continue_statement_can_only_jump_to_a_label_of_an_enclosing_iteration_statement)
        }
        if k = KindBreakStatement
            return this.grammar_error_on_node(node, DiagA_break_statement_can_only_be_used_within_an_enclosing_iteration_or_switch_statement)
        this.grammar_error_on_node(node, DiagA_continue_statement_can_only_be_used_within_an_enclosing_iteration_statement)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g12.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE SAME FOUR MESSAGES' break/continue SPLIT SWAPPED, i.e. the other axis of the
# same table. A bare `break` then reports TS1104 and a bare `continue` TS1105. The two
# rows together say the table is two-dimensional and that both dimensions are load
# bearing — one of them alone would leave half the table unmeasured.
old = """        if k = KindBreakStatement
            return this.grammar_error_on_node(node, DiagA_break_statement_can_only_be_used_within_an_enclosing_iteration_or_switch_statement)
        this.grammar_error_on_node(node, DiagA_continue_statement_can_only_be_used_within_an_enclosing_iteration_statement)"""
new = """        if k <> KindBreakStatement
            return this.grammar_error_on_node(node, DiagA_break_statement_can_only_be_used_within_an_enclosing_iteration_or_switch_statement)
        this.grammar_error_on_node(node, DiagA_continue_statement_can_only_be_used_within_an_enclosing_iteration_statement)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g13.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ is_iteration_statement's LabeledStatement ARM REMOVED. `a: b: c: do continue a;
# while (1)` is a legal program: the predicate has to look THROUGH two labels to find
# the `do`. Without the arm it answers false, the walk decides the label is misplaced,
# and the port invents a TS1115 on a correct program — the failure mode a subsequence
# test exists to catch.
old = """        if k = KindLabeledStatement
        {
            if look_in_labeled_statements = false
                return false
            return Checker.is_iteration_statement(AstNode.statement_of(node), look_in_labeled_statements)
        }
        false"""
new = """        false"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g14.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE RECURSION'S FLAG FORCED FALSE — the arm kept, the flag not passed on. With
# TWO labels this row would be ungated (the single recursive step lands directly on
# the `do`); the fixture has THREE for exactly that reason, so the flag at the CALL
# SITE (g13's neighbour) and the flag inside the RECURSION are separately measurable.
# **A parameter whose value only matters at depth two needs a fixture of depth
# three.**
old = """            return Checker.is_iteration_statement(AstNode.statement_of(node), look_in_labeled_statements)"""
new = """            return Checker.is_iteration_statement(AstNode.statement_of(node), false)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g15.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE FUNCTION-BOUNDARY TEST REMOVED — and NOTHING MOVES, which is the claim.
# TS1107 is unreachable because no arm of this port walks into a function body, so the
# walk in checkGrammarBreakOrContinueStatement can never meet a function-like
# ancestor. g16 is the proof from the other side: add the body walk as a premise and
# the report comes alive. **A row that predicted its own silence is a measurement; the
# same row without the prediction is a hole in the battery.**
old = """            if Checker.is_function_like_or_class_static_block_declaration(current)
                return this.grammar_error_on_node(node, DiagJump_target_cannot_cross_function_boundary)"""
new = """"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g16.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ PREMISE: checkFunctionOrMethodDeclaration GIVEN ITS BODY WALK, which is the
# reference's own `c.checkSourceElement(node.Body())` several statements past the stop.
# It is not a fix and is not proposed as one — the statements in between are the type
# dimension — but it lifts the ONE obstacle that makes TS1107 dead, and the report
# then fires on `function f() { break; }` at the reference's own span. The number is
# the row: a diagnostic APPEARS.
old = """        this.record_unported("check-function-or-constructor-symbol", AstNode.kind_of(node))
    }"""
new = """        this.check_source_element(AstNode.body_of(node))
        this.record_unported("check-function-or-constructor-symbol", AstNode.kind_of(node))
    }"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g17.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ g16 PLUS THE FUNCTION-BOUNDARY REPORT'S CODE SWAPPED. Against g16 — not against
# the baseline — the only difference is the diagnostic number, and diagcheck goes red:
# the report no fixture can reach is measured after all, and the measurement needed a
# PREMISE rather than a fixture. That is §3.5v's distinction between UNCOVERED and
# UNREACHABLE, made with two rows, and it is slice 62's g19/g20 one dimension along.
old = """        this.record_unported("check-function-or-constructor-symbol", AstNode.kind_of(node))
    }"""
new = """        this.check_source_element(AstNode.body_of(node))
        this.record_unported("check-function-or-constructor-symbol", AstNode.kind_of(node))
    }"""
assert s.count(old) == 1, s.count(old)
s = s.replace(old, new)
old2 = """                return this.grammar_error_on_node(node, DiagJump_target_cannot_cross_function_boundary)"""
new2 = """                return this.grammar_error_on_node(node, DiagA_break_statement_can_only_be_used_within_an_enclosing_iteration_or_switch_statement)"""
assert s.count(old2) == 1, s.count(old2)
open(p, "w").write(s.replace(old2, new2))
PY

cat > "$PATCHDIR/g18.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE DUPLICATE-LABEL REPORT MOVED TO THE STATEMENT. The reference reports on the
# LABEL — `grammarErrorOnNode(labelNode, …)` — and here the two spellings do NOT
# coincide: a LabeledStatement's error range is its whole `a: …` and the label's is
# one character. It is slice 62's span-table finding from the red side: there the two
# spellings provably agreed and the row was ungated.
old = """                        this.grammar_error_on_node(label_node, DiagDuplicate_label_0)"""
new = """                        this.grammar_error_on_node(node, DiagDuplicate_label_0)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g19.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ checkLabeledStatement's FUNCTION-LIKE STOP REMOVED — and nothing moves, for
# g15's reason at a second site: the walk starts at the labeled statement's parent and
# climbs, and a labeled statement this port reaches has no function-like ancestor,
# because it was reached from a statement list that no function body owns. The two
# rows together bound the slice's unreachability to ONE fact rather than two.
old = """                if AstNode.is_function_like(current)
                    break
"""
new = ""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g20.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE ROW THAT JUSTIFIES A DIRECTION. checkCatchClause's annotation branch cannot
# decide *must be any or unknown* — the reference asks getTypeFromTypeNode and then
# `t.flags&AnyOrUnknown == 0` — so this port reports the hole and says nothing. Here
# it reports TS1196 unconditionally instead: correct on `catch (e: string)`, and an
# INVENTED diagnostic on `catch (e: any)`, which the fixture holds for this row alone.
# **Where the port cannot decide, the branch that suppresses is the only sound one**,
# because diagcheck forgives a missing line and fails on an invented one.
old = """            if type_node <> null
                this.record_unported("get-type-from-type-node", AstNode.kind_of(type_node))"""
new = """            if type_node <> null
                this.grammar_error_on_first_token(type_node, DiagCatch_clause_variable_type_annotation_must_be_any_or_unknown_if_specified)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g21.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE REDECLARATION WALK'S BLOCK-SCOPE TEST REMOVED — and the row is worth more
# than its verdict, because its FIRST version was ungated and the reason was in the
# fixture rather than in the code. The obvious negative is `try {} catch (e) { var e; }`
# — a `var` is FUNCTION-scoped and does not redeclare the caught name — and it never
# reaches the test at all: a hoisted `var` is not in the BLOCK's locals, so the lookup
# answers null one line earlier. The negatives that DO reach it are a block-scoped
# FUNCTION and a CLASS, which are in the block's locals and carry
# SymbolFlagsFunction / SymbolFlagsClass; without the flag test the port invents a
# TS2492 on each. **A negative that does not reach the branch it is aimed at is not a
# negative**, and the fixture carries all three lines so the distinction survives.
old = """                    if (Symbol.flags_of(block_local) & SymbolFlagsBlockScopedVariable) <> 0"""
new = """                    if true"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g22.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE REDECLARATION REPORT MOVED FROM THE BLOCK LOCAL'S DECLARATION TO THE CATCH
# CLAUSE. The reference reports on `blockLocal.ValueDeclaration` — the INNER `let`,
# not the caught name — and the two are on different lines of the fixture, so the
# wrong one is a wrong span rather than a missing report. It is also the row that says
# why the walk reads two tables: get the pairing backwards and the report lands on the
# thing that was declared FIRST.
old = """                        this.grammar_error_on_node(value_declaration, DiagCannot_redeclare_identifier_0_in_catch_clause)"""
new = """                        this.grammar_error_on_node(node, DiagCannot_redeclare_identifier_0_in_catch_clause)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g23.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★ checkTryStatement's FINALLY WALK REMOVED. The `with` fixture's second statement is
# a `with` inside a `finally`, and it is there because this slice's arms are the only
# route into a nested statement it has. Removing the walk loses that TS2410 — ungated
# by construction, and the falling count is the row.
old = """        let finally_block AstNode.finally_block_of(node)
        if finally_block <> null
            this.check_block(finally_block)"""
new = """        let finally_block AstNode.finally_block_of(node)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g24.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ checkBreakOrContinueStatement's GUARD INVERTED — the grammar check run only when
# the ambient check REPORTED. In the ambient fixture the block's once-bit is already
# spent by the `if`, so the ambient check answers false and the grammar check is
# skipped: TS1105 disappears. It is the row that says the `!` in
# `if !c.checkGrammarStatementInAmbientContext(node)` is load-bearing rather than
# decoration, and it is ungated with a number for the usual reason.
old = """        if this.check_grammar_statement_in_ambient_context(node) = false
            this.check_grammar_break_or_continue_statement(node)"""
new = """        if this.check_grammar_statement_in_ambient_context(node)
            this.check_grammar_break_or_continue_statement(node)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

# ── the dry run ─────────────────────────────────────────────────────────────

bold "DRY RUN — every patch against a COPY of the tree"
DRY=$WORK/dry
mkdir -p "$DRY"
dry_ok=1
for id in g01 g02 g03 g04 g05 g06 g07 g08 g09 g10 g11 g12 g13 g14 g15 g16 g17 g18 g19 g20 g21 g22 g23 g24; do
  cp "$CHECKER" "$DRY/copy"
  if python3 "$PATCHDIR/$id.py" "$DRY/copy" 2> "$DRY/err"; then
    printf '  %s  ok\n' "$id"
  else
    red "  $id  DID NOT APPLY — $(tail -1 "$DRY/err")"
    dry_ok=0
  fi
done
if [ "$dry_ok" != 1 ]; then
  red "at least one anchor is wrong. Fix them before spending the battery."
  exit 2
fi

baseline

control "g01 the if empty-statement test INVERTED"                       "$CHECKER" "$PATCHDIR/g01.py"
control "g02 that test asked of the ELSE branch"                         "$CHECKER" "$PATCHDIR/g02.py"
control "g03 checkIfStatement's ambient first line REMOVED"              "$CHECKER" "$PATCHDIR/g03.py"
control "g04 the IfStatement arm UNWIRED"                                "$CHECKER" "$PATCHDIR/g04.py"
control "g05 checkDoStatement's two steps SWAPPED"                       "$CHECKER" "$PATCHDIR/g05.py"
control "g06 the throw report's LENGTH changed from 0 to 1"              "$CHECKER" "$PATCHDIR/g06.py"
control "g07 the throw report's empty-text test DROPPED"                 "$CHECKER" "$PATCHDIR/g07.py"
control "g08 the with report's END taken from the statement"             "$CHECKER" "$PATCHDIR/g08.py"
control "g09 the with report's START taken without skip_trivia"          "$CHECKER" "$PATCHDIR/g09.py"
control "g10 the with report REMOVED"                                    "$CHECKER" "$PATCHDIR/g10.py"
control "g11 the jump messages' LABELED/UNLABELED split swapped"         "$CHECKER" "$PATCHDIR/g11.py"
control "g12 the jump messages' break/continue split swapped"            "$CHECKER" "$PATCHDIR/g12.py"
control "g13 is_iteration_statement's LabeledStatement arm REMOVED"      "$CHECKER" "$PATCHDIR/g13.py"
control "g14 that arm's RECURSION given false instead of the flag"       "$CHECKER" "$PATCHDIR/g14.py"
control "g15 the function-boundary test REMOVED"                         "$CHECKER" "$PATCHDIR/g15.py"
control "g16 PREMISE: checkFunctionOrMethodDeclaration given its body walk" "$CHECKER" "$PATCHDIR/g16.py"
cp "$WORK/last.tags" "$WORK/g16.tags"
control "g17 g16 + the function-boundary report's CODE swapped"          "$CHECKER" "$PATCHDIR/g17.py" "$WORK/g16.tags"
control "g18 the duplicate-label report moved to the STATEMENT"          "$CHECKER" "$PATCHDIR/g18.py"
control "g19 checkLabeledStatement's function-like stop REMOVED"         "$CHECKER" "$PATCHDIR/g19.py"
control "g20 the catch annotation branch given an unconditional TS1196"  "$CHECKER" "$PATCHDIR/g20.py"
control "g21 the redeclaration walk's block-scope test REMOVED"          "$CHECKER" "$PATCHDIR/g21.py"
control "g22 the redeclaration report moved to the CATCH CLAUSE"         "$CHECKER" "$PATCHDIR/g22.py"
control "g23 checkTryStatement's FINALLY walk REMOVED"                   "$CHECKER" "$PATCHDIR/g23.py"
control "g24 checkBreakOrContinueStatement's ambient guard INVERTED"     "$CHECKER" "$PATCHDIR/g24.py"

echo
echo "################################################################"
bold "RESTORED — checker.scaly, byte-identical"
git -C "$REPO" diff --stat -- "$CHECKER" | tail -3
