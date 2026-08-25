#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice67.sh — the slice-67 battery: THE BASE TYPES AND THE STATIC SIDE
# OF A CLASS. getTypeOfSymbol's dispatch, getTypeOfFuncClassEnumModule and its
# worker, getBaseTypeVariableOfClass, getBaseConstructorTypeOfClass, getBaseTypes
# with resolveBaseTypesOfInterface, checkInheritedPropertiesAreIdentical, the
# type-resolution stack that three of them share, the valueSymbolLinks table —
# and, in the BINDER, the seenThisKeyword field whose absence had made slice 66's
# isThislessInterface answer wrong.
#
# ★★★ THE BATTERY SPANS TWO FILES BECAUSE THE SLICE DOES, and the binder half is
# the more interesting one: rows g16 and g17 break a checker predicate and a
# binder assignment respectively, and BOTH move the same fixture's tag. That is
# the only evidence in this suite that the two halves are one mechanism — no
# binder dump carries a node's flags, so the checker's tag is the whole witness.
#
# ★★★ ROW g09 IS A ROW SLICE 66 COULD NOT WRITE. Its g11 broke the EXTENDS-token
# test in the heritage walk and came back ungated with a PROOF: the only caller
# was isThislessInterface, an interface cannot carry `implements`, so the test
# could not distinguish anything "until a class asks". This slice is the class
# asking, and the row is red. A conservative-looking argument and a real gap look
# alike from outside; what separates them is the slice that adds the caller.
#
# ★★ TWO INSTRUMENTS, as in slices 56-66: diagcheck over the whole corpus, and a
# PIN over nine fixtures' unported TAGS. The nine are chosen so each pins a
# DIFFERENT path: a plain class, a class with `extends`, a class with
# `implements`, a class merged with a namespace, a rest parameter, a plain
# interface, an interface with `this` AND `extends` (the only shape that reaches
# resolveBaseTypesOfInterface's loop), an interface with `extends` alone (which
# is claimed one call earlier), and a generic class (which never reaches the head
# at all).
#
# ★★★ THE SLICE ADDS NO DIAGNOSTIC, SO DIAGCHECK IS A NEGATIVE INSTRUMENT HERE —
# it can only go red by LOSING one. It stays at 167/340 on every row below, which
# is the statement that nothing this slice touches sits in front of a report. The
# pin is what carries the battery, and that division of labour is the opposite of
# slices 62-64, where most rows broke a live report.
#
# ★★★ ITERATE AT STAGE 1 AND CONFIRM AT STAGE 2 ONCE — slice 64's rule.
#
# Usage (nothing may edit the tree while this runs — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # stage 1, ~25 s
#   packages/tscaly/tests/controls-slice67.sh 2>&1 | tee /tmp/battery67.log
#   TSCALY_STAGE=2 packages/tscaly/tests/run.sh       # ~7 min, ONCE
#   packages/tscaly/tests/controls-slice67.sh 2>&1 | tee /tmp/battery67-s2.log

set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.0/tscaly/checker.scaly
BINDER=$PKG/0.1.0/tscaly/binder.scaly
FIX=$PKG/tests/fixtures

LIBSCALY=${LIBSCALY:-/tmp/libscaly.a}
SCALYC=${SCALYC:-$REPO/scalyc/build/scalyc}

# The fixtures the PIN reads.
TAGFILES="
$FIX/checker_static_type_class_plain.ts
$FIX/checker_static_type_class_extends.ts
$FIX/checker_static_type_class_implements.ts
$FIX/checker_static_type_class_merged.ts
$FIX/checker_static_type_rest_parameter.ts
$FIX/checker_base_types_interface_plain.ts
$FIX/checker_base_types_interface_this_extends.ts
$FIX/checker_declared_type_interface_extends.ts
$FIX/checker_declared_type_class_generic.ts
"

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  echo "Both instruments compare against the reference dumps that run produced."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl67)

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
    echo "  pin       unmoved — all nine fixtures answer the same tag."
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
# ★★★ getTypeOfSymbol's FUNCTION/CLASS/ENUM/MODULE ARM REMOVED — a class symbol
# then falls out of the chain and gets errorType as its static side. PREDICTION:
# ungated on both instruments, because nothing in this slice READS the static
# type: checkClassLikeDeclaration binds it to `staticType` and the first consumer
# is checkMembersForOverrideModifier, three reports further on. It is the sharpest
# available statement of what this slice cannot measure.
old = """        if (f & (SymbolFlagsFunction | SymbolFlagsMethod | SymbolFlagsClass | SymbolFlagsEnum | SymbolFlagsValueModule)) <> 0
            return this.get_type_of_func_class_enum_module(symbol)"""
new = """        if false
            return this.get_type_of_func_class_enum_module(symbol)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g02.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE VARIABLE/PROPERTY ARM REMOVED. Those symbols then fall through to
# errorType with no report, so the three call sites carry on to their own next
# stop — which is the loudest way to show that the 4 694-unit row this slice
# renamed is a real stop and not a label.
old = """        if (f & (SymbolFlagsVariable | SymbolFlagsProperty)) <> 0
        {
            this.record_unported("get-type-of-variable-or-parameter-or-property", 0)
            return null
        }"""
new = """        if false
        {
            this.record_unported("get-type-of-variable-or-parameter-or-property", 0)
            return null
        }"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g03.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE HEAD MADE TO REPORT FOR EVERY SYMBOL — the cheapest statement of *is
# getTypeOfSymbol on the path at all*, and the answer is a count rather than an
# argument.
old = """    function get_type_of_symbol(this, symbol: ref[Symbol]) returns ref[Type]?
    {
        let f Symbol.flags_of(symbol)"""
new = """    function get_type_of_symbol(this, symbol: ref[Symbol]) returns ref[Type]?
    {
        this.record_unported("g03-head-reached", 0)
        let f Symbol.flags_of(symbol)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g04.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE valueSymbolLinks MEMO MADE TO MISS ALWAYS — every ask mints a fresh row
# and a fresh static type. PREDICTION: ungated. Nothing in this slice asks twice;
# checkClassLikeDeclaration asks once per class and checkClassExpression, the
# second caller, is unported. NAMED READER: checkMembersForOverrideModifier,
# which compares the static type against the base's by IDENTITY.
old = """                let r row as ref[ValueSymbolLink]
                if r.symbol = sym
                    return r"""
new = """                let r row as ref[ValueSymbolLink]
                if r.symbol = null
                    return r"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g05.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ newObjectType's ANONYMOUS ARM PUT BACK THE WAY SLICE 66 LEFT IT — reporting.
# It stands in front of the class arm in the worker, so both class fixtures move.
old = """        if (object_flags & ObjectFlagsAnonymous) <> 0
            return this.new_type(TypeFlagsObject, object_flags, sym, TypeData.Anonymous(AnonymousTypeData()))"""
new = """        if (object_flags & ObjectFlagsAnonymous) <> 0
        {
            this.record_unported("new-object-type-anonymous", 0)
            return null
        }"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g06.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ getBaseTypeVariableOfClass FORCED TO ANSWER A TYPE — every class then looks
# like a mixin and the intersection report fires. It is the row that proves the
# nil answer is what carries the ordinary class through.
old = """        if (bt.flags & TypeFlagsTypeVariable) <> 0
            return bt"""
new = """        if true
            return bt"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g07.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ getBaseTypeNodeOfClass FORCED TO ANSWER NOTHING — a class with `extends`
# then takes the undefinedType early return like a bare one. The row that prices
# the 97.5 % / 2.5 % split from the other side.
old = """    function get_base_type_node_of_class(t: ref[Type]) returns ref[AstNode]?
    {"""
new = """    function get_base_type_node_of_class(t: ref[Type]) returns ref[AstNode]?
    {
        return null"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g08.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE BASE-CONSTRUCTOR MEMO WRITE DROPPED — the answer is still undefinedType,
# it is simply recomputed. PREDICTION: ungated; getBaseConstructorTypeOfClass is
# asked once per class here. NAMED READERS: resolveBaseTypesOfClass and
# checkClassLikeDeclaration's heritage branch, which ask a second and third time,
# and typeResolutionHasProperty, whose ResolvedBaseConstructorType arm IS this
# slot and which therefore cannot see a cycle without it.
old = """            Checker.set_resolved_base_constructor_type(t, undefined_type)
            return undefined_type"""
new = """            return undefined_type"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g09.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE EXTENDS-TOKEN TEST DROPPED — an `implements` clause then counts as a
# base. THIS IS THE ROW SLICE 66 COULD NOT WRITE: its g11 broke the same line and
# came back ungated with the argument that only an interface ever asked, and an
# interface cannot carry `implements`. Slice 67 adds the class as a caller.
old = """                if AstNode.heritage_clause_token_of(c as ref[AstNode]) = KindExtendsKeyword"""
new = """                if true"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g10.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE baseTypesResolved MEMO MADE TO MISS ALWAYS — getBaseTypes recomputes on
# every ask, and checkInterfaceDeclaration asks TWICE (through
# checkInheritedPropertiesAreIdentical and again for the loop). PREDICTION:
# ungated, because both computations answer the same EMPTY list on this corpus.
# NAMED READER: the day resolveBaseTypesOfInterface appends, a second computation
# doubles the list and `len < 2` stops being true — so the memo is what will make
# the guard mean what it says.
old = """        if Checker.base_types_resolved_of(t) = false
        {"""
new = """        if true
        {"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g11.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ getBaseTypes' RESOLUTION PUSH MADE TO FAIL — the function then answers the
# unresolved list and never walks the declarations at all.
old = """            if this.push_type_resolution(null, t, TypeSystemPropertyNameResolvedBaseTypes) = false
                return Checker.resolved_base_types_of(t)"""
new = """            if true
                return Checker.resolved_base_types_of(t)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g12.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ resolveBaseTypesOfInterface's LOOP BODY EMPTIED — the one shape that
# reaches it then falls through to an empty base list like every other interface.
old = """                            this.record_unported("get-type-from-type-node", KindExpressionWithTypeArguments)
                            return"""
new = """                            set j: j + 1"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g13.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE INTERFACE ARM OF getBaseTypes' SWITCH SKIPPED — the declarations are
# never walked, so the base list stays empty and nothing reports. PREDICTION: PIN
# RED on the one fixture that reaches the loop, and nothing else.
old = """            if (sf & SymbolFlagsInterface) <> 0
            {
                this.resolve_base_types_of_interface(t)"""
new = """            if false
            {
                this.resolve_base_types_of_interface(t)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g14.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE CLASS ARM OF getBaseTypes MADE TO CLAIM INTERFACES — it is an arm that
# stands in place and reports, and this is the row that shows the arm is REACHED
# by the switch rather than merely written down.
old = """            if (sf & SymbolFlagsClass) <> 0
            {
                this.pop_type_resolution()
                this.record_unported("resolve-base-types-of-class", 0)"""
new = """            if true
            {
                this.pop_type_resolution()
                this.record_unported("resolve-base-types-of-class", 0)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g15.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ checkInheritedPropertiesAreIdentical's `len(baseTypes) < 2` GUARD REMOVED —
# every interface then reports resolveDeclaredMembers, which is the members
# dimension claiming units that belong to nobody yet.
old = """        if n < 2
            return true
        this.record_unported("resolve-declared-members", 0)"""
new = """        this.record_unported("resolve-declared-members", 0)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g16.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE ContainsThis TEST REMOVED FROM isThislessInterface — SLICE 66's g09,
# RUN AGAIN. There it was ungated, and its reason was recorded as "the `this`
# fixture and the plain one already answer the same tag". The truer reason was
# that the flag had NO WRITER in this port at all, so the line was dead. Slice 67
# gives it one, and the row is red.
old = """                    if (AstNode.flags_of(dn) & NodeFlagsContainsThis) <> 0
                        return false"""
new = """                    if false
                        return false"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g17.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE BINDER HALF: the `this` TYPE stops setting seenThisKeyword. It is the
# SAME red as g16 through a different file, and the pair is the only evidence
# this suite has that the binder's flag and the checker's predicate are one
# mechanism — no dump carries a node's flags after a bind.
old = """        if k = KindThisType
            set seen_this_keyword: true"""
new = """        if k = KindThisType
            set seen_this_keyword: false"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g18.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE INTERFACE BRANCH'S RESET DROPPED — seenThisKeyword then leaks in from
# whatever was bound before the interface. PREDICTION: ungated on this pin. The
# reset only matters when a `this` occurs EARLIER in the same file than an
# interface whose thisless-ness is then asked, and no fixture has that shape
# because the earlier `this` would have to be outside any interface — i.e. in a
# function body, which is the control-flow branch this port does not have.
old = """            let save_seen_this seen_this_keyword
            set seen_this_keyword: false
            this.bind_children(n)"""
new = """            let save_seen_this seen_this_keyword
            this.bind_children(n)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g19.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE DEFENSIVE POP REMOVED from getBaseConstructorTypeOfClass' reporting
# exit. PREDICTION: ungated, and the row exists to PRICE a line that is ours
# rather than the reference's. The leaked frame can only matter when a LATER push
# in the same file collides with it, and every fixture stops before a second one.
old = """        this.pop_type_resolution()
        this.record_unported("check-expression", KindExpressionWithTypeArguments)"""
new = """        this.record_unported("check-expression", KindExpressionWithTypeArguments)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g20.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ checkClassLikeDeclaration's ASK REMOVED — the class never reaches its
# static side and stops at checkTypeParameterListsIdentical instead. It is the
# row that measures how much of this slice hangs on ONE statement: without it,
# getTypeOfFuncClassEnumModule, the anonymous arm, getBaseTypeVariableOfClass and
# getBaseConstructorTypeOfClass all have no reachable caller at all (§3.5be).
old = """        let static_type this.get_type_of_symbol(sym)
        if this.is_unported() <> unported_before
            return
"""
new = ""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

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
for id in g01 g02 g03 g04 g05 g06 g07 g08 g09 g10 g11 g12 g13 g14 g15 g16 g19 g20; do
  dry_one "$id" "$CHECKER"
done
for id in g17 g18; do
  dry_one "$id" "$BINDER"
done
if [ "$dry_ok" != 1 ]; then
  red "at least one anchor is wrong. Fix them before spending the battery."
  exit 2
fi

baseline

control "g01 getTypeOfSymbol's func/class/enum/module arm removed"        "$CHECKER" "$PATCHDIR/g01.py"
control "g02 the variable/property arm removed"                           "$CHECKER" "$PATCHDIR/g02.py"
control "g03 the head made to report for EVERY symbol"                    "$CHECKER" "$PATCHDIR/g03.py"
control "g04 the valueSymbolLinks memo made to MISS always"               "$CHECKER" "$PATCHDIR/g04.py"
control "g05 newObjectType's anonymous arm reporting again"               "$CHECKER" "$PATCHDIR/g05.py"
control "g06 getBaseTypeVariableOfClass forced to answer a type"          "$CHECKER" "$PATCHDIR/g06.py"
control "g07 getBaseTypeNodeOfClass forced to answer nothing"             "$CHECKER" "$PATCHDIR/g07.py"
control "g08 the base-constructor memo write dropped"                     "$CHECKER" "$PATCHDIR/g08.py"
control "g09 the EXTENDS token test dropped (slice 66's g11, now gated)"  "$CHECKER" "$PATCHDIR/g09.py"
control "g10 the baseTypesResolved memo made to MISS always"              "$CHECKER" "$PATCHDIR/g10.py"
control "g11 getBaseTypes' resolution push made to FAIL"                  "$CHECKER" "$PATCHDIR/g11.py"
control "g12 resolveBaseTypesOfInterface's loop body emptied"             "$CHECKER" "$PATCHDIR/g12.py"
control "g13 the interface arm of getBaseTypes' switch skipped"           "$CHECKER" "$PATCHDIR/g13.py"
control "g14 the class arm made to claim interfaces"                      "$CHECKER" "$PATCHDIR/g14.py"
control "g15 checkInheritedPropertiesAreIdentical's guard removed"        "$CHECKER" "$PATCHDIR/g15.py"
control "g16 the ContainsThis test removed (slice 66's g09, now gated)"   "$CHECKER" "$PATCHDIR/g16.py"
control "g17 the BINDER's this-TYPE write removed"                        "$BINDER"  "$PATCHDIR/g17.py"
control "g18 the BINDER's interface-branch reset dropped"                 "$BINDER"  "$PATCHDIR/g18.py"
control "g19 the defensive pop removed from the reporting exit"           "$CHECKER" "$PATCHDIR/g19.py"
control "g20 checkClassLikeDeclaration's ASK removed"                     "$CHECKER" "$PATCHDIR/g20.py"

echo
echo "################################################################"
bold "RESTORED — checker.scaly and binder.scaly, byte-identical"
git -C "$REPO" diff --stat -- "$CHECKER" "$BINDER" | tail -3
