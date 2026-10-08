#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice86.sh — the slice-86 battery: THE INSTANTIATION CHAPTER, and a
# chapter that is cheap for one reason nothing at a call site shows.
#
# ★★★ THE SLICE CLOSES THE WORK LIST'S HEAD. `resolve-type-reference-members` was
# 212 units taken FIRST and 295 reached — the largest REACHABLE row since slice 63 —
# and it is now zero, together with the `instantiate-symbol` row the chapter's own
# first draft left behind. What stands in its place is `resolve-anonymous-type-
# members` at 204 first-wins, i.e. the class's STATIC side, which is the successor
# slice 85's own source comment already named.
#
# ★★★ WHAT AN INSTRUMENT CAN SEE HERE IS SLICE 85'S ONE BIT, ONE LEVEL DOWN:
# `check-index-constraint` IN A STOP LOG MEANS AN IndexInfo WAS BUILT — and for a
# CLASS that IndexInfo can only have come out of an INSTANTIATED members table. So
# every pin file below carries an index signature, and every row that breaks the
# mapper, the thisless predicate, the minting branch or the list walks is read off
# whether that line survives. Everything else the chapter produces — the members
# table itself, the properties list, the signatures — still has no reader (slice
# 85's finding, unchanged), which is why so many rows below are ungated ON PURPOSE.
#
# ★★★ THE SLICE ADDS NO DIAGNOSTIC, so diagcheck and the DIAGPIN are purely
# NEGATIVE here — what they are for is to say that a row which moves a stop does
# not also move a report. Slices 67 and 85 had the same shape and said so.
#
# ★★★ ITERATE AT STAGE 1 AND CONFIRM AT STAGE 2 ONCE — slice 64's rule. The
# recorded verdicts are stage 1's.
#
# Usage (nothing may edit the tree while this runs, and no second harness may own
# tests/out — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # stage 1, ~35 s
#   packages/tscaly/tests/controls-slice86.sh 2>&1 | tee /tmp/battery86.log
#
set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.1/tscaly/checker.scaly
AST=$PKG/0.1.1/tscaly/ast.scaly
FIX=$PKG/tests/fixtures

. packages/tscaly/tests/toolchain.sh || exit 2

# ★ ONE MECHANISM PER FILE (slice 72's rule): the tagpin is first-wins, so a fixture
# naming two mechanisms is a fixture nobody can read a red row off.
#
# ★★ THE STOPPIN IS THE INSTRUMENT THAT CARRIES THIS BATTERY, for slice 85's reason
# and one more: a row here typically swaps ONE stop for another inside a single
# unit, which the tagpin (first stop only) and the stopgate (counts over the whole
# corpus) can both miss. The whole log, in order, per fixture, is what separates
# `the members table was built` from `it was not`.
PINFILES="
$FIX/checker_instantiate_class_plain.ts
$FIX/checker_instantiate_class_this_member.ts
$FIX/checker_instantiate_class_untyped_prop.ts
$FIX/checker_instantiate_class_generic.ts
$FIX/checker_instantiate_class_extends.ts
$FIX/checker_instantiate_interface_generic_index.ts
$FIX/checker_members_class_index.ts
$FIX/checker_members_interface_index.ts
$FIX/checker_members_interface_this.ts
$FIX/checker_members_interface_generic.ts
$FIX/checker_members_interface_extends_index.ts
$FIX/checker_members_type_literal_index.ts
"
red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl86)

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
  "$SCALYC" -c --no-prelude -o "$WORK/pkg.o" "$PKG/0.1.1/tscaly.scaly" > "$WORK/build.log" 2>&1 || return 1
  "$SCALYC" -c -o "$WORK/types.o" "$PKG/0.1.1/tscaly_types.scaly" >> "$WORK/build.log" 2>&1 || return 1
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

# The MEMBERPIN — the SIXTH instrument, and the one this battery exists for.
#
# ★★★ ITS ARGUMENT IS A MEASUREMENT: the first run of this battery put thirty-three
# rows against five instruments and TWENTY-NINE came back completely silent, every
# one of them for the same reason — the chapter's product is a members table whose
# only reader is checkIndexConstraints' `is the index-info list empty` test. **A
# battery whose rows are silent for one shared reason is measuring the absence of a
# reader, not the slice.** The member log (see MemberEvent in checker.scaly) prints
# what those rows actually move: per resolved type its object flags and counts, and
# per property its name, symbol flags, CHECK flags and declaration count — where
# check flags 1 means the member was MINTED and 0 means it came back unchanged.
members_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$("$WORK/tscaly_types" --members "$f" 2>/dev/null | tr '\n' '|')"
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
  bold "BASELINE — six instruments"
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
  members_of > "$WORK/base.members"
  STOP_BASE=$(stopgate)
  echo
  echo "  the STOPPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.stops"
  echo
  echo "  the MEMBERPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.members"
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
  members_of > "$WORK/ctl.members"
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
    echo "  diagpin   unmoved — all twelve pin files answer the same C section."
  else
    green "diagpin   RED"
    diff "$WORK/base.diags" "$WORK/ctl.diags" | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.tags" "$WORK/ctl.tags"; then
    echo "  tagpin    unmoved — all twelve fixtures answer the same tag."
  else
    green "tagpin    RED"
    diff "$WORK/base.tags" "$WORK/ctl.tags" | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.stops" "$WORK/ctl.stops"; then
    echo "  stoppin   unmoved — all twelve fixtures log the same stops, in order."
  else
    green "stoppin   RED"
    diff "$WORK/base.stops" "$WORK/ctl.stops" | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.members" "$WORK/ctl.members"; then
    echo "  memberpin unmoved — all twelve fixtures resolve the same members."
  else
    green "memberpin RED"
    diff "$WORK/base.members" "$WORK/ctl.members" | sed 's/^/    /'
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
      echo "  ungated on all six, WITH A NUMBER: $DIAG_LINES/$DIAG_DIAGS -> $speaking/$diags."
    else
      red "UNGATED ON ALL SIX AND NOTHING MOVED AT ALL."
      echo "  Decide which of §3.5v's four kinds this is. A row that predicted"
      echo "  this is a measurement; a row that did not is a hole in the battery."
    fi
  fi
  return 0
}

PATCHDIR=$WORK/patches
mkdir -p "$PATCHDIR"

cat > "$PATCHDIR/g01.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# THE PREMISE. PREDICTION: STOPPIN RED on every class and every generic interface,
# STOPGATE moved by the whole chapter, `resolve-type-reference-members` back on the
# work list at 295 units. diagcheck cannot move: the slice adds no diagnostic.
old = """                if (t.object_flags & ObjectFlagsReference) <> 0
                    this.resolve_type_reference_members(t)"""
new = """                if (t.object_flags & ObjectFlagsReference) <> 0
                    this.record_unported("resolve-type-reference-members", t.object_flags)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g02.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# newTypeMapper's one-entry case removed: every mapper is the ARRAY arm.
# PREDICTION: UNGATED, and a PROOF — ArrayTypeMapper.MapsThisOnly asks exactly the
# same question of a single source, so the two arms coincide for every mapper this
# chapter builds and the simple one is fidelity rather than behaviour.
old = """        if n = 1
        {
            let src sources as ref[Array[ref[Type]?]]"""
new = """        if false
        {
            let src sources as ref[Array[ref[Type]?]]"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g03.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# MapsThisOnly forced FALSE: the fast path that answers a thisless member unchanged
# never fires, so every member of every class is MINTED.
# PREDICTION: STOPPIN unmoved and STOPGATE moved — the minting branch works, so the
# tables still come out, but every instantiated member now asks
# getTypeOfInstantiatedSymbol and some of those asks stop.
old = """    function type_mapper_maps_this_only(m: ref[TypeMapper]) returns bool
    {"""
new = """    function type_mapper_maps_this_only(m: ref[TypeMapper]) returns bool
    {
        if true
            return false"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g04.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# isThisless forced TRUE: every member takes the fast path, including the ones the
# reference instantiates. PREDICTION: STOPPIN RED on class_this_member,
# class_untyped_prop and class_generic — the three fixtures whose members are NOT
# thisless — because their minting stops disappear.
old = """    function is_thisless(symbol: ref[Symbol]) returns bool
    {
        if Symbol.declaration_count(symbol) <> 1"""
new = """    function is_thisless(symbol: ref[Symbol]) returns bool
    {
        if true
            return true
        if Symbol.declaration_count(symbol) <> 1"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g05.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# isThislessType's KEYWORD list emptied — only ArrayType and TypeReference remain
# thisless. PREDICTION: STOPPIN moved on class_plain, whose only member is
# `a: string`: the keyword is what makes it thisless.
# The keyword chain appears twice in this file (getTypeFromTypeNode has one too),
# so the anchor is taken INSIDE is_thisless_type rather than globally.
i = s.index("function is_thisless_type(")
old = """        if k = KindStringKeyword
            return true
        if k = KindNumberKeyword
            return true"""
new = """        if k = KindStringKeyword
            return false
        if k = KindNumberKeyword
            return false"""
j = s.index(old, i)
open(p, "w").write(s[:j] + new + s[j+len(old):])
PY

cat > "$PATCHDIR/g06.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# isThislessType's TypeReference arm answers FALSE instead of walking the type
# ARGUMENTS. PREDICTION: ungated with a number, or ungated — no pin file has a
# member whose annotation is a type reference, and the corpus decides the rest.
old = """            let args AstNode.type_arguments_of(node)
            let n AstNode.list_count(args)
            var i 0
            while i < n
            {
                let a AstNode.child_in_list(args, i)
                if a = null
                    return false
                if Checker.is_thisless_type(a as ref[AstNode]) = false
                    return false
                set i: i + 1
            }
            return true"""
new = """            return false"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g07.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# isThislessVariableLikeDeclaration's SECOND arm inverted: no annotation and an
# INITIALIZER now counts as thisless, where the reference says the opposite.
# PREDICTION: STOPPIN RED on class_untyped_prop — the fixture that exists for
# exactly this arm.
old = """        if type_node <> null
            return Checker.is_thisless_type(type_node as ref[AstNode])
        AstNode.initializer_of(node) = null"""
new = """        if type_node <> null
            return Checker.is_thisless_type(type_node as ref[AstNode])
        AstNode.initializer_of(node) <> null"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g08.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# isThislessFunctionLikeDeclaration's CONSTRUCTOR disjunct removed: a constructor
# has no return annotation, so it stops being thisless.
# PREDICTION: ungated on the pin files (none of them has a constructor) but a
# NUMBER on the corpus — the stopgate should move.
old = """        if AstNode.kind_of(node) <> KindConstructor
        {
            let return_type AstNode.type_of(node)"""
new = """        if true
        {
            let return_type AstNode.type_of(node)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g09.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# isThisless' one-declaration test relaxed to `take the first of a merge`.
# PREDICTION: ungated on the pin files, a number on the corpus — a MERGED member
# symbol is rare and the direction is towards FEWER mints, not more.
old = """        if Symbol.declaration_count(symbol) <> 1
            return false
        let d Symbol.declaration_at(symbol, 0)"""
new = """        if Symbol.declaration_count(symbol) = 0
            return false
        let d Symbol.declaration_at(symbol, 0)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g10.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# couldContainTypeVariables' StructuredOrInstantiable guard inverted, so a
# primitive answers TRUE. PREDICTION: STOPGATE moved hard — instantiateType then
# enters the worker for every `string` and `number` and the worker's arms report.
old = """        if (t.flags & TypeFlagsStructuredOrInstantiable) = 0
            return false
        if (t.object_flags & ObjectFlagsCouldContainTypeVariablesComputed) <> 0"""
new = """        if (t.flags & TypeFlagsStructuredOrInstantiable) <> 0
            return false
        if (t.object_flags & ObjectFlagsCouldContainTypeVariablesComputed) <> 0"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g11.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# couldContainTypeVariables' MEMO removed. PREDICTION: UNGATED — slice 84's g02 and
# slice 85's g02 for a third time. A memo pays only where the same question is
# asked twice, and the answers this chapter needs are asked once per type.
old = """        if (t.object_flags & ObjectFlagsCouldContainTypeVariablesComputed) <> 0
            return (t.object_flags & ObjectFlagsCouldContainTypeVariables) <> 0"""
new = """        if false
            return (t.object_flags & ObjectFlagsCouldContainTypeVariables) <> 0"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g12.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# couldContainTypeVariables' INSTANTIABLE arm removed: a type parameter stops
# counting as something that could contain one. PREDICTION: STOPPIN moved on
# class_generic — instantiateType then answers `T` unchanged instead of mapping it.
old = """        var result false
        if (t.flags & TypeFlagsInstantiable) <> 0
            set result: true"""
new = """        var result false
        if false
            set result: true"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g13.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# couldContainTypeVariables' REFERENCE arm: the walk over the type arguments
# dropped, so a generic reference answers false. PREDICTION: ungated with a number
# — the walk's own answer is false for every reference in the pin files (a
# non-generic class's argument list is EMPTY).
old = """                    if (t.object_flags & ObjectFlagsReference) <> 0
                    {"""
new = """                    if false
                    {"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g14.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# couldContainTypeVariables' ANONYMOUS arm removed. PREDICTION: ungated — the
# anonymous types this port makes are a class's static side and a type literal, and
# neither is handed to instantiateType by anything that has landed.
old = """                    if (t.object_flags & ObjectFlagsAnonymous) <> 0
                    {
                        if t.symbol <> null"""
new = """                    if false
                    {
                        if t.symbol <> null"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g15.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# instantiateType's `could = false` early return removed: every type goes into the
# worker. PREDICTION: STOPGATE moved hard, and it is the other half of g10 — the
# predicate is the whole gate in front of the seven unported arms.
old = """        if could = false
            return t
        if instantiation_depth = 100"""
new = """        if false
            return t
        if instantiation_depth = 100"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g16.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# instantiateTypeWorker's TypeParameter arm answers the type UNCHANGED instead of
# mapping it — the one line the whole mapper exists for.
# PREDICTION: STOPPIN moved on class_generic, and on nothing else: it is the only
# pin file whose mapper has a source anything asks about.
old = """        if (t.flags & TypeFlagsTypeParameter) <> 0
            return Checker.type_mapper_map(m, t)"""
new = """        if (t.flags & TypeFlagsTypeParameter) <> 0
            return t"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g17.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# instantiateTypeWorker's Reference arm: the `nothing changed` identity test
# dropped, so a fresh type reference is minted every time.
# PREDICTION: ungated — createTypeReference's instantiation list answers the SAME
# object for the same arguments, so the two spellings coincide. A proof that the
# identity test is a saving and not a semantics.
old = """                if mapped = args
                    return t
                let target Checker.target_of(t)"""
new = """                if false
                    return t
                let target Checker.target_of(t)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g18.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# instantiateTypes' unchanged-list identity broken: it always answers a FRESH
# array. PREDICTION: read beside g17 — the caller's `mapped = args` test then never
# holds, so this row and that one are one mechanism from two sides.
old = """            if mapped <> list[i]
            {
                let out this.new_type_list(null)"""
new = """            if true
            {
                let out this.new_type_list(null)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g19.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# instantiateSymbol's MapsThisOnly fast path removed. PREDICTION: read beside g03 —
# the same effect reached from the caller's side rather than the mapper's, and the
# pair is what says the two halves of that test are ONE mechanism.
old = """        if m <> null
        {
            if Checker.type_mapper_maps_this_only(m as ref[TypeMapper])
            {
                if Checker.is_thisless(sym)
                    return symbol
            }
        }"""
new = """        if false
        {
            if Checker.type_mapper_maps_this_only(m as ref[TypeMapper])
            {
                if Checker.is_thisless(sym)
                    return symbol
            }
        }"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g20.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# instantiateSymbol's SECOND fast path removed — the resolved-type-cannot-contain-
# a-type-variable one. PREDICTION: ungated or a number: the first fast path already
# takes every member of a non-generic class, so this one only sees what that one
# rejected.
old = """        if links.resolved_type <> null
        {
            let mark this.unported_mark()
            let could this.could_contain_type_variables(links.resolved_type as ref[Type])"""
new = """        if false
        {
            let mark this.unported_mark()
            let could this.could_contain_type_variables(links.resolved_type as ref[Type])"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g21.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The MINTING branch reverted to the stop the chapter's own first draft had.
# PREDICTION: STOPPIN RED on class_this_member, class_untyped_prop and
# class_generic, and the STOPGATE moved by 73 units — this is the half of the slice
# that made `instantiate-symbol` a row of its own for one afternoon.
old = """        let result this.new_symbol(Symbol.flags_of(sym), Symbol.name_data_of(sym), Symbol.name_len_of(sym))"""
new = """        this.record_unported("instantiate-symbol", Symbol.flags_of(sym))
        if true
            return null
        let result this.new_symbol(Symbol.flags_of(sym), Symbol.name_data_of(sym), Symbol.name_len_of(sym))"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g22.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The minted symbol's CheckFlagsInstantiated never set, so getTypeOfSymbol takes
# the ordinary arm and answers the UNinstantiated type.
# PREDICTION: this is the silent direction and the battery may not see it — a
# member's type has no reader in this chapter. A row that comes back ungated prices
# exactly that.
old = """        Symbol.set_check_flags(result, CheckFlagsInstantiated)"""
new = """        Symbol.set_check_flags(result, CheckFlagsNone)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g23.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The transient symbol's declarations / valueDeclaration / parent not copied.
# PREDICTION: STOPPIN or STOPGATE moved — getNamedMembers and the index-info walk
# both ask a member symbol for its declarations, so an empty list is visible where
# the TYPE is not.
old = """        Symbol.copy_declarations_from(result, sym)"""
new = """        if false
            Symbol.copy_declarations_from(result, sym)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g24.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# getTypeOfInstantiatedSymbol's memo removed. PREDICTION: ungated — the third memo
# in three slices with no observable hit, unless a member's type is asked twice.
old = """        let links this.value_symbol_link_of(symbol)
        if links.resolved_type <> null
            return links.resolved_type
        if links.target = null"""
new = """        let links this.value_symbol_link_of(symbol)
        if false
            return links.resolved_type
        if links.target = null"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g25.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# instantiateSymbolTable answers the SOURCE table instead of a fresh one.
# PREDICTION: ungated here and a hazard elsewhere — the copy exists so that the
# base loop does not fold inherited members into the DECLARED table, and no type in
# this corpus has a base type at all (slice 85's g11).
old = """        let out SymbolTable.create(host)
        let mark this.unported_mark()
        var i 0
        while i < n
        {
            let sym SymbolTable.entry_symbol_at(symbols, i)"""
new = """        let out symbols as ref[SymbolTable]
        let mark this.unported_mark()
        var i 0
        while i < n
        {
            let sym SymbolTable.entry_symbol_at(symbols, i)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g26.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# resolveObjectTypeMembers: the instantiating branch never taken, so the DECLARED
# lists are used for a type reference as they are.
# PREDICTION: STOPPIN unmoved on most and STOPGATE moved — the members come out
# uninstantiated, which is a wrong TABLE rather than a missing one, and the only
# thing that can see it is a member whose type had to be mapped.
old = """        if Checker.type_lists_equal(type_parameters, type_arguments) = false
        {
            set instantiated: true"""
new = """        if false
        {
            set instantiated: true"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g27.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The base loop's getTypeWithThisArgument arm removed. PREDICTION: UNGATED, and it
# is slice 85's g11 finding one level on: `base_count` is ZERO at every arrival, so
# the loop this arm lives in does not run at all.
old = """                if this_argument <> null
                {
                    let inst this.instantiate_type(row, mapper)"""
new = """                if false
                {
                    let inst this.instantiate_type(row, mapper)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g28.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# resolveTypeReferenceMembers' PADDING removed: the mapper's targets are then one
# short and the thisType maps to nothing.
# PREDICTION: STOPPIN or STOPGATE moved — a simple mapper whose target is null is
# what `this` becomes, and the members table is built from it.
old = """        if tan = (tpn - 1)
        {
            let combined this.new_type_list(type_arguments)"""
new = """        if false
        {
            let combined this.new_type_list(type_arguments)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g29.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# resolveTypeReferenceMembers' SOURCE taken as the type itself rather than as its
# target. PREDICTION: UNGATED, and a PROOF — every type that reaches this function
# is its own target, because the only Reference types this port makes are the
# declared types getDeclaredTypeOfClassOrInterface builds with `d.target = t`.
old = """        let source target as ref[Type]
        let type_parameters Checker.all_type_parameters_of(source)"""
new = """        let source t
        let type_parameters Checker.all_type_parameters_of(source)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g30.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# resolveBaseTypesOfClass' flags guard inverted, so a base-LESS class falls through
# to the report. PREDICTION: STOPPIN RED on every class fixture — it is the row
# that says the guard is what makes the class arm answer at all.
old = """        if (base_ctor.flags & (TypeFlagsObject | TypeFlagsIntersection | TypeFlagsAny)) = 0
            return
        this.record_unported("resolve-base-types-of-class", base_ctor.flags)"""
new = """        if (base_ctor.flags & (TypeFlagsObject | TypeFlagsIntersection | TypeFlagsAny)) <> 0
            return
        this.record_unported("resolve-base-types-of-class", base_ctor.flags)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g31.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# resolveBaseTypesOfClass reverted to the plain stop it was before the slice.
# PREDICTION: STOPPIN RED on every class fixture and the STOPGATE moved — the class
# arm of getBaseTypes is on 274 units now where it used to be on none.
old = """                this.resolve_base_types_of_class(t)
                if this.unported_mark() <> before"""
new = """                this.record_unported("resolve-base-types-of-class", 0)
                if this.unported_mark() <> before"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g32.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# getReturnTypeOfSignature's INSTANTIATED arm removed, so an instantiated signature
# answers its target's ANNOTATION with the mapper never applied.
# PREDICTION: ungated — a class's declared call-signature list is empty, so
# instantiateSignature has nothing to make and the arm has nothing to read. The row
# prices the arm rather than gating it, and it is written because the alternative
# was to leave the slot unread (see Signature's header).
old = """        if sig.target <> null
        {
            let inner this.get_return_type_of_signature(sig.target as ref[Signature])"""
new = """        if false
        {
            let inner this.get_return_type_of_signature(sig.target as ref[Signature])"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g33.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# instantiateIndexInfo's unchanged-value identity test dropped: a fresh IndexInfo
# every time. PREDICTION: STOPPIN unmoved (the key type is what
# checkIndexConstraints reads and it is copied) but the row is worth having,
# because a fresh IndexInfo breaks the IDENTITY findIndexInfo compares on.
old = """        if new_value = i.value_type
            return info"""
new = """        if false
            return info"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

DRY=$WORK/dry
for g in g01 g02 g03 g04 g05 g06 g07 g08 g09 g10 g11 g12 g13 g14 g15 g16 g17 g18 g19 g20 g21 g22 g23 g24 g25 g26 g27 g28 g29 g30 g31 g32 g33; do
  rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
  if python3 "$PATCHDIR/$g.py" "$DRY/f.scaly" >/dev/null 2>&1; then
    echo "  $g applies"
  else
    red "  $g DOES NOT APPLY — its anchor has moved."; exit 2
  fi
done
rm -rf "$DRY"

baseline

control "g01 the Reference arm reverted to its stop (the premise)" $CHECKER "$PATCHDIR/g01.py"
control "g02 newTypeMapper's one-entry case removed" $CHECKER "$PATCHDIR/g02.py"
control "g03 MapsThisOnly forced false" $CHECKER "$PATCHDIR/g03.py"
control "g04 isThisless forced true" $CHECKER "$PATCHDIR/g04.py"
control "g05 isThislessType's string/number keywords made NOT thisless" $CHECKER "$PATCHDIR/g05.py"
control "g06 isThislessType's TypeReference arm answers false" $CHECKER "$PATCHDIR/g06.py"
control "g07 isThislessVariableLikeDeclaration's initializer arm inverted" $CHECKER "$PATCHDIR/g07.py"
control "g08 isThislessFunctionLikeDeclaration's constructor disjunct removed" $CHECKER "$PATCHDIR/g08.py"
control "g09 isThisless' one-declaration test relaxed" $CHECKER "$PATCHDIR/g09.py"
control "g10 couldContainTypeVariables' StructuredOrInstantiable guard inverted" $CHECKER "$PATCHDIR/g10.py"
control "g11 couldContainTypeVariables' memo removed" $CHECKER "$PATCHDIR/g11.py"
control "g12 couldContainTypeVariables' Instantiable arm removed" $CHECKER "$PATCHDIR/g12.py"
control "g13 couldContainTypeVariables' Reference arm removed" $CHECKER "$PATCHDIR/g13.py"
control "g14 couldContainTypeVariables' Anonymous arm removed" $CHECKER "$PATCHDIR/g14.py"
control "g15 instantiateType's couldContain gate removed" $CHECKER "$PATCHDIR/g15.py"
control "g16 instantiateTypeWorker's TypeParameter arm made the identity" $CHECKER "$PATCHDIR/g16.py"
control "g17 instantiateTypeWorker's Reference identity test dropped" $CHECKER "$PATCHDIR/g17.py"
control "g18 instantiateTypes always answers a fresh list" $CHECKER "$PATCHDIR/g18.py"
control "g19 instantiateSymbol's MapsThisOnly fast path removed" $CHECKER "$PATCHDIR/g19.py"
control "g20 instantiateSymbol's resolved-type fast path removed" $CHECKER "$PATCHDIR/g20.py"
control "g21 the MINTING branch reverted to a stop" $CHECKER "$PATCHDIR/g21.py"
control "g22 the minted symbol's CheckFlagsInstantiated never set" $CHECKER "$PATCHDIR/g22.py"
control "g23 the minted symbol's declarations not copied" $CHECKER "$PATCHDIR/g23.py"
control "g24 getTypeOfInstantiatedSymbol's memo removed" $CHECKER "$PATCHDIR/g24.py"
control "g25 instantiateSymbolTable answers the SOURCE table" $CHECKER "$PATCHDIR/g25.py"
control "g26 resolveObjectTypeMembers' instantiating branch never taken" $CHECKER "$PATCHDIR/g26.py"
control "g27 the base loop's getTypeWithThisArgument arm removed" $CHECKER "$PATCHDIR/g27.py"
control "g28 resolveTypeReferenceMembers' padding removed" $CHECKER "$PATCHDIR/g28.py"
control "g29 resolveTypeReferenceMembers' source taken as the type itself" $CHECKER "$PATCHDIR/g29.py"
control "g30 resolveBaseTypesOfClass' flags guard inverted" $CHECKER "$PATCHDIR/g30.py"
control "g31 resolveBaseTypesOfClass reverted to a plain stop" $CHECKER "$PATCHDIR/g31.py"
control "g32 getReturnTypeOfSignature's instantiated arm removed" $CHECKER "$PATCHDIR/g32.py"
control "g33 instantiateIndexInfo's unchanged-value test dropped" $CHECKER "$PATCHDIR/g33.py"

echo
echo "################################################################"
bold "DONE — read every row against its PREDICTION, not against its colour."
