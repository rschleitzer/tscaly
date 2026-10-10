#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice88.sh — the slice-88 battery: THE BINARY EXPRESSION, and a memo
# that had been argued for eighteen slices and was bought by a red diagcheck.
#
# ★★★ THE SLICE CLOSES THE WORK LIST'S FIRST REACHABLE ROW. `check-binary-
# expression` was 413 events over 142 units at stage 1 — 3 044 units at stage 2 —
# and it is ZERO. It also closes `check-truthiness-of-type`, which slice 63 left
# standing, because the `if`/`do`/`while` condition and the left operand of `&&`
# are the same question and the arm arrives for both at once.
#
# ★★★ THE ROW WAS OPENED AS A HISTOGRAM, which is slice 70's method on the same
# function's caller: record_unported was pointed at the OPERATOR kind for one run,
# and the forty-one operators behind the stop turned out to be one operator —
# **`=` is 245 of the 413 events and 98 of the 142 units.** That is what decided
# the slice's shape: `=` and `,` are the two arms that can ANSWER (both return the
# right operand's type), and the other fourteen groups are behind `booleanType`
# (a union this port cannot mint) or behind the assignability relation.
#
# ★★★ THE SLICE DOES ADD DIAGNOSTICS — six codes, +9 lines on the compared corpus
# and not one line lost — so diagcheck and the DIAGPIN are POSITIVE instruments
# here, unlike slices 85, 86 and 87 where they could only be negative.
#
# ★★★ ITERATE AT STAGE 1 AND CONFIRM AT STAGE 2 ONCE — slice 64's rule. The
# recorded verdicts are stage 1's.
#
# Usage (nothing may edit the tree while this runs, and no second harness may own
# tests/out — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # stage 1, ~25 s
#   packages/tscaly/tests/controls-slice88.sh 2>&1 | tee /tmp/battery88.log
#
set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.2/tscaly/checker.scaly
AST=$PKG/0.1.2/tscaly/ast.scaly
PARSER=$PKG/0.1.2/tscaly/parser.scaly
FIX=$PKG/tests/fixtures

. packages/tscaly/tests/toolchain.sh || exit 2

# ★ ONE MECHANISM PER FILE (slice 72's rule): the tagpin is first-wins, so a fixture
# naming two mechanisms is a fixture nobody can read a red row off.
#
# ★★ THE STOPPIN IS THE INSTRUMENT THAT CARRIES THIS BATTERY, for slice 85's reason
# and one more: a row here typically swaps ONE stop for another inside a single
# unit, which the tagpin (first stop only) and the stopgate (counts over the whole
# corpus) can both miss. The whole log, in order, per fixture, is what separates
# `the arm ran` from `it did not`.
#
# ★★ THE LAST ONE BREAKS THAT RULE ON PURPOSE. `parser_binary_ops.ts` is the
# parser's own operator fixture and it holds FORTY-ONE operators in twenty-eight
# lines — every arm of the switch this slice writes, in one file. Its TAG names one
# of them and its stop LOG names all of them, which is exactly what a row aimed at
# a whole operator GROUP needs, and no per-mechanism fixture can give.
PINFILES="
$FIX/checker_binary_assign_plain.ts
$FIX/checker_binary_assign_invalid_lhs.ts
$FIX/checker_binary_assign_optional_chain.ts
$FIX/checker_binary_comma_unused.ts
$FIX/checker_binary_comma_in_call.ts
$FIX/checker_binary_comma_double_check.ts
$FIX/checker_binary_equality_object_literal.ts
$FIX/checker_binary_nullish_mixed.ts
$FIX/checker_binary_nullish_always.ts
$FIX/checker_binary_nullish_never.ts
$FIX/checker_binary_truthy_always.ts
$FIX/checker_binary_truthy_falsy.ts
$FIX/checker_binary_arithmetic_stop.ts
$FIX/parser_binary_ops.ts
"
red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl88)

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
  "$SCALYC" -c --no-prelude -o "$WORK/pkg.o" "$PKG/0.1.2/tscaly.scaly" > "$WORK/build.log" 2>&1 || return 1
  "$SCALYC" -c -o "$WORK/types.o" "$PKG/0.1.2/tscaly_types.scaly" >> "$WORK/build.log" 2>&1 || return 1
  clang -o "$WORK/tscaly_types" "$WORK/types.o" "$WORK/pkg.o" "$LIBSCALY" -lm >> "$WORK/build.log" 2>&1
}

diags_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$("$WORK/tscaly_types" --diags "$f" 2>/dev/null | tr '\n' '|')"
  done
}

tags_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$("$WORK/tscaly_types" "$f" 2>/dev/null | grep '^UNPORTED ' | head -1 | cut -d' ' -f3-)"
  done
}

stops_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$("$WORK/tscaly_types" --stops "$f" 2>/dev/null | tr '\n' '|')"
  done
}

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
  echo "  the STOPPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.stops"
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
    echo "  diagpin   unmoved — all fourteen pin files answer the same C section."
  else
    green "diagpin   RED"
    diff "$WORK/base.diags" "$WORK/ctl.diags" | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.tags" "$WORK/ctl.tags"; then
    echo "  tagpin    unmoved — all fourteen fixtures answer the same tag."
  else
    green "tagpin    RED"
    diff "$WORK/base.tags" "$WORK/ctl.tags" | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.stops" "$WORK/ctl.stops"; then
    echo "  stoppin   unmoved — all fourteen fixtures log the same stops, in order."
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

python3 - "$PATCHDIR" <<'MKPATCHES'
import os, sys
D = sys.argv[1]
os.makedirs(D, exist_ok=True)

P = {}

P['g01'] = ('''# THE PREMISE — the whole chapter reverted to its stop. PREDICTION: TAGPIN +
# STOPPIN + DIAGPIN RED on every fixture, diagcheck RED at a LOSS is invisible so it
# is UNGATED with a number, and the STOPGATE moves by the whole row.''',
'''old = """        if k = KindBinaryExpression
            return this.check_binary_expression(node, check_mode)"""
new = """        if k = KindBinaryExpression
        {
            this.record_unported("check-binary-expression", k)
            return null
        }"""''')

P['g02'] = ('''# The destructuring fork's RIGHT-operand check removed. PREDICTION: STOPGATE moved
# — the reference evaluates checkExpressionEx(right) as the ARGUMENT to
# checkDestructuringAssignment, so dropping it silences whatever the right side
# would have reached. No pin file is a destructuring assignment, so the pins stay.''',
'''old = """                this.check_expression_ex(right, check_mode)
                this.record_unported("check-destructuring-assignment", lk)"""
new = """                this.record_unported("check-destructuring-assignment", lk)"""''')

P['g03'] = ('''# The LEFT operand check removed. PREDICTION: TAGPIN + STOPPIN RED on most fixtures
# and the STOPGATE moved — the tag of a `x = 1` names check-identifier today and
# would name whatever the RIGHT side reaches instead.''',
'''old = """        let left_type this.check_expression_ex(left, check_mode)
        let right_type this.check_expression_ex(right, check_mode)"""
new = """        let left_type: ref[Type]? null
        let right_type this.check_expression_ex(right, check_mode)"""''')

P['g04'] = ('''# The RIGHT operand check removed, and with it the `=` arm's ANSWER. PREDICTION:
# TAGPIN + STOPPIN + STOPGATE moved on a large scale — the assignment returns nil,
# so check_variable_declaration's tail no longer runs for every `x = e` initializer.''',
'''old = """        let left_type this.check_expression_ex(left, check_mode)
        let right_type this.check_expression_ex(right, check_mode)"""
new = """        let left_type this.check_expression_ex(left, check_mode)
        let right_type: ref[Type]? null"""''')

P['g05'] = ('''# The pre-pass's parent WALK short-circuited — the loop never climbs. PREDICTION:
# STOPGATE moved: the walk decides whether an `||` chain inside an `if` asks
# checkTestingKnownTruthy…, so freezing it at left.Parent.Parent changes how often
# that stop is recorded.''',
'''old = """            while Checker.is_parenthesis_or_logical_chain(parent)
                set parent: AstNode.parent_node_of(parent)"""
new = """            while false
                set parent: AstNode.parent_node_of(parent)"""''')

P['g06'] = ('''# checkTestingKnownTruthyCallableOrAwaitableOrEnumMemberType never asked.
# PREDICTION: TAGPIN + STOPPIN RED on both truthiness fixtures — their first stop IS
# that tag — and the STOPGATE moved.''',
'''old = """            var ask_known_truthy false
            if op_kind = KindAmpersandAmpersandToken
                set ask_known_truthy: true"""
new = """            var ask_known_truthy false
            if false
                set ask_known_truthy: true"""''')

P['g07'] = ('''# is_logical_binary_operator swapped for the COALESCING question, so `??` also
# checks its left operand for truthiness. PREDICTION: diagcheck RED — an INVENTION.
# `null ?? 1` would report TS2873 (*always falsy*) where the reference reports only
# TS2871. It is the row that says the two predicates cannot be one.''',
'''old = """            if Binder.is_logical_binary_operator(op_kind)
            {"""
new = """            if Binder.is_logical_or_coalescing_binary_operator(op_kind)
            {"""''')

P['g08'] = ('''# checkTruthinessOfType's VOID test removed. PREDICTION: UNGATED — no pin file and
# no corpus unit reaches this arm with a void-typed left operand, because the only
# expressions this port types here are literals. The row names what a fixture would
# have to hold.''',
'''old = """        if (t.flags & TypeFlagsVoid) <> 0
        {
            this.error_on_node(node, DiagAn_expression_of_type_void_cannot_be_tested_for_truthiness)"""
new = """        if false
        {
            this.error_on_node(node, DiagAn_expression_of_type_void_cannot_be_tested_for_truthiness)"""''')

P['g09'] = ('''# getSyntacticTruthySemantics' `0`/`1` exemption dropped. PREDICTION: diagcheck RED
# — an INVENTION. The reference's own comment is *"Allow while(0) or while(1)"*, and
# parser_binary_ops.ts holds `const logic = 1 && 2 || 3 ?? 4;`, whose left operand is
# the literal 1.''',
'''old = """            if Checker.node_text_is(d, len, "0", 1)
                return PredicateSemanticsSometimes
            if Checker.node_text_is(d, len, "1", 1)
                return PredicateSemanticsSometimes"""
new = """"""''')

P['g10'] = ('''# The empty-string test INVERTED. PREDICTION: DIAGPIN RED on both truthiness
# fixtures and in OPPOSITE directions — `"a" && 1` would report always-FALSY and
# `"" && 1` always-TRUTHY. diagcheck RED too, because one of the two is an
# invention whichever way round it lands.''',
'''old = """            if AstNode.literal_text_length_of(n) <> 0
                return PredicateSemanticsAlways
            return PredicateSemanticsNever"""
new = """            if AstNode.literal_text_length_of(n) = 0
                return PredicateSemanticsAlways
            return PredicateSemanticsNever"""''')

P['g11'] = ('''# The `undefined` identifier stop removed from the truthiness walk. PREDICTION:
# UNGATED, and a PROOF — the row is ZERO at stage 1, so no unit of this corpus puts
# a bare `undefined` on the left of a `&&` or `||`. It is the row that says the one
# lookup this walk cannot make is not being made.''',
'''old = """                this.record_unported("get-resolved-symbol-undefined", k)
        }
        PredicateSemanticsSometimes"""
new = """                set k: k
        }
        PredicateSemanticsSometimes"""''')

P['g12'] = ('''# The arithmetic group's silentNever short-circuit forced TAKEN. PREDICTION:
# TAGPIN + STOPPIN RED on checker_binary_arithmetic_stop and the STOPGATE moved —
# every arithmetic operator would answer silentNeverType instead of reaching
# check-non-null-type.''',
'''old = """            if Checker.either_is(left_type, right_type, silent_never_type)
                return silent_never_type
            this.record_unported("check-non-null-type", op_kind)"""
new = """            if true
                return silent_never_type
            this.record_unported("check-non-null-type", op_kind)"""''')

P['g13'] = ('''# is_arithmetic_or_bitwise_operator answers FALSE, so its twenty-two operators fall
# through to the switch's default. PREDICTION: TAGPIN + STOPPIN RED — the tag
# becomes `check-binary-like-expression-unhandled`, which is the reference's PANIC
# and this port's unreachability claim. It is the row that says the group is
# reached at all.''',
'''old = """        if Checker.is_arithmetic_or_bitwise_operator(op_kind)"""
new = """        if false"""''')

P['g14'] = ('''# checkForDisallowedESSymbolOperand forced to report on every relational operator.
# PREDICTION: diagcheck RED — TS2469 invented on `1 < 2` and its neighbours in
# parser_binary_ops.ts. It is the only evidence this suite can give that the
# function is called at all, its true answer being silence.''',
'''old = """            if this.check_for_disallowed_es_symbol_operand(left, right, left_type, right_type, op_kind)
                this.record_unported("check-non-null-type", op_kind)
            else"""
new = """            this.error_on_node(left, DiagThe_0_operator_cannot_be_applied_to_type_symbol)
            if false
                this.record_unported("check-non-null-type", op_kind)
            else"""''')

P['g15'] = ('''# The equality arm's TS2839 report removed. PREDICTION: DIAGPIN RED on
# checker_binary_equality_object_literal at a LOSS, diagcheck UNGATED — which is the
# pair slice 73 named: a subsequence breaks on what you INVENT and stays green on
# what you LOSE, so the pin is the only instrument that sees this row.''',
'''old = """                    if report
                        this.error_on_node_or_null(error_node, DiagThis_condition_will_always_return_0_since_JavaScript_compares_objects_by_reference_not_value)"""
new = """                    if false
                        this.error_on_node_or_null(error_node, DiagThis_condition_will_always_return_0_since_JavaScript_compares_objects_by_reference_not_value)"""''')

P['g16'] = ('''# The CheckModeTypeOnly gate forced CLOSED, i.e. the equality block's three steps
# skipped while the row below them still runs. PREDICTION: DIAGPIN RED (the same
# loss as g15, plus TS2839) and diagcheck ungated — g15 confined to one report,
# this one to the whole gate, and the pair says the gate is OPEN under Normal,
# which is all this port passes.
#
# ★★★ ITS FIRST RUN WAS A FINDING AND IT CHANGED THE SOURCE. With the stop recorded
# INSIDE the gate, closing the gate made the arm answer nil with NO stop, and one
# unit of parser_binary_ops.ts then INVENTED a TS7005 — diagcheck RED where the
# patch could only LOSE. The row is what moved that `record_unported` outside the
# gate; see the arm's own note.''',
'''old = """            if (check_mode & CheckModeTypeOnly) = 0
            {"""
new = """            if false
            {"""''')

P['g17'] = ('''# checkNaNEquality's isGlobalNaN forced TRUE on both operands. PREDICTION: UNGATED,
# and a PROOF that the function is inert here: with no globals table there is
# nothing for the report to be built from, so both branches of the ported shape
# return and no C line can appear whatever the predicate answers.''',
'''old = """        if this.is_global_na_n(left)
            return
        if this.is_global_na_n(right)
            return"""
new = """        if true
            return
        if true
            return"""''')

P['g18'] = ('''# The `??` arm's checkNullishCoalesceOperands removed. PREDICTION: DIAGPIN RED on
# THREE fixtures at a LOSS (mixed, always, never) and diagcheck ungated. It is the
# largest single-row diagnostic loss in this battery.''',
'''old = """            if op_kind = KindQuestionQuestionToken
                this.check_nullish_coalesce_operands(left, right)"""
new = """            if false
                this.check_nullish_coalesce_operands(left, right)"""''')

P['g19'] = ('''# checkNullishCoalesceOperandLeft removed, i.e. the MIXING report kept and the
# operand's own nullishness dropped. PREDICTION: DIAGPIN RED on the two nullish
# fixtures and NOT on checker_binary_nullish_mixed — g18 split in half, which is
# what says the two reports are two mechanisms.''',
'''old = """        this.check_nullish_coalesce_operand_left(left)"""
new = """"""''')

P['g20'] = ('''# getSyntacticNullishnessSemantics' DEFAULT changed from Never to Sometimes.
# PREDICTION: DIAGPIN RED on checker_binary_nullish_never at a LOSS — TS2869 comes
# from the DEFAULT arm and from nowhere else, which is why the reference's asymmetry
# with the truthiness walk (whose default is Sometimes) is transcribed rather than
# normalised.''',
'''old = """        PredicateSemanticsNever
    }

    ; The nine kinds of the first `case` label"""
new = """        PredicateSemanticsSometimes
    }

    ; The nine kinds of the first `case` label"""''')

P['g21'] = ('''# The three logical COMPOUND assignments no longer run checkAssignmentOperator.
# PREDICTION: STOPGATE moved — parser_binary_ops.ts holds `x &&= 1`, `x ||= 1` and
# `x ??= 1`, each of which reaches check-type-assignable-to through that call and
# would stop at has-type-facts alone instead.''',
'''old = """            if Binder.is_logical_or_coalescing_assignment_operator(op_kind)
                this.check_assignment_operator(left, op_kind, right, left_type, right_type)"""
new = """"""''')

P['g22'] = ('''# checkReferenceExpression's reference-like test forced TRUE. PREDICTION: DIAGPIN
# RED on checker_binary_assign_invalid_lhs at a LOSS — TS2364 is the arm's first
# report and `f() = 1` is the only shape in the pin set that reaches it.''',
'''old = """        if reference_like = false
        {
            this.error_on_node(expr, invalid_reference_code)
            return false
        }"""
new = """        if false
        {
            this.error_on_node(expr, invalid_reference_code)
            return false
        }"""''')

P['g23'] = ('''# checkReferenceExpression's optional-chain test removed. PREDICTION: DIAGPIN RED on
# checker_binary_assign_optional_chain at a LOSS — TS2779, the arm's second report,
# and the complement of g22.''',
'''old = """        if (AstNode.flags_of(n) & NodeFlagsOptionalChain) <> 0
        {
            this.error_on_node(expr, invalid_optional_chain_code)
            return false
        }"""
new = """        if false
        {
            this.error_on_node(expr, invalid_optional_chain_code)
            return false
        }"""''')

P['g24'] = ('''# The CommonJS exports-property guard asked in the REFERENCE'S OWN ORDER, i.e.
# without the rightType test in front of it. PREDICTION: STOPGATE moved by exactly
# the difference the reordering bought — 6 events over 5 units back up to 25 over 15.
# It is the row that prices asking an ASKABLE conjunct before an unaskable one.''',
'''old = """                    var may_skip false
                    if right_type = null
                        set may_skip: true"""
new = """                    var may_skip true
                    if right_type = null
                        set may_skip: true"""''')

P['g25'] = ('''# The comma arm's isSideEffectFree forced FALSE. PREDICTION: DIAGPIN RED on
# checker_binary_comma_unused at a LOSS — every TS2695 goes, which is ten of the
# corpus lines this slice adds.''',
'''old = """        if this.is_side_effect_free(left) = false
            return
        if Checker.is_indirect_call(AstNode.parent_node_of(left))
            return"""
new = """        if true
            return
        if Checker.is_indirect_call(AstNode.parent_node_of(left))
            return"""''')

P['g26'] = ('''# isIndirectCall forced TRUE. PREDICTION: UNGATED, and it is a FINDING rather than a
# gap: the exemption's whole shape is `(0, x.f)(...)`, and a comma inside a call is
# never checked by this port at all — the CallExpression arm of the dispatch stops
# first. checker_binary_comma_in_call.ts is that claim as a file, and this row is
# the claim as a measurement.''',
'''old = """        if Checker.is_indirect_call(AstNode.parent_node_of(left))
            return"""
new = """        if true
            return"""''')

P['g29'] = ('''# isIndirectCall forced FALSE, i.e. the exemption dropped rather than forced.
# PREDICTION: UNGATED — this is the claim g26 cannot make. `(0, x.f)(...)` is an
# ExpressionStatement whose expression is a CallExpression, and the dispatch stops
# at check-call-expression before the comma inside it is ever checked, so the
# exemption has no reachable trigger in this corpus. checker_binary_comma_in_call.ts
# is the same claim as a file, with the reference reporting a TS2695 this port does
# not.''',
'''old = """        if Checker.is_indirect_call(AstNode.parent_node_of(left))
            return"""
new = """        if false
            return"""''')

P['g30'] = ('''# ★★★ THE MEMO'S SECOND HALF REMOVED — the `expression_resolved` bit dropped, so a
# nil is not cached again. PREDICTION: diagcheck RED — a DUPLICATE TS2695 on
# checker_binary_comma_double_check.ts, whose initializer STOPS (the comma's right
# operand is an identifier) and whose variable has two declarations. g28 is the same
# failure for a node that ANSWERS; this one is for a node that stopped, and it is the
# half that only stage 2 found.''',
'''old = """            if links.expression_resolved = false
            {
                let mark this.unported_mark()"""
new = """            if true
            {
                let mark this.unported_mark()"""''')

P['g31'] = ('''# ★★★ THE MARK REPLAY REMOVED — a cached stop no longer moves `unported_mark`.
# PREDICTION: diagcheck RED — an INVENTED TS7005 on
# checker_binary_comma_double_check.ts, because
# get_widened_type_for_variable_like_declaration's incompleteness guard is a mark
# DELTA, and a memoised nil that does not move it reads as *nothing stopped*. It is
# the row for slice 88's second correction: a memo that caches an INCOMPLETE answer
# must cache its INCOMPLETENESS too.''',
'''old = """                if links.expression_stopped
                    this.replay_stop_mark()"""
new = """                if false
                    this.replay_stop_mark()"""''')

P['g27'] = ('''# The TS2657 overlap test dropped. PREDICTION: diagcheck RED — an INVENTION on the
# JSX units where `<a/> <b/>` parses as a comma expression the reference has already
# reported on. It is the reason that test is in the port at all.''',
'''old = """        if this.position_is_in_jsx_parent_diagnostic(start)
            return"""
new = """        if false
            return"""''')

P['g28'] = ('''# ★★★ THE MEMO REMOVED — checkExpressionCachedEx back to the pass-through it was for
# eighteen slices. PREDICTION: diagcheck RED — a DUPLICATE TS2695 per comma on
# checker_binary_comma_unused, because check_variable_declaration checks the
# initializer once through getTypeOfSymbol and once in its own tail. It is the row
# that holds this slice's first finding, and the only reason the memo exists.''',
'''old = """        let links this.type_node_link_of(node)
        if links.resolved_type = null"""
new = """        return this.check_expression_ex(node, check_mode)
        let links this.type_node_link_of(node)
        if links.resolved_type = null"""''')

for k, (pred, body) in sorted(P.items()):
    src = "import sys\np = sys.argv[1]; s = open(p).read()\n" + pred + "\n" + body + """
if old not in s:
    sys.exit(1)
if old == "":
    sys.exit(1)
s = s.replace(old, new, 1)
open(p, 'w').write(s)
"""
    open(os.path.join(D, k + '.py'), 'w').write(src)
print("wrote", len(P))
MKPATCHES

baseline

control "g01 the whole chapter reverted to its stop (the premise)" $CHECKER "$PATCHDIR/g01.py"
control "g02 the destructuring fork's right-operand check removed" $CHECKER "$PATCHDIR/g02.py"
control "g03 the LEFT operand check removed" $CHECKER "$PATCHDIR/g03.py"
control "g04 the RIGHT operand check removed" $CHECKER "$PATCHDIR/g04.py"
control "g05 the pre-pass's parent walk short-circuited" $CHECKER "$PATCHDIR/g05.py"
control "g06 checkTestingKnownTruthy... never asked" $CHECKER "$PATCHDIR/g06.py"
control "g07 is_logical_binary_operator swapped for the coalescing one" $CHECKER "$PATCHDIR/g07.py"
control "g08 checkTruthinessOfType's void test removed" $CHECKER "$PATCHDIR/g08.py"
control "g09 getSyntacticTruthySemantics' 0/1 exemption dropped" $CHECKER "$PATCHDIR/g09.py"
control "g10 the empty-string test inverted" $CHECKER "$PATCHDIR/g10.py"
control "g11 the truthiness walk's undefined stop removed" $CHECKER "$PATCHDIR/g11.py"
control "g12 the arithmetic silentNever short-circuit forced taken" $CHECKER "$PATCHDIR/g12.py"
control "g13 is_arithmetic_or_bitwise_operator answers false" $CHECKER "$PATCHDIR/g13.py"
control "g14 checkForDisallowedESSymbolOperand forced to report" $CHECKER "$PATCHDIR/g14.py"
control "g15 the equality arm's TS2839 report removed" $CHECKER "$PATCHDIR/g15.py"
control "g16 the CheckModeTypeOnly gate forced closed" $CHECKER "$PATCHDIR/g16.py"
control "g17 checkNaNEquality's isGlobalNaN forced true" $CHECKER "$PATCHDIR/g17.py"
control "g18 the ?? arm's checkNullishCoalesceOperands removed" $CHECKER "$PATCHDIR/g18.py"
control "g19 checkNullishCoalesceOperandLeft removed" $CHECKER "$PATCHDIR/g19.py"
control "g20 getSyntacticNullishnessSemantics' default changed to Sometimes" $CHECKER "$PATCHDIR/g20.py"
control "g21 the logical compounds no longer run checkAssignmentOperator" $CHECKER "$PATCHDIR/g21.py"
control "g22 checkReferenceExpression's reference-like test forced true" $CHECKER "$PATCHDIR/g22.py"
control "g23 checkReferenceExpression's optional-chain test removed" $CHECKER "$PATCHDIR/g23.py"
control "g24 the CommonJS guard asked in the reference's own order" $CHECKER "$PATCHDIR/g24.py"
control "g25 the comma arm's isSideEffectFree forced false" $CHECKER "$PATCHDIR/g25.py"
control "g26 isIndirectCall forced true" $CHECKER "$PATCHDIR/g26.py"
control "g27 the TS2657 overlap test dropped" $CHECKER "$PATCHDIR/g27.py"
control "g28 the MEMO removed" $CHECKER "$PATCHDIR/g28.py"
control "g29 isIndirectCall forced false" $CHECKER "$PATCHDIR/g29.py"
control "g30 the MEMO's second half removed (the nil bit)" $CHECKER "$PATCHDIR/g30.py"
control "g31 the mark REPLAY removed" $CHECKER "$PATCHDIR/g31.py"

echo
echo "################################################################"
bold "DONE — read every row against its PREDICTION, not against its colour."
