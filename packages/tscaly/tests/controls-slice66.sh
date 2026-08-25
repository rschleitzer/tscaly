#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice66.sh — the slice-66 battery: the FIRST OBJECT TYPES.
# getDeclaredTypeOfSymbol and its one live arm getDeclaredTypeOfClassOrInterface,
# getDeclaredTypeOfTypeParameter, the two type-parameter collectors,
# isThislessInterface, createTypeReference and getTypeWithThisArgument — and the
# `TypeData` union that had to exist before any of them could.
#
# ★★★ HALF OF THIS BATTERY IS UNGATED BY CONSTRUCTION, AND THAT IS THE SLICE'S OWN
# PROPERTY RATHER THAN A HOLE IN THE ROWS. What the slice produces is an OBJECT
# TYPE, and this port cannot print one: type_to_string ports the KEYWORD arms of
# the reference's worker and nothing else, so a class's declared type has no name
# in the T section, and no arm this slice reaches reports a diagnostic. So a row
# that changes what the type CONTAINS moves nothing, and a row that changes who
# REPORTS moves the pin. Every ungated row below names the reader that would make
# its difference observable — which is §3.5ao's rule applied to a whole slice
# instead of to one field.
#
# ★★★ THE ONE ROW THAT REPRODUCES A DEFECT THE SLICE ACTUALLY HAD is g14, and it
# is the reason diagcheck is in this battery at all. `is_unported()` is a
# UNIT-WIDE STICKY FLAG — record_unported is first-wins — so using it as a
# per-call error test returns early for every declaration after the first. Written
# that way, the type-parameter arm skipped checkTypeNameIsReserved on the second
# and third parameter and diagcheck fell 340 -> 338 diagnostics on one fixture.
# The tags did not move at all: **the pin cannot see a lost diagnostic, and
# diagcheck cannot see a moved tag, which is why both instruments run.**
#
# ★★ TWO INSTRUMENTS, as in slices 56-65: diagcheck over the whole corpus, and a
# PIN over six fixtures' unported TAGS. The six are chosen so that each pins a
# DIFFERENT path through the slice — plain class, generic class (which never
# reaches the head at all), plain interface, an interface whose body mentions
# `this`, one with an extends clause, and one declared twice. The `this` fixture
# and the plain one answer the SAME tag on purpose: the difference between them is
# a `this` type nothing can print, and the row that would gate it says so.
#
# ★★★ ITERATE AT STAGE 1 AND CONFIRM AT STAGE 2 ONCE — slice 64's rule. Measured
# here: 18 rows in ~2 min at stage 1.
#
# Usage (nothing may edit the tree while this runs — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # stage 1, ~30 s
#   packages/tscaly/tests/controls-slice66.sh 2>&1 | tee /tmp/battery66.log
#   TSCALY_STAGE=2 packages/tscaly/tests/run.sh       # ~7 min, ONCE
#   packages/tscaly/tests/controls-slice66.sh 2>&1 | tee /tmp/battery66-s2.log

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
$FIX/checker_declared_type_class_plain.ts
$FIX/checker_declared_type_class_generic.ts
$FIX/checker_declared_type_interface_plain.ts
$FIX/checker_declared_type_interface_this.ts
$FIX/checker_declared_type_interface_extends.ts
$FIX/checker_declared_type_interface_merged.ts
"

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  echo "Both instruments compare against the reference dumps that run produced."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl66)

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
    echo "  pin       unmoved against $againstname — all six fixtures answer the same tag."
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
# copy of the tree before a single build is spent (slice 57).

cat > "$PATCHDIR/g01.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE HEAD MADE TO REPORT FOR EVERY SYMBOL. The cheapest possible statement of
# *is getDeclaredTypeOfSymbol on the path at all* — and the answer is a count, not
# an argument: every class and interface in the corpus stops there again.
old = """        let f Symbol.flags_of(symbol)
        if (f & (SymbolFlagsClass | SymbolFlagsInterface)) <> 0"""
new = """        let f Symbol.flags_of(symbol)
        this.record_unported("g01-head-reached", 0)
        if (f & (SymbolFlagsClass | SymbolFlagsInterface)) <> 0"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g02.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE CLASS HALF OF THE FIRST ARM REMOVED — the switch then answers nil for a
# class, which getDeclaredTypeOfSymbol turns into errorType. PREDICTION: ungated on
# both instruments, because the class arm's stop does not depend on the type being
# right, only on it being non-null. If that prediction holds it is the row's whole
# content, and it is the sharpest statement of what this slice cannot measure.
old = """        if (f & (SymbolFlagsClass | SymbolFlagsInterface)) <> 0"""
new = """        if (f & SymbolFlagsInterface) <> 0"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g03.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE ARM ANSWERING NULL. Both call sites then take their `if t = null return`
# and the unit is never marked — so it produces a full dump instead of an UNPORTED
# line, which is the loudest failure this yardstick has.
old = """        let links this.declared_type_link_of(symbol)
        if links.declared_type <> null
            return links.declared_type
        var kind ObjectFlagsInterface"""
new = """        let links this.declared_type_link_of(symbol)
        if links.declared_type <> null
            return links.declared_type
        return null
        var kind ObjectFlagsInterface"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g04.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE MEMO MADE TO MISS ALWAYS — every ask mints a fresh row and a fresh type.
# PREDICTION: ungated. Nothing in this slice asks twice (the two call sites ask
# once per symbol and isThislessInterface's recursive ask is behind a report), so
# the memo is written for fidelity alone. NAMED READER: getBaseTypes, where an
# interface's declared type is asked again through its base and the identity of the
# answer is what makes `thisType` the same object on both routes.
old = """            if row <> null
            {
                let r row as ref[DeclaredTypeLink]
                if r.symbol = sym
                    return r
            }"""
new = """            if row <> null
            {
                let r row as ref[DeclaredTypeLink]
                if r.symbol = null
                    return r
            }"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g05.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE WRITE-BACK DROPPED from fill_interface_data — the payload is mutated in
# the `when` binding's COPY and the copy is thrown away. This is the exact spelling
# the slice was first written with, and it is the row that gates ast.scaly's
# copy/mutate/write-back idiom rather than a fact about the reference.
old = """                set d.target: t
                set t.data: TypeData.Interface(d)"""
new = """                set d.target: t"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g06.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE `kind == Class` TERM DROPPED from the this-type disjunction. A plain class
# then goes through isThislessInterface, whose loop looks only at INTERFACE
# declarations, finds none, and answers true — so the class loses its `this` type
# and its ObjectFlagsReference with it. PREDICTION: ungated. NAMED READER:
# checkClassLikeDeclaration's `baseWithThis`, which passes classTypeData.thisType
# as the this ARGUMENT.
old = """        if is_class
            set give_this_type: true
        if give_this_type = false"""
new = """        if give_this_type = false"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g07.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ isThislessInterface FORCED FALSE — every interface gets a `this` type, which
# is the reference's answer for an interface that mentions `this` and the wrong one
# for the other 1 400. PREDICTION: ungated, same reader as g06.
old = """    function is_thisless_interface(this, symbol: ref[Symbol]) returns bool
    {"""
new = """    function is_thisless_interface(this, symbol: ref[Symbol]) returns bool
    {
        return false"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g08.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ isThislessInterface FORCED TRUE — which skips its heritage branch, and with
# it the resolveEntityName report. The extends fixture then stops one call later.
# This is the row that proves the 25-unit resolve-entity-name row is REACHED
# through this predicate and not through some other path.
old = """                    if (AstNode.flags_of(dn) & NodeFlagsContainsThis) <> 0
                        return false
                    if Checker.has_extends_heritage(dn)"""
new = """                    if (AstNode.flags_of(dn) & NodeFlagsContainsThis) <> 0
                        return false
                    if false"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g09.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE ContainsThis TEST REMOVED. The `this` fixture then answers thisless like
# the plain one. PREDICTION: ungated — the two fixtures already answer the same
# tag, which is why they are both in the pin. NAMED READER: the same as g06.
old = """                    if (AstNode.flags_of(dn) & NodeFlagsContainsThis) <> 0
                        return false"""
new = """                    if false
                        return false"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g10.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ has_extends_heritage FORCED FALSE — the extends fixture stops at get-base-types
# instead of resolve-entity-name.
old = """    function has_extends_heritage(node: ref[AstNode]) returns bool
    {"""
new = """    function has_extends_heritage(node: ref[AstNode]) returns bool
    {
        return false"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g11.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE EXTENDS TOKEN TEST DROPPED — an `implements` clause then counts as a base,
# which is the reference's own distinction (GetExtendsHeritageClauseElements) and
# not a detail: a class implementing an interface would resolve names it must not.
old = """                if AstNode.heritage_clause_token_of(c as ref[AstNode]) = KindExtendsKeyword"""
new = """                if true"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g12.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ checkTypeParameterListsIdentical's GUARD REMOVED — every class and interface
# then reports, singly declared ones included.
old = """        if Symbol.declaration_count(symbol) = 1
            return
        this.record_unported("check-type-parameter-lists-identical", 0)"""
new = """        this.record_unported("check-type-parameter-lists-identical", 0)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g13.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE GUARD INVERTED — a MERGED declaration is let through and a single one
# reports. The merged fixture is the only one that moves, which is what makes it
# worth having in the pin.
old = """        if Symbol.declaration_count(symbol) = 1
            return"""
new = """        if Symbol.declaration_count(symbol) <> 1
            return"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g14.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE DEFECT THE SLICE ACTUALLY HAD, restored. `is_unported()` is unit-wide and
# sticky, so a blanket test in the type-parameter arm returns for every parameter
# after the first — and checkTypeNameIsReserved below it never runs. diagcheck is
# the ONLY instrument that can see this: the tags do not move at all.
old = """        let tp_symbol this.symbol_of_declaration(node)
        if tp_symbol <> null
            let tp this.get_declared_type_of_type_parameter(tp_symbol as ref[Symbol])"""
new = """        let tp_symbol this.symbol_of_declaration(node)
        if tp_symbol <> null
        {
            let tp this.get_declared_type_of_type_parameter(tp_symbol as ref[Symbol])
            if this.is_unported()
                return
        }"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g15.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE SAME MISTAKE IN THE INTERFACE ARM — a blanket is_unported() where the
# slice compares against the value captured on entry. Every interface after the
# first declaration in a file then returns before its own check.
old = """        let unported_before this.is_unported()
        this.check_type_parameter_lists_identical(sym)
        if this.is_unported() <> unported_before
            return"""
new = """        let unported_before this.is_unported()
        this.check_type_parameter_lists_identical(sym)
        if this.is_unported()
            return"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g16.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ getTypeWithThisArgument's REFERENCE ARM SKIPPED — it answers the declared type
# unchanged, which is what the reference does when the arities disagree. PREDICTION:
# ungated. NAMED READER: checkInheritedPropertiesAreIdentical, which compares
# typeWithThis against each base — the first consumer of the value at all.
old = """        if (t.object_flags & ObjectFlagsReference) <> 0
        {
            let target Checker.target_of(t)"""
new = """        if false
        {
            let target Checker.target_of(t)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g17.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ getDeclaredTypeOfTypeParameter MADE TO REPORT. The generic fixture is the
# only one in the pin that can move, and it must — it is the fixture that exists to
# show a generic declaration never reaches the class/interface head.
old = """        let links this.declared_type_link_of(symbol)
        if links.declared_type = null
            set links.declared_type: this.new_type_parameter(symbol)
        links.declared_type"""
new = """        this.record_unported("g17-type-parameter-reached", 0)
        let links this.declared_type_link_of(symbol)
        if links.declared_type = null
            set links.declared_type: this.new_type_parameter(symbol)
        links.declared_type"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g18.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE ASK REMOVED from the type-parameter arm — the ported function then has no
# reachable caller at all, because its other one (appendTypeParameters) is a loop
# that cannot run while every generic declaration stops here. PREDICTION: ungated,
# and that IS the row: §3.5be's rule says a port nothing calls is a claim about the
# future, and this measures how little stands between the two.
old = """        let tp_symbol this.symbol_of_declaration(node)
        if tp_symbol <> null
            let tp this.get_declared_type_of_type_parameter(tp_symbol as ref[Symbol])
"""
new = ""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

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
echo "################################################################"
bold "DRY RUN — every patch against a copy, before a single build"
for id in g01 g02 g03 g04 g05 g06 g07 g08 g09 g10 g11 g12 g13 g14 g15 g16 g17 g18; do
  dry_one "$id" "$CHECKER"
done
if [ "$dry_ok" != 1 ]; then
  red "at least one anchor is wrong. Fix them before spending the battery."
  exit 2
fi

baseline

control "g01 the head made to report for EVERY symbol"                   "$CHECKER" "$PATCHDIR/g01.py"
control "g02 the CLASS half of the first arm removed"                    "$CHECKER" "$PATCHDIR/g02.py"
control "g03 getDeclaredTypeOfClassOrInterface answering NULL"           "$CHECKER" "$PATCHDIR/g03.py"
control "g04 the declaredTypeLinks memo made to MISS always"             "$CHECKER" "$PATCHDIR/g04.py"
control "g05 the payload WRITE-BACK dropped"                             "$CHECKER" "$PATCHDIR/g05.py"
control "g06 the kind==Class term dropped from the this-type guard"      "$CHECKER" "$PATCHDIR/g06.py"
control "g07 isThislessInterface forced FALSE"                           "$CHECKER" "$PATCHDIR/g07.py"
control "g08 isThislessInterface's heritage branch skipped"              "$CHECKER" "$PATCHDIR/g08.py"
control "g09 the ContainsThis test removed"                              "$CHECKER" "$PATCHDIR/g09.py"
control "g10 has_extends_heritage forced FALSE"                          "$CHECKER" "$PATCHDIR/g10.py"
control "g11 the EXTENDS token test dropped"                             "$CHECKER" "$PATCHDIR/g11.py"
control "g12 checkTypeParameterListsIdentical's guard removed"           "$CHECKER" "$PATCHDIR/g12.py"
control "g13 that guard INVERTED"                                        "$CHECKER" "$PATCHDIR/g13.py"
control "g14 the STICKY is_unported() guard restored (the real defect)"  "$CHECKER" "$PATCHDIR/g14.py"
control "g15 the same sticky guard in the interface arm"                 "$CHECKER" "$PATCHDIR/g15.py"
control "g16 getTypeWithThisArgument's reference arm skipped"            "$CHECKER" "$PATCHDIR/g16.py"
control "g17 getDeclaredTypeOfTypeParameter made to report"              "$CHECKER" "$PATCHDIR/g17.py"
control "g18 the type-parameter arm's ASK removed"                       "$CHECKER" "$PATCHDIR/g18.py"

echo
echo "################################################################"
bold "RESTORED — checker.scaly, byte-identical"
git -C "$REPO" diff --stat -- "$CHECKER" | tail -3
