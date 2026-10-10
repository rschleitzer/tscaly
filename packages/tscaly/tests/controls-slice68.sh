#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice68.sh — the slice-68 battery: THE OVERLOAD CHECK.
# checkFunctionOrConstructorSymbol and its worker, the three closures it carries
# (getCanonicalOverload, checkFlagAgreementBetweenOverloads,
# checkQuestionTokenAgreementBetweenOverloads), reportImplementationExpectedError
# with its next-sibling walk, the hasBindableName guard at the function/method
# call site, and the FUNCTION BODY this port now walks for the first time.
#
# ★★★ DIAGCHECK IS THE POSITIVE INSTRUMENT AGAIN. Slices 66 and 67 could only
# LOSE a diagnostic — what they made was an object type nothing prints — so their
# batteries rested on a tag pin. This slice's whole product is diagnostics: eight
# codes over six fixtures plus the corpus's own, so most rows below break a LIVE
# report and go red by INVENTING one, which is the failure the subsequence
# relation is built to catch.
#
# ★★ THE PIN STILL CARRIES TWO THINGS DIAGCHECK CANNOT SEE, and both are tags:
# `get-signatures-of-symbol` (the slice's stop, reachable only from a
# PARAMETERLESS overload set — see checker_overload_signatures_stop.ts) and the
# body walk, whose only witness anywhere is that
# checker_function_body_walk.ts answers a tag from INSIDE the body rather than the
# tag of the line after it.
#
# ★★★ THE VERDICTS, at stage 1 on the tree this slice lands: twelve rows diagcheck
# RED, three PIN-red (g02, g19, g21), three ungated WITH A NUMBER (g12, g13, g23)
# and five ungated with an argument each. Two of those five are PROOFS rather than
# coverage gaps and are the battery's real yield: g07's guard is subsumed by a
# later one inside reportImplementationExpectedError, and g22 shows that the CLASS
# call site is redundant today because every path that reports for a class symbol
# needs a function-like declaration the function arm already walks. The other three
# are g06, g11 and g18.
#
# ★★ FIVE OF THE FIFTEEN PIN FIXTURES EXIST ONLY BECAUSE A ROW WAS SILENT —
# two_containers (g08), missing_name (g09), merged_namespace (g12),
# implementation_name (g13), ambient_after_overload (g04).
#
# ★★★ ITERATE AT STAGE 1 AND CONFIRM AT STAGE 2 ONCE — slice 64's rule.
#
# Usage (nothing may edit the tree while this runs — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # stage 1, ~25 s
#   packages/tscaly/tests/controls-slice68.sh 2>&1 | tee /tmp/battery68.log
#   TSCALY_STAGE=2 packages/tscaly/tests/run.sh       # ~7 min, ONCE
#   packages/tscaly/tests/controls-slice68.sh 2>&1 | tee /tmp/battery68-s2.log

set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.2/tscaly/checker.scaly
FIX=$PKG/tests/fixtures

. packages/tscaly/tests/toolchain.sh || exit 2

# The fixtures the PIN reads. Seven of the ten share one tag on the unpatched
# tree, which is the point: what they pin is that a row does not push a unit into
# a DIFFERENT hole, and the three that differ are the rows' real targets.
TAGFILES="
$FIX/checker_overload_implementation_missing.ts
$FIX/checker_overload_not_consecutive.ts
$FIX/checker_overload_export_disagreement.ts
$FIX/checker_overload_ambient_disagreement.ts
$FIX/checker_overload_optional_signature.ts
$FIX/checker_overload_duplicate_implementation.ts
$FIX/checker_overload_signatures_stop.ts
$FIX/checker_class_function_merge.ts
$FIX/checker_overload_class_method_unreached.ts
$FIX/checker_function_body_walk.ts
$FIX/checker_overload_two_containers.ts
$FIX/checker_overload_merged_namespace.ts
$FIX/checker_overload_implementation_name.ts
$FIX/checker_overload_ambient_after_overload.ts
$FIX/checker_overload_missing_name.ts
"

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  echo "Both instruments compare against the reference dumps that run produced."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl68)

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
  "$SCALYC" -c --no-prelude -o "$WORK/pkg.o" "$PKG/0.1.2/tscaly.scaly" > "$WORK/build.log" 2>&1 || return 1
  "$SCALYC" -c -o "$WORK/types.o" "$PKG/0.1.2/tscaly_types.scaly" >> "$WORK/build.log" 2>&1 || return 1
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
    echo "  pin       unmoved — all fifteen fixtures answer the same tag."
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
# ★★★ THE ONLY-CHECK-ONCE BIT NEVER SET — every reach re-runs the worker.
# PREDICTION: RED, and by DUPLICATION rather than by a wrong span. A class merged
# with a function is reached from both call sites, so its reports come out twice.
old = """        set links.function_or_constructor_checked: true
        this.check_function_or_constructor_symbol_worker(symbol)"""
new = """        this.check_function_or_constructor_symbol_worker(symbol)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g02.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE MEMO ALWAYS HITS — the worker never runs at all. PREDICTION: diagcheck
# UNGATED with a number (a missing line is a subsequence of anything) and the PIN
# RED, because the slice's stop tag is the worker's last statement. It is the
# sharpest statement of the division of labour between the two instruments.
old = """        if links.function_or_constructor_checked
            return"""
new = """        if true
            return"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g03.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ getCanonicalOverload ALWAYS ANSWERS THE FIRST OVERLOAD — the
# implementation-shares-a-container branch dropped. The canonical flag set is then
# the first SIGNATURE's rather than the body's, so the deviation is measured from
# the wrong end and the export fixture reports on the other two declarations.
old = """        ; implementationSharesContainerWithFirstOverload
        if AstNode.parent_node_of(implementation) = AstNode.parent_node_of(first)
            return implementation
        first"""
new = """        first"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g04.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE AMBIENT/INTERFACE RESET OF previousDeclaration DROPPED. Ambient
# declarations may be interleaved, and this reset is the whole of what says so —
# without it a `declare function` followed by a non-ambient overload is read as a
# non-consecutive block and reports TS2391 that the reference does not have.
old = """            if in_ambient_context_or_interface
                set previous_declaration: null"""
new = """            if false
                set previous_declaration: null"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g05.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE FOUR-KIND FILTER MADE TO ADMIT EVERY KIND — a class declaration then
# enters the accumulators alongside the function it merged with, carries no body,
# and turns the merge fixture into an overload set.
old = """            if Checker.is_function_or_constructor_declaration(AstNode.kind_of(node)) = false
                continue"""
new = """            if false
                continue"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g06.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★ THE Reparsed CONJUNCT DROPPED. A reparsed declaration is a JSDoc-synthesized
# one, whose end and the next node's pos have no relation — the conjunct is what
# keeps the consecutiveness test off them. Whether this corpus contains the shape
# is the row's whole question.
old = """                            if (AstNode.flags_of(prev) & NodeFlagsReparsed) = 0
                                this.report_implementation_expected_error(prev, is_constructor)"""
new = """                            this.report_implementation_expected_error(prev, is_constructor)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g07.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE CONSECUTIVENESS TEST DROPPED INSIDE THE LOOP — every overload that
# follows another now reports "not immediately following". PREDICTION: the widest
# red in the battery, because a plain overload set is the ordinary shape.
old = """                        if AstNode.end_of(prev) <> AstNode.pos_of(node)
                        {"""
new = """                        if true
                        {"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g08.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE SAME-PARENT TEST DROPPED. Two declarations in different containers are
# never "not immediately following" each other; without the test a merge across a
# namespace boundary reports.
old = """                    if AstNode.parent_node_of(prev) = AstNode.parent_node_of(node)
                    {"""
new = """                    if true
                    {"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g09.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ reportImplementationExpectedError's MISSING-NAME EARLY RETURN DROPPED. A
# declaration whose name failed to parse has a zero-width name, and the reference
# says nothing about it rather than reporting at a point.
old = """        if name <> null
        {
            if Binder.node_is_missing(name)
                return
        }
        let parent AstNode.parent_node_of(node)"""
new = """        let parent AstNode.parent_node_of(node)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g10.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE NEXT-SIBLING WALK MADE TO ANSWER THE FIRST CHILD. §3.9d's index pair is
# what the reference's ForEachChild visitor became, and the `seen` flag is the
# whole of the translation; without it the reporter compares this declaration with
# the container's first child instead of with the one after it.
old = """                if seen
                {
                    set subsequent_node: child
                    set i: child_total
                }
                else
                {
                    if child = node
                        set seen: true
                    set i: i + 1
                }"""
new = """                set subsequent_node: child
                set i: child_total"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g11.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE REPORTER'S OWN CONSECUTIVENESS TEST DROPPED — `subsequentNode.Pos() ==
# node.End()`. The reference's comment is the argument: extra nodes between
# overloads that could not be parsed leave a subsequent node that is not really
# consecutive, and reading it anyway names the wrong declaration.
old = """            if AstNode.pos_of(s) = AstNode.end_of(node)
            {"""
new = """            if true
            {"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g12.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★ THE KIND EQUALITY BETWEEN A DECLARATION AND ITS SUCCESSOR DROPPED. A function
# followed by a class is not an overload pair, and this test is what says so.
old = """                if AstNode.kind_of(s) = AstNode.kind_of(node)
                {"""
new = """                if true
                {"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g13.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ name_text_equals ALWAYS TRUE — two declarations with DIFFERENT names are
# then read as the same one, which suppresses TS2389 (the corpus's own) and lets
# the static/instance arm speak instead.
old = """        if data_a = null
            return false
        if data_b = null
            return false
        if len_a <> len_b
            return false"""
new = """        if true
            return true"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g14.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★ ast.IsPropertyNameLiteral ALWAYS FALSE — the third disjunct of the
# same-name test is then dead, so a plain identifier pair stops being recognised.
old = """    function is_property_name_literal(k: int) returns bool
    {
        if k = KindIdentifier
            return true"""
new = """    function is_property_name_literal(k: int) returns bool
    {
        if false
            return true"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g15.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE SUCCESSOR'S BODY TEST INVERTED — TS2389 is reported exactly when the
# node that follows an overload IS an implementation with a different name, and
# this is the test that says "is an implementation".
old = """                    if Binder.node_is_missing(AstNode.body_of(s)) = false
                    {
                        this.error_on_node_or_null(error_node, DiagFunction_implementation_name_must_be_0)"""
new = """                    if Binder.node_is_missing(AstNode.body_of(s))
                    {
                        this.error_on_node_or_null(error_node, DiagFunction_implementation_name_must_be_0)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g16.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE "SECOND BODY" TEST DROPPED — the FIRST implementation now counts as a
# duplicate too, so every ordinary function with a body reports TS2393.
old = """            if body_is_present
            {
                if body_declaration <> null
                {
                    if is_constructor"""
new = """            if body_is_present
            {
                if true
                {
                    if is_constructor"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g17.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE CLASS/FUNCTION MERGE BLOCK'S GUARD DROPPED. `symbol.Flags &
# SymbolFlagsFunction != 0` is what limits TS2813/TS2814 to a symbol that is BOTH
# — without it every non-ambient class declaration in the corpus reports.
old = """                if (Symbol.flags_of(symbol) & SymbolFlagsFunction) <> 0
                {
                    var j 0"""
new = """                if true
                {
                    var j 0"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g18.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE ABSTRACT/OPTIONAL GUARD ON THE LAST NON-AMBIENT DECLARATION DROPPED. An
# abstract method and an optional signature legitimately have no implementation;
# this pair of tests is the whole of that exemption.
old = """                if b.has_syntactic_modifier(last, ModifierFlagsAbstract) = false
                {
                    if Checker.is_optional_declaration(last) = false
                        this.report_implementation_expected_error(last, is_constructor)
                }"""
new = """                this.report_implementation_expected_error(last, is_constructor)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g19.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE hasOverloads GATE REMOVED — the two agreement checks then run over a
# symbol whose declarations are all implementations, where the reference does not
# ask the question at all.
old = """        if has_overloads = false
            return
        this.check_flag_agreement_between_overloads"""
new = """        this.check_flag_agreement_between_overloads"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g20.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE JAVASCRIPT GUARD DROPPED. The reference's own reason is that JS does no
# semantic analysis, so redeclaring a function in a .js file is not a duplicate;
# 151 of this corpus's units are JS or JSX, which is what makes the guard live.
old = """                if (AstNode.flags_of(node) & NodeFlagsJavaScriptFile) = 0
                    this.check_function_or_constructor_symbol(local_symbol as ref[Symbol])"""
new = """                this.check_function_or_constructor_symbol(local_symbol as ref[Symbol])"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g21.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE BODY WALK REMOVED — the arm stops where it would have stopped had this
# slice invented a report for a function it HAS. PREDICTION: the PIN is the
# instrument that sees it, because a body walk has no other witness anywhere in
# this suite.
old = """        this.check_source_element(AstNode.body_of(node))
        ; checkAllCodePathsInNonVoidFunctionReturnOrThrow's argument is"""
new = """        ; checkAllCodePathsInNonVoidFunctionReturnOrThrow's argument is"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g22.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE CLASS CALL SITE'S ASK REMOVED — the class arm no longer runs the overload
# check, so TS2813/TS2814 are lost while the function arm still finds the same
# symbol. That the merge fixture keeps ONE of its two reports is the row's content.
old = """        this.check_function_or_constructor_symbol(sym)
        if this.is_unported() <> unported_before
            return
        this.record_unported("check-object-type-for-duplicate-declarations", AstNode.kind_of(node))"""
new = """        this.record_unported("check-object-type-for-duplicate-declarations", AstNode.kind_of(node))"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g23.py" <<'PY2'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE EXPORT-SYMBOL CALL REMOVED — only the LOCAL symbol is checked. An
# exported declaration's local symbol lives in its own container, so a symbol
# exported from two namespace blocks has TWO local symbols with one declaration
# each and ONE export symbol with both; the reference reports three times and this
# leaves two. PREDICTION: ungated with a number, because a lost line is a
# subsequence of anything — the count is the whole gate.
old = """                if Symbol.has_parent(sym)
                    this.check_function_or_constructor_symbol(sym)"""
new = """                if false
                    this.check_function_or_constructor_symbol(sym)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY2

DRY=$WORK/dry
mkdir -p "$DRY"
dry_ok=1
dry_one() {   # $1 = id, $2 = file
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
for id in g01 g02 g03 g04 g05 g06 g07 g08 g09 g10 g11 g12 g13 g14 g15 g16 g17 g18 g19 g20 g21 g22 g23; do
  dry_one "$id" "$CHECKER"
done
if [ "$dry_ok" != 1 ]; then
  red "at least one anchor is wrong. Fix them before spending the battery."
  exit 2
fi

baseline

control "g01 the only-check-once bit never set"                       "$CHECKER" "$PATCHDIR/g01.py"
control "g02 the memo made to hit always — the worker never runs"     "$CHECKER" "$PATCHDIR/g02.py"
control "g03 getCanonicalOverload always the first overload"          "$CHECKER" "$PATCHDIR/g03.py"
control "g04 the ambient/interface reset of previousDeclaration gone" "$CHECKER" "$PATCHDIR/g04.py"
control "g05 the four-kind filter made to admit every kind"           "$CHECKER" "$PATCHDIR/g05.py"
control "g06 the Reparsed conjunct dropped"                           "$CHECKER" "$PATCHDIR/g06.py"
control "g07 the consecutiveness test dropped inside the loop"        "$CHECKER" "$PATCHDIR/g07.py"
control "g08 the same-parent test dropped"                            "$CHECKER" "$PATCHDIR/g08.py"
control "g09 the missing-name early return dropped"                   "$CHECKER" "$PATCHDIR/g09.py"
control "g10 the next-sibling walk made to answer the first child"    "$CHECKER" "$PATCHDIR/g10.py"
control "g11 the reporter's own consecutiveness test dropped"         "$CHECKER" "$PATCHDIR/g11.py"
control "g12 the kind equality with the successor dropped"            "$CHECKER" "$PATCHDIR/g12.py"
control "g13 name_text_equals always true"                            "$CHECKER" "$PATCHDIR/g13.py"
control "g14 IsPropertyNameLiteral always false"                      "$CHECKER" "$PATCHDIR/g14.py"
control "g15 the successor's body test inverted"                      "$CHECKER" "$PATCHDIR/g15.py"
control "g16 the second-body test dropped"                            "$CHECKER" "$PATCHDIR/g16.py"
control "g17 the class/function merge block's guard dropped"          "$CHECKER" "$PATCHDIR/g17.py"
control "g18 the abstract/optional exemption dropped"                 "$CHECKER" "$PATCHDIR/g18.py"
control "g19 the hasOverloads gate removed"                           "$CHECKER" "$PATCHDIR/g19.py"
control "g20 the JavaScript guard dropped"                            "$CHECKER" "$PATCHDIR/g20.py"
control "g21 the BODY WALK removed"                                   "$CHECKER" "$PATCHDIR/g21.py"
control "g22 the class call site's ask removed"                       "$CHECKER" "$PATCHDIR/g22.py"
control "g23 the EXPORT-symbol call removed"                          "$CHECKER" "$PATCHDIR/g23.py"

echo
echo "################################################################"
bold "RESTORED — checker.scaly, byte-identical"
git -C "$REPO" diff --stat -- "$CHECKER" | tail -3
