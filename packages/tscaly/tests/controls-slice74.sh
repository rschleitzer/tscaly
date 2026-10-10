#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice74.sh — the slice-74 battery: THE OVERRIDE MODIFIER WITHOUT A BASE.
# checkClassForStaticPropertyNameConflicts (which is inert),
# checkMembersForOverrideModifier, checkMemberForOverrideModifier's nil-base
# branch, and the extends/implements rows the walk now stops at instead.
#
# ★★★ THE SLICE HAS TWO HALVES AND ONLY ONE OF THEM PRODUCES ANYTHING, so the
# battery needs two kinds of row. The override family's reports are diagnostics, so
# diagcheck and the DIAGPIN judge them; the static-conflicts head produces NOTHING
# under this harness, and its only instrument is the TAGPIN under a row that
# substitutes the option's value (g02). A battery that carried diagcheck alone
# would score that half as untested and read as though it had been tested.
#
# ★★ DIAGCHECK IS ASYMMETRIC — a SUBSEQUENCE — so a patch that INVENTS a diagnostic
# breaks it and a patch that LOSES one leaves it green. Every losing row below is
# caught by the diagpin instead, which compares the twelve pin files' C sections
# byte for byte; every line in it was checked against the reference's own C section
# before the battery ran (with three documented gaps).
#
# ★★★ ITERATE AT STAGE 1 AND CONFIRM AT STAGE 2 ONCE — slice 64's rule. The
# recorded verdicts are stage 1's.
#
# Usage (nothing may edit the tree while this runs — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # stage 1, ~25 s
#   packages/tscaly/tests/controls-slice74.sh 2>&1 | tee /tmp/battery74.log

set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.2/tscaly/checker.scaly
FIX=$PKG/tests/fixtures

. packages/tscaly/tests/toolchain.sh || exit 2

# The twelve files both pins read: this slice's eleven, plus the implements row's
# own witness, which belongs to an earlier slice and is the only unit in the
# corpus that reaches `class-implements-heritage-clause` as its FIRST tag.
#
# ★ ONE MECHANISM PER FILE — slice 72's finding, inherited: the tagpin is
# first-wins, so a fixture naming two mechanisms is a fixture nobody can read a red
# row off.
PINFILES="
$FIX/checker_class_override_no_base.ts
$FIX/checker_class_override_no_modifier_ok.ts
$FIX/checker_class_override_property.ts
$FIX/checker_class_override_static.ts
$FIX/checker_class_override_parameter_property.ts
$FIX/checker_class_override_ambient_member_ok.ts
$FIX/checker_class_override_js.js
$FIX/checker_class_override_accessor.ts
$FIX/checker_class_extends_override.ts
$FIX/checker_class_implements_override.ts
$FIX/checker_class_static_conflicts_inert_ok.ts
$FIX/checker_static_type_class_implements.ts
"
red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  echo "diagcheck compares against the reference dumps that run produced."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl74)

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

# The DIAGPIN: the C section of each pin file, one line each. It is the `--diags`
# mode rather than the dump, because every one of these units stops at a report and
# the dump prints nothing for such a unit (TypeDump.emit's own note).
diags_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$("$WORK/tscaly_types" --diags "$f" 2>/dev/null | tr '\n' '|')"
  done
}

# The TAGPIN: the first unported tag. For this chapter it carries the half of the
# slice that produces no diagnostics at all — the static-conflicts head — so it is
# not a secondary instrument here.
tags_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$("$WORK/tscaly_types" "$f" 2>/dev/null | grep '^UNPORTED ' | head -1 | cut -d' ' -f3-)"
  done
}

DIAG_BASE=""
DIAG_LINES=""
DIAG_DIAGS=""

baseline() {
  echo "################################################################"
  bold "BASELINE — three instruments"
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
  sed -n '/^diagcheck/,$p' "$WORK/base.diag" | sed 's/^/  /'
  if [ "$rc" != 0 ]; then
    red "the diagnostics instrument is already red on the unpatched tree — fix that first."
    exit 2
  fi
  diags_of > "$WORK/base.diags"
  tags_of  > "$WORK/base.tags"
  echo
  echo "  the DIAGPIN — the fixtures' C sections on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.diags"
  if grep -q '	$' "$WORK/base.tags"; then
    red "a fixture answers NO tag — the tagpin would be comparing two empties."
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
  if ! build_bins; then
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
  diags_of > "$WORK/ctl.diags"
  tags_of  > "$WORK/ctl.tags"
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
  local pinred=0
  if cmp -s "$WORK/base.diags" "$WORK/ctl.diags"; then
    echo "  diagpin   unmoved — all twelve pin files answer the same C section."
  else
    green "diagpin   RED"
    diff "$WORK/base.diags" "$WORK/ctl.diags" | sed 's/^/    /'
    pinred=1
  fi
  if cmp -s "$WORK/base.tags" "$WORK/ctl.tags"; then
    echo "  tagpin    unmoved."
  else
    green "tagpin    RED"
    diff "$WORK/base.tags" "$WORK/ctl.tags" | sed 's/^/    /'
    pinred=1
  fi
  if [ "$rc" = 0 ] && [ "$pinred" = 0 ]; then
    if [ "$speaking" != "$DIAG_LINES" ] || [ "$diags" != "$DIAG_DIAGS" ]; then
      echo "  ungated on all three, WITH A NUMBER: $DIAG_LINES/$DIAG_DIAGS -> $speaking/$diags."
    else
      red "UNGATED ON ALL THREE AND NOTHING MOVED AT ALL."
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
# ★★★ THE PREMISE ROW: the whole chapter turned back into slice 73's stop.
# PREDICTION: diagpin red on the seven reporting fixtures and unmoved on the four
# negatives — which is what proves the pin measures THIS chapter; tagpin red on
# eleven of the twelve, the implements witness keeping its own tag; diagcheck
# ungated at slice 73's recorded 223/485, re-measured from inside this battery.
old = """        let node_in_ambient_context (AstNode.flags_of(node) & NodeFlagsAmbient) <> 0
        if node_in_ambient_context = false"""
new = """        this.record_unported("check-class-for-static-property-name-conflicts", AstNode.kind_of(node))
        return
        let node_in_ambient_context (AstNode.flags_of(node) & NodeFlagsAmbient) <> 0
        if node_in_ambient_context = false"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g02.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE OPTION SUBSTITUTED: GetUseDefineForClassFields() answers FALSE, which is
# what a `@target: es5` or `@useDefineForClassFields: false` case would give it.
# PREDICTION: tagpin RED on every fixture whose first tag is now
# `class-static-property-name-conflicts`, and diagpin RED on the seven reporting
# ones — the class returns before the override family ever runs. diagcheck ungated,
# the whole movement being a LOSS. This is the only instrument slice 74a has.
old = "        set c.use_define_for_class_fields: ScriptTargetES2025 >= ScriptTargetES2022"
new = "        set c.use_define_for_class_fields: ScriptTargetES2021 >= ScriptTargetES2022"
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g03.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The `!nodeInAmbientContext` guard on the static-conflicts call dropped.
# PREDICTION: ungated on all three with nothing moving, and the row is a PROOF
# rather than a measurement — the function returns at its own first line whatever
# the flag says, so the guard cannot be observed while the option is true. It is
# also what collapses slice 73's "ONE ROW FOR TWO PATHS" note: the ambient class
# and the plain one now arrive at the same next statement.
old = """        if node_in_ambient_context = false
        {
            this.check_class_for_static_property_name_conflicts(node)
            if this.is_unported() <> unported_before
                return
        }"""
new = """        this.check_class_for_static_property_name_conflicts(node)
        if this.is_unported() <> unported_before
            return"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g04.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The CALLER's extends stop dropped, leaving the one inside
# checkMembersForOverrideModifier. PREDICTION: tagpin RED on
# checker_class_extends_override.ts alone — its tag becomes
# `override-modifier-base-with-this`, which is the report that has no input today.
# diagpin and diagcheck unmoved: the second stop still keeps baseWithThis honest.
# ★This row is the only thing that gives that report an input, which is how a
# dead-but-correctly-placed report gets tested at all.
old = """        if Checker.get_extends_heritage_clause_element(node) <> null
        {
            this.record_unported("class-extends-heritage-clause", AstNode.kind_of(node))
            return
        }"""
new = ""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g05.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# BOTH extends stops dropped, so baseWithThis stays null for a class that HAS a
# base. PREDICTION: diagcheck RED 1 and diagpin RED on
# checker_class_extends_override.ts, which INVENTS a TS4112 where the reference
# reports TS4113. g04/g05 together separate *we stop here* from *we would be wrong
# if we did not*.
old = """        if Checker.get_extends_heritage_clause_element(node) <> null
        {
            this.record_unported("class-extends-heritage-clause", AstNode.kind_of(node))
            return
        }"""
assert s.count(old) == 1
s = s.replace(old, "", 1)
old2 = """        if Checker.get_extends_heritage_clause_element(node) <> null
        {
            this.record_unported("override-modifier-base-with-this", AstNode.kind_of(node))
            return
        }"""
assert s.count(old2) == 1
open(p, "w").write(s.replace(old2, "", 1))
PY

cat > "$PATCHDIR/g06.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The modifier test dropped in the nil-base branch: report for every member.
# PREDICTION: diagcheck RED and widest — every member of every base-less class in
# the corpus invents a TS4112; diagpin RED on the four negatives too.
old = """            if member_has_override_modifier
            {
                if is_js"""
new = """            if true
            {
                if is_js"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g07.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The isJs term dropped — always the TypeScript message. PREDICTION: diagcheck RED
# on the JavaScript units (a wrong CODE breaks the subsequence) and diagpin RED on
# checker_class_override_js.js.
old = """                if is_js
                    this.error_on_node(member, DiagThis_member_cannot_have_a_JSDoc_comment_with_an_override_tag_because_its_containing_class_0_does_not_extend_another_class)
                else
                    this.error_on_node(member, DiagThis_member_cannot_have_an_override_modifier_because_its_containing_class_0_does_not_extend_another_class)"""
new = """                this.error_on_node(member, DiagThis_member_cannot_have_an_override_modifier_because_its_containing_class_0_does_not_extend_another_class)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g08.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The isJs term inverted — always the JSDoc message. PREDICTION: diagcheck RED on
# every TypeScript unit that reports, diagpin RED on the seven reporting fixtures
# minus the .js one. g07/g08 are the two ways to lose one fact, one at each pole.
old = """                if is_js
                    this.error_on_node(member, DiagThis_member_cannot_have_a_JSDoc_comment_with_an_override_tag_because_its_containing_class_0_does_not_extend_another_class)
                else
                    this.error_on_node(member, DiagThis_member_cannot_have_an_override_modifier_because_its_containing_class_0_does_not_extend_another_class)"""
new = """                this.error_on_node(member, DiagThis_member_cannot_have_a_JSDoc_comment_with_an_override_tag_because_its_containing_class_0_does_not_extend_another_class)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g09.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ast.HasAmbientModifier's `continue` dropped. PREDICTION: diagcheck RED —
# checker_class_override_ambient_member_ok.ts invents a TS4112, and so does every
# `declare override` member in the corpus.
old = """            if b.has_syntactic_modifier(member, ModifierFlagsAmbient)
                continue"""
new = """            if false
                continue"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g10.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The constructor branch dropped, so a constructor is handed down as itself
# instead of through its parameters. PREDICTION: diagpin RED on
# checker_class_override_parameter_property.ts, which loses its line — the
# constructor carries no `override` modifier of its own. diagcheck ungated, the
# movement being a loss.
old = """            ; is_parameter_property_declaration through the parameter's own parent.
            if AstNode.kind_of(member) = KindConstructor
            {"""
new = """            ; is_parameter_property_declaration through the parameter's own parent.
            if false
            {"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g11.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The parameter-property filter dropped, so EVERY constructor parameter is asked.
# PREDICTION: ungated on all three with nothing moving, and the row is a PROOF:
# `override` is one of ModifierFlagsParameterPropertyModifier and the parent IS the
# constructor, so a parameter carrying the modifier is always a parameter property
# and one without it cannot report. The conjunct is transcribed because the
# reference has it.
old = """                    if b.is_parameter_property_declaration(param) = false
                        continue
                    this.check_member_for_override_modifier(node, static_type, base_static_type, base_with_this, t, type_with_this, param)"""
new = """                    if false
                        continue
                    this.check_member_for_override_modifier(node, static_type, base_static_type, base_with_this, t, type_with_this, param)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g12.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# hasOverrideModifier reads ModifierFlagsAbstract instead. PREDICTION: RED in both
# directions at once — diagpin loses all eight lines of the seven reporting
# fixtures, and diagcheck goes RED where an abstract member of a base-less abstract
# class invents one.
old = "        let member_has_override_modifier b.has_syntactic_modifier(member, ModifierFlagsOverride)"
new = "        let member_has_override_modifier b.has_syntactic_modifier(member, ModifierFlagsAbstract)"
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g13.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# compilerOptions.NoImplicitOverride substituted TRUE. PREDICTION: ungated with
# nothing moving — the return it guards sits BEHIND the nil-base branch, which
# every unit takes, so the option cannot be observed until the extends block is a
# port. The row PRICES the noImplicitOverride family rather than testing it.
old = "        set c.no_implicit_override: false"
new = "        set c.no_implicit_override: true"
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g14.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# getBaseConstructorTypeOfClass not called. PREDICTION: ungated with nothing
# moving — nothing reads baseStaticType on the reachable path, so the row asks
# whether the call has an observable SIDE EFFECT here (it caches undefinedType on
# the type). It is kept because the reference makes it at this point in the walk.
old = """        let base_static_type this.get_base_constructor_type_of_class(t)
        if this.is_unported() <> unported_before
            return"""
new = """        let base_static_type null as ref[Type]?"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g15.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The implements row moved IN FRONT of the override call, which is the mistake a
# reader tidying the two statements together would make. PREDICTION: diagpin RED on
# checker_class_implements_override.ts, which loses its TS4112; diagcheck ungated,
# because a lost line is a subsequence. The ORDER row.
old = """        this.check_members_for_override_modifier(node, class_type as ref[Type], type_with_this, static_type)
        if this.is_unported() <> unported_before
            return"""
new = """"""
assert s.count(old) == 1
s = s.replace(old, new, 1)
old2 = """        this.record_unported("check-index-constraints", AstNode.kind_of(node))
    }"""
new2 = """        this.check_members_for_override_modifier(node, class_type as ref[Type], type_with_this, static_type)
        if this.is_unported() <> unported_before
            return
        this.record_unported("check-index-constraints", AstNode.kind_of(node))
    }"""
assert s.count(old2) == 1
open(p, "w").write(s.replace(old2, new2, 1))
PY

cat > "$PATCHDIR/g16.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The implements wrapper asks GetHeritageElements for the EXTENDS keyword.
# PREDICTION: tagpin RED on checker_static_type_class_implements.ts, whose tag is
# the only `class-implements-heritage-clause` in the corpus and becomes
# `check-index-constraints`. diagpin and diagcheck unmoved — a lost stop is not a
# lost diagnostic here.
old = """    function get_implements_heritage_clause_elements(node: ref[AstNode]) returns ref[Array[ref[AstNode]?]]?
    {
        Checker.get_heritage_elements(node, KindImplementsKeyword)
    }"""
new = """    function get_implements_heritage_clause_elements(node: ref[AstNode]) returns ref[Array[ref[AstNode]?]]?
    {
        Checker.get_heritage_elements(node, KindExtendsKeyword)
    }"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g17.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# And the extends wrapper asks for the IMPLEMENTS keyword — the other half of the
# refactor slice 74 made when it split GetHeritageElements out. PREDICTION: broad
# red: getBaseTypeNodeOfClass, resolveBaseTypesOfClass and this chapter's own stop
# all read that wrapper, so every class with a base changes what it answers.
# g16/g17 together are the evidence that the kind argument is threaded and not
# ignored.
old = """    function get_extends_heritage_clause_elements(node: ref[AstNode]) returns ref[Array[ref[AstNode]?]]?
    {
        Checker.get_heritage_elements(node, KindExtendsKeyword)
    }"""
new = """    function get_extends_heritage_clause_elements(node: ref[AstNode]) returns ref[Array[ref[AstNode]?]]?
    {
        Checker.get_heritage_elements(node, KindImplementsKeyword)
    }"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g18.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The report's span moved from the MEMBER to the member's NAME, which is the span a
# reader would guess for a *this member cannot have* message. PREDICTION: diagpin
# RED on all seven reporting fixtures and diagcheck RED — a wrong span breaks the
# subsequence exactly as a wrong code does, and the parameter-property fixture is
# where the two spans differ most.
old = """                if is_js
                    this.error_on_node(member, DiagThis_member_cannot_have_a_JSDoc_comment_with_an_override_tag_because_its_containing_class_0_does_not_extend_another_class)
                else
                    this.error_on_node(member, DiagThis_member_cannot_have_an_override_modifier_because_its_containing_class_0_does_not_extend_another_class)"""
new = """                if is_js
                    this.error_on_node_or_null(AstNode.name_of(member), DiagThis_member_cannot_have_a_JSDoc_comment_with_an_override_tag_because_its_containing_class_0_does_not_extend_another_class)
                else
                    this.error_on_node_or_null(AstNode.name_of(member), DiagThis_member_cannot_have_an_override_modifier_because_its_containing_class_0_does_not_extend_another_class)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
# ── the dry run ─────────────────────────────────────────────────────────────
#
# Every patch applied to a COPY of the tree before the first build, so an anchor
# that moved is one message here rather than a red row three minutes in.
DRY=$WORK/dry
mkdir -p "$DRY"
dry_fail=0
for g in $(ls "$PATCHDIR"/*.py | sort); do
  name=$(basename "$g" .py)
  cp "$CHECKER" "$DRY/checker.scaly"
  if ! python3 "$g" "$DRY/checker.scaly" > "$DRY/log" 2>&1; then
    red "DRY RUN: $name does not apply — its anchor has moved."
    sed 's/^/    /' "$DRY/log"
    dry_fail=1
  fi
done
[ "$dry_fail" = 1 ] && exit 2
echo "dry run: all patches apply."


baseline

control "g01 the whole chapter back to a stop (the premise)"     "$CHECKER" "$PATCHDIR/g01.py"
control "g02 GetUseDefineForClassFields substituted FALSE"       "$CHECKER" "$PATCHDIR/g02.py"
control "g03 the non-ambient guard on the head dropped"          "$CHECKER" "$PATCHDIR/g03.py"
control "g04 the caller's extends stop dropped"                  "$CHECKER" "$PATCHDIR/g04.py"
control "g05 BOTH extends stops dropped"                         "$CHECKER" "$PATCHDIR/g05.py"
control "g06 the override-modifier test dropped"                 "$CHECKER" "$PATCHDIR/g06.py"
control "g07 the isJs term dropped (always TS4112)"              "$CHECKER" "$PATCHDIR/g07.py"
control "g08 the isJs term inverted (always TS4121)"             "$CHECKER" "$PATCHDIR/g08.py"
control "g09 the HasAmbientModifier continue dropped"            "$CHECKER" "$PATCHDIR/g09.py"
control "g10 the constructor branch dropped"                     "$CHECKER" "$PATCHDIR/g10.py"
control "g11 the parameter-property filter dropped"              "$CHECKER" "$PATCHDIR/g11.py"
control "g12 hasOverrideModifier reads Abstract"                 "$CHECKER" "$PATCHDIR/g12.py"
control "g13 NoImplicitOverride substituted TRUE"                "$CHECKER" "$PATCHDIR/g13.py"
control "g14 getBaseConstructorTypeOfClass not called"           "$CHECKER" "$PATCHDIR/g14.py"
control "g15 the implements row in front of the override call"   "$CHECKER" "$PATCHDIR/g15.py"
control "g16 the implements wrapper asks for Extends"            "$CHECKER" "$PATCHDIR/g16.py"
control "g17 the extends wrapper asks for Implements"            "$CHECKER" "$PATCHDIR/g17.py"
control "g18 the report's span moved to the member's NAME"       "$CHECKER" "$PATCHDIR/g18.py"

echo
echo "################################################################"
bold "DONE — 18 rows."
echo "A row that is UNGATED on all three needs an argument,"
echo "not a shrug."
