#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice73.sh — the slice-73 battery: THE CLASS'S DUPLICATE MEMBERS.
# checkObjectTypeForDuplicateDeclarations, its checkPropertyOrAccessor closure,
# reportDuplicateMemberErrors, and the association list that stands in for the
# reference's three `map[string]int`s.
#
# ★★★ THREE INSTRUMENTS, AND DIAGCHECK ALONE WOULD MISS HALF OF THEM. What this
# slice produces is diagnostics, so diagcheck is a positive instrument again after
# two slices in which it could only lose a line — but its relation is a
# SUBSEQUENCE, which is asymmetric: a patch that INVENTS a diagnostic breaks it and
# a patch that LOSES one leaves it green. Six of the rows below are exactly the
# losing kind. So this battery adds a DIAGPIN — the exact C lines of the eighteen
# fixtures, compared byte for byte — and keeps the TAGPIN over their first unported
# tag as the third.
#
# ★★ THE DIAGPIN IS THE ONE TO READ FIRST. It is the only instrument here that is
# symmetric in the direction the slice's product points: every line it holds was
# checked against the reference's own C section when the fixture was written (see
# CLAUDE.md §3.5ds for the table), so a red diagpin is a statement about the
# reference and not merely about a previous build of this port.
#
# ★★★ ITERATE AT STAGE 1 AND CONFIRM AT STAGE 2 ONCE — slice 64's rule. The
# recorded verdicts below are stage 1's.
#
# Usage (nothing may edit the tree while this runs — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # stage 1, ~25 s
#   packages/tscaly/tests/controls-slice73.sh 2>&1 | tee /tmp/battery73.log

set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.0/tscaly/checker.scaly
FIX=$PKG/tests/fixtures

. packages/tscaly/tests/toolchain.sh || exit 2

# The eighteen fixtures both pins read: the ten that report and the eight
# negatives whose whole content is that they do NOT.
#
# ★ ONE MECHANISM PER FILE — slice 72's first finding. The TAGPIN inherits the
# first-wins rule and so would collapse two gates in one file into one; the
# DIAGPIN does not, but a fixture whose header names two mechanisms is a fixture
# nobody can read a red row off.
PINFILES="
$FIX/checker_class_duplicate_property.ts
$FIX/checker_class_duplicate_property_accessor.ts
$FIX/checker_class_duplicate_accessor_property.ts
$FIX/checker_class_accessor_pair_ok.ts
$FIX/checker_class_duplicate_static.ts
$FIX/checker_class_duplicate_static_instance_ok.ts
$FIX/checker_class_duplicate_both_sides.ts
$FIX/checker_class_duplicate_parameter_property.ts
$FIX/checker_class_parameter_property_binding_pattern.ts
$FIX/checker_class_static_prototype.ts
$FIX/checker_class_static_prototype_ambient.d.ts
$FIX/checker_class_instance_prototype_ok.ts
$FIX/checker_class_private_name_static_instance.ts
$FIX/checker_class_private_name_duplicate.ts
$FIX/checker_class_private_name_reported_once.ts
$FIX/checker_class_accessor_modifier_field.ts
$FIX/checker_class_accessor_modifier_pair_ok.ts
$FIX/checker_class_computed_names_ok.ts
"

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  echo "diagcheck compares against the reference dumps that run produced."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl73)

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
  "$SCALYC" -c --no-prelude -o "$WORK/pkg.o" "$PKG/0.1.0/tscaly.scaly" > "$WORK/build.log" 2>&1 || return 1
  "$SCALYC" -c -o "$WORK/types.o" "$PKG/0.1.0/tscaly_types.scaly" >> "$WORK/build.log" 2>&1 || return 1
  clang -o "$WORK/tscaly_types" "$WORK/types.o" "$WORK/pkg.o" "$LIBSCALY" -lm >> "$WORK/build.log" 2>&1
}

# The DIAGPIN: the C section of each fixture, in one line per fixture. It is the
# `--diags` mode rather than the dump, because every one of these units stops at a
# report and the dump prints nothing for such a unit (TypeDump.emit's own note).
diags_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$("$WORK/tscaly_types" --diags "$f" 2>/dev/null | tr '\n' '|')"
  done
}

# The TAGPIN: the first unported tag, which for this chapter says whether the arm
# still reaches the same stop.
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
    echo "  diagpin   unmoved — all eighteen fixtures answer the same C section."
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
# ★★★ THE PREMISE ROW: the whole chapter turned back into slice 72's stop.
# PREDICTION: diagpin red on the ten reporting fixtures and unmoved on the eight
# negatives — which is what proves the pin measures THIS function; tagpin red on
# all eighteen, since the row's name goes back.
old = """        this.check_object_type_for_duplicate_declarations(node, true)"""
new = """        this.record_unported("check-object-type-for-duplicate-declarations", AstNode.kind_of(node))
        return"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g02.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The `len(symbol.Declarations) > 1` guard dropped. PREDICTION: diagcheck RED —
# two computed member names bind to ONE internal name with one declaration each,
# so checker_class_computed_names_ok.ts collects an invented TS2300 pair.
old = """        if Symbol.declaration_count(sym) <= 1
            return"""
new = """        if false
            return"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g03.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The two kind maps folded into one. PREDICTION: diagpin RED on
# checker_class_duplicate_both_sides.ts, which loses its static pair — the
# instance pair writes state 3 first and silences it. ★The obvious candidate
# (a static beside an instance member of one name) does NOT gate this: those are
# two symbols with one declaration each and the guard stops them, which is why the
# first draft of this row came back ungated.
old = """        var names: ref[Array[DuplicateNameEntry]] instance_names
        if is_static
            set names: static_names"""
new = """        var names: ref[Array[DuplicateNameEntry]] instance_names"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g04.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# An accessor recorded with kind 1 instead of 2. PREDICTION: diagcheck RED — a
# getter/setter pair then reports (1 against state 1), inventing a TS2300 pair on
# checker_class_accessor_pair_ok.ts.
old = """                if is_accessor
                    this.check_property_or_accessor(node, symbol, 2, is_static, ia, sa)"""
new = """                if is_accessor
                    this.check_property_or_accessor(node, symbol, 1, is_static, ia, sa)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g05.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The `kind != 2` conjunct dropped — any second sighting reports. PREDICTION:
# diagcheck RED on checker_class_accessor_pair_ok.ts, the getter/setter pair — the
# ONE negative here whose symbol is merged, which is what makes it the only witness
# for this conjunct (the two `accessor` fields are stopped a step earlier; see g08).
old = """        if state = 2
        {
            if kind <> 2
                set report: true
        }"""
new = """        if state = 2
            set report: true"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g06.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The whole `state == 2` case dropped. PREDICTION: diagpin RED on
# checker_class_duplicate_accessor_property.ts and
# checker_class_accessor_modifier_field.ts — the two files whose FIRST member is
# the accessor — and diagcheck ungated, because a lost line is still a
# subsequence. This is the row the diagpin exists for.
old = """        if state = 2
        {
            if kind <> 2
                set report: true
        }"""
new = """        if false
            set report: true"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g07.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The "errors have been reported" write dropped. PREDICTION: diagcheck RED — the
# third `a` of checker_class_duplicate_property.ts finds state 1 again and reports
# a SECOND time, so our lines repeat and are no longer a subsequence.
old = """        ; Record that errors have been reported.
        Checker.set_duplicate_name_state(names, d, n, 3)"""
new = """        ; Record that errors have been reported."""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g08.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# HasAccessorModifier dropped from BOTH conditions, so an `accessor` field is a
# property. PREDICTION: UNGATED, and the row is the MEASUREMENT that says so —
# arrived at after two wrong fixtures. The only kind pair whose ANSWER differs is
# accessor-against-accessor, where the switch falls through and reports nothing;
# the binder never merges that pair (two `accessor` fields conflict, and so does an
# `accessor` field beside a getter), so the declaration-count guard stops it, while
# every shape that does merge reports under both readings. See
# checker_class_accessor_modifier_pair_ok.ts for the whole account.
old = """            if mk = KindPropertyDeclaration
            {
                if b.has_syntactic_modifier(member, ModifierFlagsAccessor) = false
                    set is_property: true
            }"""
new = """            if mk = KindPropertyDeclaration
                set is_property: true"""
assert s.count(old) == 1
s = s.replace(old, new, 1)
old = """                if mk = KindPropertyDeclaration
                {
                    if b.has_syntactic_modifier(member, ModifierFlagsAccessor)
                        set is_accessor: true
                }"""
new = """"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g09.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The non-ambient guard on the prototype report dropped. PREDICTION: diagcheck RED
# — checker_class_static_prototype_ambient.d.ts collects an invented TS2699.
old = """            if node_in_ambient_context = false
            {
                if is_static"""
new = """            if true
            {
                if is_static"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g10.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The `isStatic` conjunct of the prototype report dropped. PREDICTION: diagcheck
# RED — checker_class_instance_prototype_ok.ts collects an invented TS2699.
old = """                if is_static
                {
                    if symbol <> null"""
new = """                if true
                {
                    if symbol <> null"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g11.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ast.HasStaticModifier replaced by ast.IsStatic where the KIND MAP is chosen.
# PREDICTION: ungated. The two differ only on a `static` modifier outside a class
# element and on a static block, and neither can be a property or an accessor — so
# this row measures the claim that the two questions coincide HERE, which is the
# only reason the port may not fold them.
old = """            let is_static b.has_syntactic_modifier(member, ModifierFlagsStatic)"""
new = """            let is_static b.is_static(member)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g12.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The other direction of g11: ast.IsStatic replaced by ast.HasStaticModifier where
# the PRIVATE NAME's bit is chosen. PREDICTION: ungated, same argument — and the
# pair together is the whole evidence that the two questions are one on this
# corpus while remaining two in the reference.
old = """            var bit 1
            if b.is_static(member)
                set bit: 2"""
new = """            var bit 1
            if b.has_syntactic_modifier(member, ModifierFlagsStatic)
                set bit: 2"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g13.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The reporter's checkStatic filter dropped. PREDICTION: diagcheck RED — the
# static pair of checker_class_duplicate_static.ts drags its INSTANCE namesake in
# and invents a third TS2300.
old = """            if check_static
            {
                if is_static <> b.is_static(member)
                    continue
            }"""
new = """"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g14.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The private-name report asks for the static filter it must not have.
# PREDICTION: diagpin RED on the three TS2804 fixtures, which lose the STATIC half
# of every report; diagcheck ungated. The second row the diagpin exists for.
old = """                this.report_duplicate_member_errors(node, pd, pl, false, false, DiagDuplicate_identifier_0_Static_and_instance_elements_cannot_share_the_same_private_name)"""
new = """                this.report_duplicate_member_errors(node, pd, pl, true, false, DiagDuplicate_identifier_0_Static_and_instance_elements_cannot_share_the_same_private_name)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g15.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The privateNames `flags != 3` guard dropped. PREDICTION: diagcheck RED —
# checker_class_private_name_reported_once.ts reports TS2804 a second time on its
# fourth sighting, so every line of the first report repeats.
old = """            var flags Checker.duplicate_name_state(pa, pd, pl)
            if flags = 3
                continue"""
new = """            var flags Checker.duplicate_name_state(pa, pd, pl)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g16.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The private-name bits swapped: 2 for an instance member, 1 for a static one.
# PREDICTION: ungated, and the row is a PROOF rather than a measurement — the
# report fires on the OR reaching 3 and 1|2 is 3 either way, so the two bits are
# distinguishable only by a reader that asks which of them is set. There is none.
old = """            var bit 1
            if b.is_static(member)
                set bit: 2"""
new = """            var bit 2
            if b.is_static(member)
                set bit: 1"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g17.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# checkPrivateNames forced false at the only call site that passes true.
# PREDICTION: diagpin RED on the three TS2804 fixtures; diagcheck ungated. It is
# also the row that says what the flag's FALSE side would cost, which is the state
# checkTypeLiteral and checkInterfaceDeclaration will arrive in.
old = """        this.check_object_type_for_duplicate_declarations(node, true)"""
new = """        this.check_object_type_for_duplicate_declarations(node, false)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g18.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The IsPrivateIdentifier test on the member's name dropped, so every named member
# enters the private-name map. PREDICTION: diagcheck RED — `a` and `static a` OR
# to 3 and invent a TS2804 on checker_class_duplicate_static_instance_ok.ts.
old = """            if AstNode.is_private_identifier(nm) = false
                continue"""
new = """            if false
                continue"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g19.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The REPORTER's constructor branch dropped, so a parameter property cannot
# collect a diagnostic. PREDICTION: diagpin RED on
# checker_class_duplicate_parameter_property.ts, which keeps the field's line and
# loses the parameter's; diagcheck ungated.
old = """                    if Checker.symbol_name_matches(psym as ref[Symbol], name_data, name_len)
                        this.error_on_node_or_null(AstNode.name_of(param), code)"""
new = """                    if false
                        this.error_on_node_or_null(AstNode.name_of(param), code)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g20.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The WALK's constructor branch dropped, so a parameter property never enters the
# map. PREDICTION: diagpin RED on the same fixture and losing BOTH lines — the
# state machine sees one `a` and nothing trips at all. The pair g19/g20 is what
# separates the two loops, which are easy to read as one.
old = """                    this.check_property_or_accessor(node, this.symbol_of_declaration(param), 1, false, ia, sa)"""
new = """                    continue"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g21.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The `!IsBindingPattern` conjunct dropped in BOTH loops. PREDICTION: UNGATED, and
# the row is a PROOF — measured after it refuted the opposite prediction. The
# binder gives such a parameter the internal name `__missing` (first byte 0xFE,
# unequal to any member name) AND a single declaration, so both the name comparison
# and the `len(Declarations) > 1` guard stop it. The conjunct is transcribed because
# the reference has it, not because it fires.
old = """                    if AstNode.is_binding_pattern(AstNode.name_of(param))
                        continue
                    this.check_property_or_accessor(node, this.symbol_of_declaration(param), 1, false, ia, sa)"""
new = """                    this.check_property_or_accessor(node, this.symbol_of_declaration(param), 1, false, ia, sa)"""
assert s.count(old) == 1
s = s.replace(old, new, 1)
old = """                    if AstNode.is_binding_pattern(AstNode.name_of(param))
                        continue
                    let psym this.symbol_of_declaration(param)"""
new = """                    let psym this.symbol_of_declaration(param)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g22.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The first sighting records 3 instead of the kind. PREDICTION: diagpin RED on
# every one of the nine reporting fixtures except the three whose only diagnostic
# is TS2699 or TS2804 — nothing can ever match state 1 or 2 again, so the whole
# kind-map half goes silent while the other two reports stand.
old = """            Checker.set_duplicate_name_state(names, d, n, kind)"""
new = """            Checker.set_duplicate_name_state(names, d, n, 3)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g23.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The map WRITE appends instead of overwriting, so the first entry for a name wins
# every later read. PREDICTION: diagcheck RED — state 3 becomes unreachable and
# the third `a` of checker_class_duplicate_property.ts reports again, exactly as
# in g07. Two ways to lose the same invariant, one in the state machine and one in
# the storage under it.
old = """            if SymbolTable.names_equal(e.name_data, e.name_len, d, n)
            {
                set e.state: s
                return
            }"""
new = """            if false
            {
                set e.state: s
                return
            }"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g24.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# An absent name answers 1 rather than the zero value. PREDICTION: diagcheck RED
# and widely — every FIRST sighting of a duplicated name now reads as a second
# one, so a report lands on a name that has been declared only once so far.
old = """            set i: i + 1
        }
        0
    }"""
new = """            set i: i + 1
        }
        1
    }"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g25.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# symbol_name_equals compares the bytes without comparing the LENGTH first.
# PREDICTION: diagcheck RED — a static member whose name merely STARTS with
# `prototype` would report, and the corpus is what says whether one exists; if
# nothing moves, the guard is the shape rule §3.5's name comparisons keep and this
# row is a measurement of the corpus rather than of the port.
old = """        if Symbol.name_len_of(s) <> len
            return false
        let d Symbol.name_data_of(s)"""
new = """        if Symbol.name_len_of(s) < len
            return false
        let d Symbol.name_data_of(s)"""
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

control "g01 the whole chapter back to a stop (the premise)"    "$CHECKER" "$PATCHDIR/g01.py"
control "g02 the declaration-count guard dropped"              "$CHECKER" "$PATCHDIR/g02.py"
control "g03 the two kind maps folded into one"                "$CHECKER" "$PATCHDIR/g03.py"
control "g04 an accessor recorded with the property's kind"     "$CHECKER" "$PATCHDIR/g04.py"
control "g05 the kind != 2 conjunct dropped"                    "$CHECKER" "$PATCHDIR/g05.py"
control "g06 the whole state == 2 case dropped"                 "$CHECKER" "$PATCHDIR/g06.py"
control "g07 the already-reported state never written"          "$CHECKER" "$PATCHDIR/g07.py"
control "g08 HasAccessorModifier dropped from both conditions"  "$CHECKER" "$PATCHDIR/g08.py"
control "g09 the non-ambient guard on TS2699 dropped"           "$CHECKER" "$PATCHDIR/g09.py"
control "g10 the isStatic conjunct on TS2699 dropped"           "$CHECKER" "$PATCHDIR/g10.py"
control "g11 the kind map chosen by IsStatic"                   "$CHECKER" "$PATCHDIR/g11.py"
control "g12 the private bit chosen by HasStaticModifier"       "$CHECKER" "$PATCHDIR/g12.py"
control "g13 the reporter's checkStatic filter dropped"         "$CHECKER" "$PATCHDIR/g13.py"
control "g14 the private report asks for the static filter"     "$CHECKER" "$PATCHDIR/g14.py"
control "g15 the privateNames flags != 3 guard dropped"         "$CHECKER" "$PATCHDIR/g15.py"
control "g16 the private-name bits swapped"                     "$CHECKER" "$PATCHDIR/g16.py"
control "g17 checkPrivateNames false at the class call site"    "$CHECKER" "$PATCHDIR/g17.py"
control "g18 the IsPrivateIdentifier test dropped"              "$CHECKER" "$PATCHDIR/g18.py"
control "g19 the REPORTER's constructor branch dropped"         "$CHECKER" "$PATCHDIR/g19.py"
control "g20 the WALK's constructor branch dropped"             "$CHECKER" "$PATCHDIR/g20.py"
control "g21 the binding-pattern conjunct dropped in both"      "$CHECKER" "$PATCHDIR/g21.py"
control "g22 the first sighting records 3"                      "$CHECKER" "$PATCHDIR/g22.py"
control "g23 the map write appends instead of overwriting"       "$CHECKER" "$PATCHDIR/g23.py"
control "g24 an absent name answers 1"                          "$CHECKER" "$PATCHDIR/g24.py"
control "g25 symbol_name_equals without the length test"        "$CHECKER" "$PATCHDIR/g25.py"

echo
echo "################################################################"
bold "DONE — 25 rows."
echo "A row that is UNGATED on all three needs an argument in CLAUDE.md's"
echo "table, not a shrug: §3.5v names the four kinds it can be."
