#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice62.sh — the slice-62 battery: the type-MEMBER arms, i.e. the
# PropertySignature and MethodSignature cases of checkSourceElement and the four
# reference functions behind them (checkPropertySignature, checkPropertyDeclaration,
# checkMethodDeclaration, checkGrammarProperty, checkGrammarMethod).
#
# ★★★ TWENTY-ONE ROWS, AND THE SLICE'S SHAPE IS THAT HALF OF WHAT IT PORTS IS
# UNREACHABLE. checkGrammarProperty is a three-way branch on the parent and only ONE
# arm is reachable — a class body is never walked, and an interface body is not
# walked either, because checkInterfaceDeclaration stops at
# checkExportsOnMergedDeclarations and its members walk is the arm's LAST statement,
# behind the whole declared-type machinery. Measured verdicts: TEN rows are diagcheck
# RED, SIX are PIN-only (they break an arm that produces no diagnostic), TWO are
# UNGATED with the number that is their whole content, and THREE are UNGATED with
# nothing moving at all — one of them with a PROOF that two spellings coincide (g02)
# and two with an unreachability argument (g17, g18). The pair g19/g20 is a PREMISE
# stack that lifts the interface stop in order to measure a branch no fixture can
# reach — slice 61's g26/g27 technique one dimension along.
#
# ★★★ THE ROW THAT MATTERS MOST IS g07, AND IT IS THE ONE THAT JUSTIFIES A DIRECTION
# RATHER THAN A LINE. `check_grammar_for_invalid_dynamic_name` cannot answer its
# question — `isLateBindableName` resolves the computed name's expression, which is
# the type dimension — so it reports and answers **true**, the value every caller
# reads as *I have reported*. g07 makes it answer FALSE instead: checkGrammarProperty
# then runs on, checkGrammarComputedPropertyName fires, and `{ [1, 2]: string }`
# collects a TS1171 the reference does not have. That is the whole argument for the
# direction, with a number on it.
#
# ★★ TWO INSTRUMENTS, as in slices 56–61. diagcheck gates the reports; a PIN over the
# eleven fixtures' unported TAGS gates the arms and the two suppressions that produce
# no diagnostic at all. One shape per fixture file, because record_unported keeps the
# FIRST report (slice 56's rule).
#
# ★ TWO FILES ARE PATCHED — checker.scaly and, for g21, ast.scaly, because the row
# that gates the accessor slice 62 introduced has to break the accessor. Every patch
# is dry-run against a copy of the tree before the first build is spent (slice 57),
# and the restore is proven with `cmp` and survives a kill (slice 58).
#
# Usage (nothing may edit the tree while this runs — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # the artifact tree, first
#   packages/tscaly/tests/controls-slice62.sh 2>&1 | tee /tmp/battery62.log

set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.2/tscaly/checker.scaly
AST=$PKG/0.1.2/tscaly/ast.scaly
FIX=$PKG/tests/fixtures

. packages/tscaly/tests/toolchain.sh || exit 2

# The fixtures the PIN reads — all eleven of this slice's. Three of them produce no
# diagnostic of their own and exist for the tag alone (the two dynamic-name
# suppressions and the literal computed name); the rest carry both, and the pin is
# what catches a row that leaves a report standing while breaking the walk under it.
TAGFILES="
$FIX/checker_property_signature_initializer.ts
$FIX/checker_property_signature_private_name.ts
$FIX/checker_property_signature_modifiers.ts
$FIX/checker_property_signature_type_walk.ts
$FIX/checker_property_dynamic_name.ts
$FIX/checker_method_signature_grammar.ts
$FIX/checker_method_signature_parameter_walk.ts
$FIX/checker_method_signature_private_name.ts
$FIX/checker_method_signature_computed_name.ts
$FIX/checker_method_signature_literal_computed_name.ts
$FIX/checker_member_container_reach.ts
"

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  echo "Both instruments compare against the reference dumps that run produced."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl62)

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
# ★★★ checkPropertySignature's PRIVATE-IDENTIFIER TEST INVERTED — the report fires
# for every property signature whose name is NOT a `#name`, which is all of them.
# It is the loudest row in the battery and it is here because the arm's whole body is
# this one test: a port that got the sense backwards would still pass every yardstick
# counter, since a diagnostic we invent is invisible to a MATCH count and visible
# only to a subsequence.
old = """        if Checker.kind_or_unknown(AstNode.name_of(node)) = KindPrivateIdentifier
            this.error_on_node(node, DiagPrivate_identifiers_are_not_allowed_outside_class_bodies)"""
new = """        if Checker.kind_or_unknown(AstNode.name_of(node)) <> KindPrivateIdentifier
            this.error_on_node(node, DiagPrivate_identifiers_are_not_allowed_outside_class_bodies)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g02.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE SAME REPORT'S SPAN MOVED TO THE NAME — AND IT IS UNGATED, WITH A PROOF.
# `error_range_for_node` resolves a PropertySignature to its declaration NAME (one of
# the seventeen kinds of `error_range_uses_declaration_name`), so
# `error_on_node(node, …)` and `error_on_node(node.Name(), …)` are the SAME span here
# and no instrument can tell them apart. The row is worth keeping because its TWIN is
# not: a MethodSignature is absent from that list, so g13 — the identical edit at the
# identical diagnostic in the other arm — is RED. **A diagnostic's span is decided by
# a table and not by the argument the reporter is handed**, and the two halves of one
# diagnostic can therefore disagree about it.
old = """        if Checker.kind_or_unknown(AstNode.name_of(node)) = KindPrivateIdentifier
            this.error_on_node(node, DiagPrivate_identifiers_are_not_allowed_outside_class_bodies)"""
new = """        if Checker.kind_or_unknown(AstNode.name_of(node)) = KindPrivateIdentifier
            this.error_on_node(AstNode.name_of(node), DiagPrivate_identifiers_are_not_allowed_outside_class_bodies)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g03.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE GRAMMAR CHAIN'S SHORT CIRCUIT DROPPED — all three checks run
# unconditionally. The reference writes `if !checkGrammarModifiers(node) &&
# !checkGrammarProperty(node) { checkGrammarComputedPropertyName(...) }`, so a
# modifier report suppresses the property check and the property check suppresses the
# name check. Reading the three as independent is the single most natural
# mistranslation of the shape, and `{ private q: number = 1 }` — wrong twice over —
# is what catches it.
old = """        var reported false
        if this.check_grammar_modifiers(node)
            set reported: true
        if reported = false
        {
            if this.check_grammar_property(node)
                set reported: true
        }
        if reported = false
            this.check_grammar_computed_property_name(AstNode.name_of(node))"""
new = """        this.check_grammar_modifiers(node)
        this.check_grammar_property(node)
        this.check_grammar_computed_property_name(AstNode.name_of(node))"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g04.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE TYPE-LITERAL INITIALIZER MESSAGE SWAPPED FOR THE INTERFACE'S — TS1246
# where TS1247 belongs. The two messages differ only in the word for the container,
# the branches sit six lines apart, and nothing but the code number distinguishes
# them; diagcheck compares the CODE, which is the whole reason this row exists.
old = """                if initializer <> null
                    return this.grammar_error_on_node(initializer, DiagA_type_literal_property_cannot_have_an_initializer)"""
new = """                if initializer <> null
                    return this.grammar_error_on_node(initializer, DiagAn_interface_property_cannot_have_an_initializer)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g05.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE INITIALIZER REPORT'S SPAN MOVED TO THE PROPERTY. Every other report in
# checkGrammarProperty is on the node or on its name; this one alone is on the
# INITIALIZER, and the reference's own three container arms are the only statement of
# that. A port that reported the member would be reporting the right error in the
# wrong place, which no yardstick counter can see.
old = """                if initializer <> null
                    return this.grammar_error_on_node(initializer, DiagA_type_literal_property_cannot_have_an_initializer)"""
new = """                if initializer <> null
                    return this.grammar_error_on_node(node, DiagA_type_literal_property_cannot_have_an_initializer)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g06.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE TYPE-LITERAL INITIALIZER REPORT REMOVED — AND THE ROW IS RED, WHICH IS NOT
# WHAT IT WAS WRITTEN FOR. It was written as *ungated by construction*: the relation is
# a SUBSEQUENCE and this only takes a line away. But `return c.grammarErrorOnNode(...)`
# is a report AND a return, and removing it lets checkGrammarProperty fall through to
# its AMBIENT branch — where check_ambient_initializer finds an initializer on a
# non-const property in an ambient context and answers **TS1039** at the same span
# where the reference has TS1247. So what this row measures is the `return`, not the
# report; g17 removes the ambient call and moves nothing, which is the same fact from
# the near side. ★The general shape: **a row that only takes a line away is ungated
# only if that line is not also control flow.**
old = """                let initializer AstNode.initializer_of(node)
                if initializer <> null
                    return this.grammar_error_on_node(initializer, DiagA_type_literal_property_cannot_have_an_initializer)"""
new = """                let initializer AstNode.initializer_of(node)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g07.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE ROW THAT JUSTIFIES A DIRECTION. check_grammar_for_invalid_dynamic_name
# reports the hole and answers TRUE, which every caller reads as *I have reported*
# and stops on; this makes it answer FALSE while KEEPING the report, so the only
# thing that changes is the control flow. checkGrammarProperty then runs on to
# checkGrammarComputedPropertyName and `{ [1, 2]: string }` collects TS1171 — a
# diagnostic the reference does not have, because in the reference the dynamic-name
# check REPORTED and returned true. The suppressing direction is the only sound one
# where the port cannot decide, and this is the number that says so.
old = """        this.record_unported("is-late-bindable-name", AstNode.kind_of(node))
        true"""
new = """        this.record_unported("is-late-bindable-name", AstNode.kind_of(node))
        false"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g08.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE LEFT CONJUNCT DROPPED — `IsDynamicName` forced false, so the hole is never
# reported and never suppresses. It is g07's row from the other side and it moves BOTH
# instruments: the two dynamic-name fixtures lose their tag (the pin) and the comma
# report fires (diagcheck). A port that had simply not noticed the term would look
# exactly like this.
old = """        if b.is_dynamic_name(node) = false
            return false"""
new = """        if true
            return false"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g09.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★ checkGrammarMethod's FIRST LINE REMOVED — the function-like grammar check, which
# is where all four diagnostics of checker_method_signature_grammar.ts come from and
# not one of them is this slice's own code. The row's content is the number: it says
# how much of the method arm's yield is the WIRING of three earlier slices.
old = """        if this.check_grammar_function_like_declaration(node)
            return true
        let k AstNode.kind_of(node)
        let parent AstNode.parent_node_of(node)"""
new = """        let k AstNode.kind_of(node)
        let parent AstNode.parent_node_of(node)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g10.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ checkGrammarMethod's TYPE-LITERAL BRANCH REMOVED — the one of its four container
# arms that is reachable. No diagnostic moves, because the branch's whole content is
# the dynamic-name hole this port reports; the PIN is the entire gate, and that is
# what a pin is for.
old = """        if pk = KindTypeLiteral
            return this.check_grammar_for_invalid_dynamic_name(name, DiagA_computed_property_name_in_a_type_literal_must_refer_to_an_expression_whose_type_is_a_literal_type_or_a_unique_symbol_type)
        false
    }"""
new = """        false
    }"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g11.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ checkMethodDeclaration's PRIVATE-NAME REPORT MADE UNCONDITIONAL — the kind test
# dropped, the containing-class walk kept. Every method signature in a type literal
# then reports TS18016. It is g01's shape at the other arm and it is the row that says
# the two tests are independent: the walk answering null is not enough, the name has
# to be a `#name` too.
old = """        if Checker.kind_or_unknown(name) = KindPrivateIdentifier
        {
            if Checker.get_containing_class(node) = null
                this.error_on_node(node, DiagPrivate_identifiers_are_not_allowed_outside_class_bodies)
        }"""
new = """        if true
        {
            if Checker.get_containing_class(node) = null
                this.error_on_node(node, DiagPrivate_identifiers_are_not_allowed_outside_class_bodies)
        }"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g12.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ get_containing_class MADE TO ANSWER ITS ARGUMENT'S PARENT UNCONDITIONALLY — a
# walk reduced to one step with no predicate, which is the mistranslation §3.9d exists
# to prevent. The report then never fires: a method signature's parent is the type
# literal, non-null, so the port reads *there is a containing class* for every method
# in the corpus. Ungated on diagcheck by construction; the number is the row.
old = """    function get_containing_class(node: pointer[AstNode]) returns pointer[AstNode]
    {
        if node = null
            return null
        var p AstNode.parent_node_of(node)"""
new = """    function get_containing_class(node: pointer[AstNode]) returns pointer[AstNode]
    {
        if node = null
            return null
        return AstNode.parent_node_of(node)
        var p AstNode.parent_node_of(node)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g13.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE METHOD'S PRIVATE-NAME REPORT MOVED TO THE NAME — g02 at the other arm, and
# the pair is the point: this one is RED and g02 is not. The two reports are the SAME
# diagnostic (TS18016) from two functions, and `error_range_uses_declaration_name`
# lists PropertySignature but not MethodSignature — so the property's two spellings
# coincide and the method's do not. A reader who checked one span would have had no
# reason to look at the other, and would have been right about the wrong half.
old = """            if Checker.get_containing_class(node) = null
                this.error_on_node(node, DiagPrivate_identifiers_are_not_allowed_outside_class_bodies)"""
new = """            if Checker.get_containing_class(node) = null
                this.error_on_node(name, DiagPrivate_identifiers_are_not_allowed_outside_class_bodies)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g14.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE PropertySignature ARM UNWIRED FROM THE SWITCH, its row in
# kind_has_ported_check_arm left in place — which is exactly the state a slice that
# updated the table and forgot the arm would be in, and the table's own header warns
# about the inverse. Everything the property half buys goes at once: the initializer
# report, the modifier reports, and the type-annotation WALK four arms deep.
old = """        if k = KindPropertySignature
        {
            this.check_property_signature(node)
            return
        }"""
new = """        if k = KindPropertySignature
            return"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g15.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE MethodSignature ARM UNWIRED — g14's twin. Four grammar diagnostics, the
# private-name report and the parameter WALK (TS2371, three functions down) go with
# it.
old = """        if k = KindMethodSignature
        {
            this.check_method_declaration(node)
            return
        }"""
new = """        if k = KindMethodSignature
            return"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g16.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ checkFunctionOrMethodDeclaration's COMPUTED-NAME REPORT REMOVED — the report
# slice 52 named and could not reach, whose caller arrived with this slice. It
# produces no diagnostic, so the PIN is the whole gate: exactly one fixture answers
# `check-computed-property-name`, and it is the one whose computed name is a string
# LITERAL — a dynamic name takes the earlier tag instead.
old = """        let name AstNode.name_of(node)
        if Checker.kind_or_unknown(name) = KindComputedPropertyName
            this.record_unported("check-computed-property-name", AstNode.kind_of(node))"""
new = """        let name AstNode.name_of(node)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g17.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ checkGrammarProperty's AMBIENT BRANCH REMOVED, and this row is EXPECTED to move
# nothing — §3.5v row 2, UNREACHABLE, with the argument in the code beside it. Every
# reachable container arm RETURNS the moment there is an initializer, and
# check_ambient_initializer returns at its own first line when there is not. So the
# call can only ever be entered for a property with no initializer, where it does
# nothing. A property DECLARATION in a `declare class` is the caller that makes it
# live, and nothing walks a class body. ★MEASURED: nothing moved, as predicted — and
# g06 is the other half of the proof, because removing the RETURN in front of this
# call makes it report.
old = """        if (AstNode.flags_of(node) & NodeFlagsAmbient) <> 0
            this.check_ambient_initializer(node)"""
new = """        if false
            this.check_ambient_initializer(node)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g18.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE MAPPED-TYPE REPORT REMOVED — checkGrammarProperty's FIRST report, and it too
# is expected to move nothing, for a reason that is two unreachabilities stacked.
# `[K in X]` parses as a computed property name only where no mapped type is
# admitted — an interface body, whose members are not walked — and a real mapped
# type's own member list is the parser's recovery slot, which checkMappedType does not
# walk either. It is ported because it is the only reader of `member_list_of`'s
# class/interface/enum arms and because a report reached by neither route today is
# still the reference's line.
old = """                if AstNode.binary_operator_kind(expr) = KindInKeyword
                    return this.grammar_error_on_node(AstNode.child_in_list(AstNode.member_list_of(parent), 0), DiagA_mapped_type_may_not_declare_properties_or_methods)"""
new = """                if false
                    return this.grammar_error_on_node(AstNode.child_in_list(AstNode.member_list_of(parent), 0), DiagA_mapped_type_may_not_declare_properties_or_methods)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g19.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE PREMISE ROW — checkInterfaceDeclaration GIVEN ITS MEMBERS WALK, which the
# reference has as the LAST statement of that arm, with the whole declared-type
# machinery between it and the stop this port reports at. It is not a defect
# being injected: it is slice 61's g26 technique, a premise that makes an
# UNREACHABLE branch measurable. With it, checker_member_container_reach.ts's
# interface property reports TS1246 — a diagnostic the reference HAS — so diagcheck
# stays green and the count RISES, which is the row. g20 then breaks the branch on
# top of it.
old = """        this.record_unported("check-exports-on-merged-declarations", KindInterfaceDeclaration)
    }"""
new = """        this.check_source_elements(AstNode.member_list_of(node))
        this.record_unported("check-exports-on-merged-declarations", KindInterfaceDeclaration)
    }"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g20.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ g19 PLUS THE INTERFACE BRANCH GIVEN THE TYPE-LITERAL'S MESSAGE — TS1247 where
# TS1246 belongs. Against g19 (not against the baseline) the only difference is the
# code, and diagcheck goes red: the branch that no fixture can reach is measured
# after all, and the measurement needed a premise rather than a fixture. That is the
# distinction §3.5v draws between UNCOVERED and UNREACHABLE, made with two rows.
old = """        this.record_unported("check-exports-on-merged-declarations", KindInterfaceDeclaration)
    }"""
new = """        this.check_source_elements(AstNode.member_list_of(node))
        this.record_unported("check-exports-on-merged-declarations", KindInterfaceDeclaration)
    }"""
assert s.count(old) == 1, s.count(old)
s = s.replace(old, new)
old2 = """                if initializer <> null
                    return this.grammar_error_on_node(initializer, DiagAn_interface_property_cannot_have_an_initializer)"""
new2 = """                if initializer <> null
                    return this.grammar_error_on_node(initializer, DiagA_type_literal_property_cannot_have_an_initializer)"""
assert s.count(old2) == 1, s.count(old2)
open(p, "w").write(s.replace(old2, new2))
PY

cat > "$PATCHDIR/g21.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ member_list_of's TypeLiteral ARM REMOVED — the accessor this slice introduced,
# broken at the one arm slice 61's walk depends on. It is the row that says why the
# retirement of `type_literal_members_of` had to be a WIDENING and not a rename: one
# accessor now serves the type literal's own members walk AND
# checkGrammarProperty's `node.Parent.Members()`, so a mistake in it takes both. Every
# member report of both slices goes at once.
old = """            when tl: TypeLiteral
                return tl.members
            when mt: MappedType
                return mt.members"""
new = """            when mt: MappedType
                return mt.members"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

# ── the dry run ─────────────────────────────────────────────────────────────

bold "DRY RUN — every patch against a COPY of the tree"
DRY=$WORK/dry
mkdir -p "$DRY"
dry_ok=1
for id in g01 g02 g03 g04 g05 g06 g07 g08 g09 g10 g11 g12 g13 g14 g15 g16 g17 g18 g19 g20; do
  cp "$CHECKER" "$DRY/copy"
  if python3 "$PATCHDIR/$id.py" "$DRY/copy" 2> "$DRY/err"; then
    printf '  %s  ok\n' "$id"
  else
    red "  $id  DID NOT APPLY — $(tail -1 "$DRY/err")"
    dry_ok=0
  fi
done
cp "$AST" "$DRY/copy"
if python3 "$PATCHDIR/g21.py" "$DRY/copy" 2> "$DRY/err"; then
  printf '  g21  ok\n'
else
  red "  g21  DID NOT APPLY — $(tail -1 "$DRY/err")"
  dry_ok=0
fi
if [ "$dry_ok" != 1 ]; then
  red "at least one anchor is wrong. Fix them before spending the battery."
  exit 2
fi

baseline

control "g01 the private-signature kind test INVERTED"                       "$CHECKER" "$PATCHDIR/g01.py"
control "g02 that report's span moved to the NAME"                           "$CHECKER" "$PATCHDIR/g02.py"
control "g03 the grammar chain's short circuit DROPPED"                      "$CHECKER" "$PATCHDIR/g03.py"
control "g04 the type-literal initializer message swapped for the interface's" "$CHECKER" "$PATCHDIR/g04.py"
control "g05 the initializer report's span moved to the PROPERTY"            "$CHECKER" "$PATCHDIR/g05.py"
control "g06 the type-literal initializer report REMOVED"                    "$CHECKER" "$PATCHDIR/g06.py"
control "g07 the dynamic-name hole answers FALSE instead of TRUE"            "$CHECKER" "$PATCHDIR/g07.py"
control "g08 the dynamic-name TEST forced false"                             "$CHECKER" "$PATCHDIR/g08.py"
control "g09 checkGrammarMethod's first line REMOVED"                        "$CHECKER" "$PATCHDIR/g09.py"
control "g10 checkGrammarMethod's type-literal branch REMOVED"               "$CHECKER" "$PATCHDIR/g10.py"
control "g11 the method private-name report made UNCONDITIONAL"              "$CHECKER" "$PATCHDIR/g11.py"
control "g12 get_containing_class reduced to ONE step with no predicate"     "$CHECKER" "$PATCHDIR/g12.py"
control "g13 the method private-name report moved to the NAME"               "$CHECKER" "$PATCHDIR/g13.py"
control "g14 the PropertySignature arm UNWIRED"                              "$CHECKER" "$PATCHDIR/g14.py"
control "g15 the MethodSignature arm UNWIRED"                                "$CHECKER" "$PATCHDIR/g15.py"
control "g16 the computed-name report of checkFunctionOrMethodDeclaration REMOVED" "$CHECKER" "$PATCHDIR/g16.py"
control "g17 checkGrammarProperty's ambient branch REMOVED"                  "$CHECKER" "$PATCHDIR/g17.py"
control "g18 the mapped-type report REMOVED"                                 "$CHECKER" "$PATCHDIR/g18.py"
control "g19 PREMISE: the interface given its members walk"                  "$CHECKER" "$PATCHDIR/g19.py"
cp "$WORK/last.tags" "$WORK/g19.tags"
control "g20 g19 + the interface branch given the TYPE-LITERAL message"      "$CHECKER" "$PATCHDIR/g20.py" "$WORK/g19.tags"
control "g21 member_list_of's TypeLiteral arm REMOVED"                       "$AST"     "$PATCHDIR/g21.py"

echo
echo "################################################################"
bold "RESTORED — checker.scaly and ast.scaly, byte-identical"
git -C "$REPO" diff --stat -- "$CHECKER" "$AST" | tail -3
