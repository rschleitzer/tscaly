#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice90.sh — the slice-90 battery: THE TYPE FACTS, which is a JOINT and
# not a chapter.
#
# ★★★ FIVE ARMS OF THREE CHAPTERS WERE STANDING AT ONE CALL. resolveCallExpression
# and resolveNewExpression stopped at `checkNonNullType` on their second line, the
# arithmetic and the relational operators stopped at it inside their own switch
# arms, and the three logical operators stopped at `hasTypeFacts`. The battery is
# therefore laid out by CALLER and not by arm: every row names which of the five it
# moves, because a row that moves all five is measuring the joint and not the claim.
#
# ★★★ MOST OF THE TABLE IS WRITE-ONLY AND THE BATTERY SAYS SO RATHER THAN HIDING
# IT. getTypeFactsWorker returns forty of the forty-two combination constants and
# exactly TWO bits are ever inspected in this slice — IsUndefinedOrNull, by
# checkNonNullType, and whichever of Truthy/Falsy/EQUndefinedOrNull the logical
# operator asks. h24 and h26 corrupt a member with no reader and are UNGATED BY
# CONSTRUCTION; h25 corrupts the one that has three readers and is red on two
# instruments. **The pair is the measurement of how much of this table the corpus
# can see, and it is the honest answer to §3.5be.**
#
# ★★★ WHAT THE RUN SAID, AND FOUR PREDICTIONS WERE WRONG. h04 and h05 (the
# string-literal and number-literal value tests forced TRUE) were predicted UNGATED
# because no CHECKER fixture has a literal left operand of a logical operator —
# and both are real gates, on `parser_binary_ops.ts`, the forty-one-operator PARSER
# fixture kept in the pin set for exactly the reason its own note gives.
# **A prediction of the form *no unit does X* has to be made against the pin SET,
# not against the fixtures the slice wrote.** h13 was predicted DIAGPIN-unmoved and
# is DIAGPIN RED: the prediction was written against an EARLIER draft of this slice,
# before the reporter's null-keyword arm existed, and it went stale inside the same
# afternoon. And h07 is the sharp one — see below.
#
# ★★★ h07 IS A CONTROL THE STOPPIN CANNOT SEE, AND IT IS SLICE 88's FINDING FOUR
# ONE SLICE LATER IN THE INSTRUMENT ITSELF. Forcing every logical spelling to ask
# Truthy does not remove a stop from `checker_logical_left_answer.ts` — it SWAPS
# which operand stops: `true || 1` starts stopping and `null || 1` stops stopping,
# and both log `get-union-type 56`. The log records a TAG and an operator KIND and
# no position, so a swap is invisible to it. The STOPGATE saw it (two units' first
# stop moved) and the STOPPIN did not. **An instrument that folds away position
# cannot refute a claim about position.**
#
# ★★★ ITERATE AT STAGE 1 AND CONFIRM AT STAGE 2 ONCE — slice 64's rule. The
# recorded verdicts are stage 1's.
#
# Usage (nothing may edit the tree while this runs, and no second harness may own
# tests/out — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # stage 1
#   packages/tscaly/tests/controls-slice90.sh 2>&1 | tee /tmp/battery90.log
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

# ★ ONE MECHANISM PER FILE (slice 72's rule), with two files that break it on
# purpose: `checker_call_callee_literal.ts` is slice 89's, kept because it is the
# only pin file whose call has a LITERAL callee and therefore the only one whose
# call reaches getApparentType, and `parser_binary_ops.ts` is the forty-one-operator
# file, kept because most of this battery's rows move a STOP rather than a
# diagnostic and the STOPPIN is what reads that.
PINFILES="
$FIX/checker_binary_boolean_suggestion.ts
$FIX/checker_logical_left_answer.ts
$FIX/checker_call_possibly_null_callee.ts
$FIX/checker_binary_null_operand.ts
$FIX/checker_call_callee_literal.ts
$FIX/parser_binary_ops.ts
"
red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl90)

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
    echo "  diagpin   unmoved — all six pin files answer the same C section."
  else
    green "diagpin   RED"
    diff "$WORK/base.diags" "$WORK/ctl.diags" | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.tags" "$WORK/ctl.tags"; then
    echo "  tagpin    unmoved — all six fixtures answer the same tag."
  else
    green "tagpin    RED"
    diff "$WORK/base.tags" "$WORK/ctl.tags" | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.stops" "$WORK/ctl.stops"; then
    echo "  stoppin   unmoved — all six fixtures log the same stops, in order."
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

P['h01'] = ('''# THE PREMISE — getTypeFactsWorker reverted to a row at its first line, which is
# what every one of the five callers met before this slice. PREDICTION: DIAGPIN RED
# on all three reporting fixtures, TAGPIN + STOPPIN RED, and the STOPGATE moved by
# the whole joint.''',
'''old = """    function get_type_facts_worker(this, t: ref[Type], caller_only_needs: int) returns int
    {
        var base: ref[Type]? t"""
new = """    function get_type_facts_worker(this, t: ref[Type], caller_only_needs: int) returns int
    {
        this.record_unported("ctl-type-facts-reverted", t.flags)
        return TypeFactsNone
        var base: ref[Type]? t"""''')

P['h02'] = ('''# The OBJECT arm's EARLY-OUT never taken — every object type falls through to the
# members wall. PREDICTION: UNGATED. Nothing in this corpus hands an OBJECT type to
# any of the five callers; the arm is transcribed because it is what makes the
# object case answerable at all for the two masks that skip it, not because a unit
# takes it today.''',
'''old = """            if (caller_only_needs & possible) = 0
                return TypeFactsNone"""
new = """            if false
                return TypeFactsNone"""''')

P['h03'] = ('''# The object arm's early-out ALWAYS taken — the members wall unreachable.
# h02's complement, and the half that says the two are a pair rather than one
# assertion. PREDICTION: UNGATED, for h02's reason.''',
'''old = """            if (caller_only_needs & possible) = 0
                return TypeFactsNone"""
new = """            if true
                return TypeFactsNone"""''')

P['h04'] = ('''# The string-literal EMPTY test forced TRUE — every string literal answers
# EmptyString*Facts. PREDICTION: UNGATED. The two members differ in Truthy alone,
# and no logical operator in this corpus has a string-literal left operand; the
# two string-literal arrivals measured before this slice were both arithmetic,
# where only IsUndefinedOrNull is read.''',
'''old = """            var is_empty false
            if (flags & TypeFlagsStringLiteral) <> 0
            {
                if Checker.literal_text_length_of(ty) = 0
                    set is_empty: true
            }"""
new = """            var is_empty true"""''')

P['h05'] = ('''# The number-literal ZERO test forced TRUE. PREDICTION: UNGATED, for h04's reason
# one arm down — Zero and NonZero differ in Truthy/Falsy and the seventy-seven
# arithmetic arrivals read neither.''',
'''old = """            var is_zero false
            if Checker.literal_bits_of(ty) = 0 as u64
                set is_zero: true
            if Checker.literal_bits_of(ty) = 0x8000000000000000
                set is_zero: true"""
new = """            var is_zero true"""''')

P['h06'] = ('''# The boolean-literal FALSE identity test forced TRUE — trueType answers
# FalseStrictFacts. PREDICTION: STOPPIN RED on checker_logical_left_answer:
# `true || 1` asks Falsy, which FalseStrictFacts HAS and TrueStrictFacts does not,
# so the operator stops at getUnionType instead of answering trueType.''',
'''old = """            var is_false false
            if ty = false_type
                set is_false: true
            if ty = regular_false_type
                set is_false: true"""
new = """            var is_false true"""''')

P['h07'] = ('''# logical_operator_fact answers Truthy for all six spellings. PREDICTION: STOPPIN
# RED — `null ?? 1` and `null || 1` ask Truthy of nullType, which does not have it,
# so both ANSWER nullType instead of stopping at getUnionType. The row that says
# the three facts are not interchangeable.''',
'''old = """        if k = KindBarBarToken
            return TypeFactsFalsy
        if k = KindBarBarEqualsToken
            return TypeFactsFalsy
        TypeFactsEQUndefinedOrNull"""
new = """        if k = KindBarBarToken
            return TypeFactsTruthy
        if k = KindBarBarEqualsToken
            return TypeFactsTruthy
        TypeFactsTruthy"""''')

P['h08'] = ('''# logical_operator_fact answers Falsy for all six. h07's complement in the other
# direction: `false && 1` and `1 ?? 2` now ask Falsy, which falseType HAS and a
# non-zero number literal does not — so `&&` stops where it answered.
# PREDICTION: STOPPIN RED, and on a DIFFERENT fixture line than h07.''',
'''old = """        if k = KindAmpersandAmpersandToken
            return TypeFactsTruthy
        if k = KindAmpersandAmpersandEqualsToken
            return TypeFactsTruthy"""
new = """        if k = KindAmpersandAmpersandToken
            return TypeFactsFalsy
        if k = KindAmpersandAmpersandEqualsToken
            return TypeFactsFalsy"""''')

P['h09'] = ('''# The MASK dropped from get_type_facts — the worker's raw answer is handed back.
# PREDICTION: STOPPIN RED and the STOPGATE moved by a lot. checkNonNullType is
# unaffected (it ANDs again with IsUndefinedOrNull), but hasTypeFacts asks `<> 0`,
# and an unmasked answer is nonzero for every type — so all six logical spellings
# take the union row and every unit that this slice made answer stops again.
# **That is the row that says the mask is the question and not a filter.**''',
'''old = """    function get_type_facts(this, t: ref[Type], mask: int) returns int
        this.get_type_facts_worker(t, mask) & mask"""
new = """    function get_type_facts(this, t: ref[Type], mask: int) returns int
        this.get_type_facts_worker(t, mask)"""''')

P['h10'] = ('''# getSuggestedBooleanOperator always answers KindUnknown. PREDICTION: DIAGPIN RED
# — the three TS2447 of checker_binary_boolean_suggestion go, and diagcheck stays
# ungated because a subsequence breaks on what you INVENT and not on what you LOSE.''',
'''old = """        if k = KindBarToken
            return KindBarBarToken"""
new = """        if true
            return KindUnknown
        if k = KindBarToken
            return KindBarBarToken"""''')

P['h11'] = ('''# The RIGHT operand's BooleanLike test dropped from the arithmetic arm.
# PREDICTION: UNGATED. Every boolean-operand pair in this corpus has BOTH sides
# boolean; the conjunct is transcribed because the reference has it, and the row
# says the corpus cannot tell the two readings apart (§3.5v's *indistinguishable*).''',
'''old = """                        if (rtb.flags & TypeFlagsBooleanLike) <> 0
                        {
                            let suggested Checker.get_suggested_boolean_operator(op_kind)"""
new = """                        if true
                        {
                            let suggested Checker.get_suggested_boolean_operator(op_kind)"""''')

P['h12'] = ('''# The arithmetic arm's two checkNonNullType calls removed — the operands are used
# raw. PREDICTION: DIAGPIN + STOPPIN RED on checker_binary_null_operand: `null * 1`
# loses its stop at the reporter and falls through to check-arithmetic-operand-type.
# The row that says the call is where a nullable operand is caught, not the arm.''',
'''old = """                    let lt this.check_non_null_type(left_type as ref[Type], left)
                    if lt = null
                        return null
                    let rt this.check_non_null_type(right_type as ref[Type], right)
                    if rt = null
                        return null
                    ; "if a user tries to apply a bitwise operator to 2 boolean"""
new = """                    let lt left_type
                    let rt right_type
                    ; "if a user tries to apply a bitwise operator to 2 boolean"""''')

P['h13'] = ('''# The RELATIONAL arm's two checkNonNullType calls removed. PREDICTION: STOPPIN RED
# on checker_binary_null_operand's second statement — `null < 1` stops at
# get-base-type-of-literal-type-for-comparison rather than at the reporter. The
# DIAGPIN does not move, because the report it loses is one this port cannot make
# on that path anyway.''',
'''old = """                        let lt this.check_non_null_type(left_type as ref[Type], left)
                        if lt = null
                            return null
                        let rt this.check_non_null_type(right_type as ref[Type], right)
                        if rt = null
                            return null"""
new = """                        let lt left_type
                        let rt right_type"""''')

P['h14'] = ('''# reportObjectPossiblyNullOrUndefinedError's null-keyword arm never taken — the
# whole reporter back to one row. PREDICTION: DIAGPIN RED — the two TS18050 of
# checker_binary_null_operand and the one of `new null()` go — and STOPPIN RED,
# because the tag flips from get-non-nullable-type to
# report-object-possibly-null-or-undefined. **This is the row that was measured
# BEFORE it was written: all three reports were being lost silently.**''',
'''old = """        if AstNode.kind_of(node) = KindNullKeyword
        {
            this.error_on_node(node, DiagThe_value_0_cannot_be_used_here)
            return true
        }
        false"""
new = """        false"""''')

P['h15'] = ('''# The reporter FLAG forced TRUE — both call sites report cannot-invoke.
# PREDICTION: diagcheck RED *by INVENTION*: `null * 1` and `null < 1` would report
# TS2721/TS2722 where the reference has TS18050, at spans the reference's list does
# not carry those codes at. The half of the flag that says it is a flag.''',
'''old = """            var reported false
            if report_cannot_invoke"""
new = """            var reported false
            if true"""''')

P['h16'] = ('''# The reporter flag forced FALSE — the CALL site takes the object reporter.
# PREDICTION: diagcheck RED *by INVENTION* — `null()` answers TS18050 where the
# reference has TS2721. h15's complement, and together they are why §3.5e's flag is
# a flag here rather than a comment.''',
'''old = """            var reported false
            if report_cannot_invoke"""
new = """            var reported false
            if false"""''')

P['h17'] = ('''# TypeFactsNullFacts loses IsNull. PREDICTION: DIAGPIN + STOPPIN RED — nullType is
# no longer nullable, so `null()` loses TS2721 and every `null` operand walks past
# checkNonNullType. The ONE member of the forty-two-row table with a live reader.''',
'''old = """define TypeFactsNullFacts: int TypeFactsTypeofEQObject | TypeFactsTypeofNEString | TypeFactsTypeofNENumber | TypeFactsTypeofNEBigInt | TypeFactsTypeofNEBoolean | TypeFactsTypeofNESymbol | TypeFactsTypeofNEFunction | TypeFactsTypeofNEHostObject | TypeFactsEQNull | TypeFactsEQUndefinedOrNull | TypeFactsNEUndefined | TypeFactsFalsy | TypeFactsIsNull"""
new = """define TypeFactsNullFacts: int TypeFactsTypeofEQObject | TypeFactsTypeofNEString | TypeFactsTypeofNENumber | TypeFactsTypeofNEBigInt | TypeFactsTypeofNEBoolean | TypeFactsTypeofNESymbol | TypeFactsTypeofNEFunction | TypeFactsTypeofNEHostObject | TypeFactsEQNull | TypeFactsEQUndefinedOrNull | TypeFactsNEUndefined | TypeFactsFalsy"""''')

P['h18'] = ('''# TypeFactsUndefinedFacts loses IsUndefined — h17's twin one line up.
# PREDICTION: UNGATED. Nothing in this port answers undefinedType from an
# EXPRESSION: `undefined` is an identifier and stops at check-identifier, and the
# `undefined` type NODE is only reachable from an annotation. The pair h17/h18 is
# what says the table is read for exactly one of its two nullable members.''',
'''old = """ | TypeFactsNENull | TypeFactsFalsy | TypeFactsIsUndefined"""
new = """ | TypeFactsNENull | TypeFactsFalsy"""''')

P['h19'] = ('''# TypeFactsAndFactsMask corrupted to TypeFactsAll — one of the four members whose
# transcription needed the `xor` form. PREDICTION: UNGATED BY CONSTRUCTION: its
# only reader upstream is getIntersectionTypeFacts, which is a row here. It is in
# the battery so that the claim *this member has no reader* is a measurement rather
# than a reading of the code (§3.5be).''',
'''old = """define TypeFactsAndFactsMask: int TypeFactsAll xor TypeFactsTypeofEQFunction xor TypeFactsTypeofNEObject"""
new = """define TypeFactsAndFactsMask: int TypeFactsAll"""''')

P['h20'] = ('''# TypeFactsEmptyObjectStrictFacts corrupted to TypeFactsNone — the member that
# decides whether `&&` and `||` reach the object wall where `??` does not.
# PREDICTION: UNGATED at stage 1, because no object type reaches any of the five
# callers; the row exists so that h02/h03's UNGATED has a THIRD reading of the same
# fact and cannot be mistaken for a broken patch.''',
'''old = """define TypeFactsEmptyObjectStrictFacts: int TypeFactsAll xor TypeFactsEQUndefined xor TypeFactsEQNull xor TypeFactsEQUndefinedOrNull xor TypeFactsIsUndefined xor TypeFactsIsNull"""
new = """define TypeFactsEmptyObjectStrictFacts: int TypeFactsNone"""''')

P['h21'] = ('''# The Intersection/Instantiable HEAD removed — no base-constraint substitution.
# PREDICTION: UNGATED. A type parameter reaching one of these five callers would
# have to come from an expression this port types, and it does not; the head is
# transcribed because getApparentType's own head is, one chapter over, and the two
# must agree the day either becomes reachable.''',
'''old = """        if (t.flags & (TypeFlagsIntersection | TypeFlagsInstantiable)) <> 0
        {
            let mark this.unported_mark()
            let constraint this.get_base_constraint_of_type(t)"""
new = """        if false
        {
            let mark this.unported_mark()
            let constraint this.get_base_constraint_of_type(t)"""''')

P['h22'] = ('''# The `unknown` row removed — an unknown-typed expression falls through to the
# facts instead of stopping. PREDICTION: UNGATED. Nothing here answers unknownType
# from an expression, which is what the note at that line has claimed since slice
# 89 and what this row measures rather than repeats.''',
'''old = """                this.record_unported("object-is-of-type-unknown", AstNode.kind_of(node))
                return null"""
new = """                let ignored 0"""''')

P['h23'] = ('''# resolveCallExpression's getApparentType call removed — a row in its place, so the
# rest of the function is not walked into a hole. PREDICTION: STOPPIN RED on
# checker_call_callee_literal: the call now stops one line EARLIER than the globals
# table it reaches today. The row that says slice 90 moved the call chapter's wall
# rather than only its report.''',
'''old = """        let apparent this.get_apparent_type(fnt)
        if apparent = null
            return null
        let at apparent as ref[Type]
        if this.is_error_type(at)
        {
            ; resolveErrorCall"""
new = """        this.record_unported("ctl-apparent-type-removed", KindCallExpression)
        return null
        let apparent this.get_apparent_type(fnt)
        if apparent = null
            return null
        let at apparent as ref[Type]
        if this.is_error_type(at)
        {
            ; resolveErrorCall"""''')

P['h24'] = ('''# The MARK check dropped around has_type_facts in the logical arm — a stop
# underneath read as an ANSWER. PREDICTION: UNGATED at stage 1: the only way the
# worker stops is the object members wall, and no object operand reaches it here.
# The guard is written because a nil answered as FALSE is the lenient direction,
# which is the class slice 88 and slice 89 spent two findings on.''',
'''old = """                let asked this.has_type_facts(left_type as ref[Type], fact)
                if this.unported_mark() <> mark
                    set result: null
                else
                {"""
new = """                let asked this.has_type_facts(left_type as ref[Type], fact)
                if false
                    set result: null
                else
                {"""''')

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

control "h01 THE PREMISE — getTypeFactsWorker reverted to a row" $CHECKER "$PATCHDIR/h01.py"
control "h02 the object arm's early-out NEVER taken" $CHECKER "$PATCHDIR/h02.py"
control "h03 the object arm's early-out ALWAYS taken" $CHECKER "$PATCHDIR/h03.py"
control "h04 the string-literal EMPTY test forced TRUE" $CHECKER "$PATCHDIR/h04.py"
control "h05 the number-literal ZERO test forced TRUE" $CHECKER "$PATCHDIR/h05.py"
control "h06 the boolean-literal FALSE identity forced TRUE" $CHECKER "$PATCHDIR/h06.py"
control "h07 logical_operator_fact answers Truthy for all six" $CHECKER "$PATCHDIR/h07.py"
control "h08 logical_operator_fact answers Falsy for && too" $CHECKER "$PATCHDIR/h08.py"
control "h09 the MASK dropped from get_type_facts" $CHECKER "$PATCHDIR/h09.py"
control "h10 getSuggestedBooleanOperator always answers Unknown" $CHECKER "$PATCHDIR/h10.py"
control "h11 the RIGHT operand's BooleanLike test dropped" $CHECKER "$PATCHDIR/h11.py"
control "h12 the arithmetic arm's checkNonNullType calls removed" $CHECKER "$PATCHDIR/h12.py"
control "h13 the relational arm's checkNonNullType calls removed" $CHECKER "$PATCHDIR/h13.py"
control "h14 the reporter's null-keyword arm never taken" $CHECKER "$PATCHDIR/h14.py"
control "h15 the reporter FLAG forced TRUE" $CHECKER "$PATCHDIR/h15.py"
control "h16 the reporter FLAG forced FALSE" $CHECKER "$PATCHDIR/h16.py"
control "h17 TypeFactsNullFacts loses IsNull" $CHECKER "$PATCHDIR/h17.py"
control "h18 TypeFactsUndefinedFacts loses IsUndefined" $CHECKER "$PATCHDIR/h18.py"
control "h19 TypeFactsAndFactsMask corrupted — a member with NO reader" $CHECKER "$PATCHDIR/h19.py"
control "h20 TypeFactsEmptyObjectStrictFacts corrupted to None" $CHECKER "$PATCHDIR/h20.py"
control "h21 the Intersection/Instantiable HEAD removed" $CHECKER "$PATCHDIR/h21.py"
control "h22 the `unknown` row removed" $CHECKER "$PATCHDIR/h22.py"
control "h23 resolveCallExpression's getApparentType call removed" $CHECKER "$PATCHDIR/h23.py"
control "h24 the MARK check dropped around has_type_facts" $CHECKER "$PATCHDIR/h24.py"

echo
echo "################################################################"
bold "DONE — read every row against its PREDICTION, not against its colour."
