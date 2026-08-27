#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice80.sh — the slice-80 battery: THE TYPE LITERAL, and the tail that
# never needed the type it was standing behind.
#
# ★★★ THE SLICE HAS TWO HALVES AND THEY NEED THE SAME INSTRUMENT IN OPPOSITE
# DIRECTIONS, which is slice 73's lesson a third time. The TAIL half produces
# diagnostics, so breaking it LOSES a line and diagcheck — a subsequence — stays
# green; only the DIAGPIN over the seven pin files sees it. The TABLE half (the
# three kinds wired into getTypeFromTypeNode's switch) produces no diagnostic at
# all, so its rows can only move the STOPGATE.
#
# ★★★ AND A THIRD GROUP IS UNOBSERVABLE BY CONSTRUCTION, WITH A NUMBER ATTACHED TO
# SAY SO. What getTypeFromTypeLiteralOrFunctionOrConstructorTypeNode decides — the
# shared emptyTypeLiteralType against a fresh anonymous type — is a question about
# type IDENTITY, and nothing in this port PRINTS an object type: type_to_string's
# tail records `type-to-string` and answers false. So g09, g12, g13 and g15 each
# break a real decision and come back silent, and each carries the reader that would
# make it observable (§3.5ao). g05, g10, g11 and g14 are silent for three further
# reasons — a guard that cannot fire twice, a walk that cannot report, and a JS
# spelling this corpus does not hold — which is §3.5v's four kinds, all four present
# in one battery.
#
# ★★★ TWO PREDICTIONS WERE WRONG, g10 AND g11, AND THEY ARE THE SAME MISTAKE. Both
# were written expecting the alias CALL to be observable where its VALUE is not:
# getAliasSymbolForTypeNode ends in getSymbolOfDeclaration, whose getLateBoundSymbol
# reports, so forcing the alias absent (g10) or moving it inside the short-circuit
# (g11) should have moved the stopgate. Neither does, and the reason is STRUCTURAL
# rather than a corpus gap — getLateBoundSymbol's guard reports only for a CLASS
# MEMBER named `__computed`, and the symbol this walk hands it is a TYPE ALIAS. ★The
# +2 units the slice puts on the `get-late-bound-symbol` row come from somewhere
# else entirely, and g03 is what says so: dropping
# checkObjectTypeForDuplicateDeclarations takes four stop EVENTS with it, because
# that walk asks getSymbolOfDeclaration of every MEMBER. **A row aimed at one
# mechanism measured another one's contribution, and only having both rows separates
# them.**
#
# ★★ READING THE STOPGATE ON A ROW THAT CHANGES A TAG: its counts are contaminated,
# because stops.sh compares against the UNPORTED line the artifact tree recorded
# with the BASELINE binary. Read `matched` first — below the unit total the row
# moved a tag. The clean before/after came from two full run.sh + stops.sh passes.
#
# ★★★ ITERATE AT STAGE 1 AND CONFIRM AT STAGE 2 ONCE — slice 64's rule. The
# recorded verdicts are stage 1's.
#
# Usage (nothing may edit the tree while this runs — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # stage 1, ~25 s
#   packages/tscaly/tests/controls-slice80.sh 2>&1 | tee /tmp/battery80.log

set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.0/tscaly/checker.scaly
FIX=$PKG/tests/fixtures

LIBSCALY=${LIBSCALY:-/tmp/libscaly.a}
SCALYC=${SCALYC:-$REPO/scalyc/build/scalyc}

# ★ ONE MECHANISM PER FILE (slice 72's rule): the tagpin is first-wins, so a fixture
# naming two mechanisms is a fixture nobody can read a red row off.
#
# The first two are the slice's PRODUCT — the two node-driven checks of
# checkTypeLiteral's tail, one each. The next two are their negative controls (the
# grouping is by TYPE, and an empty literal reports nothing on either route). The
# fifth is slice 61's members walk, whose TAG this slice moves. The last two are the
# SIBLING containers, and they are here to show that a row aimed at the type literal
# leaves the class and the interface where slice 77 put them.
PINFILES="
$FIX/checker_type_literal_duplicate_index.ts
$FIX/checker_type_literal_duplicate_member.ts
$FIX/checker_type_literal_index_distinct_ok.ts
$FIX/checker_type_literal_alias_empty.ts
$FIX/checker_type_literal_members.ts
$FIX/checker_index_signature_duplicate_interface.ts
$FIX/checker_index_signature_duplicate_class.ts
"
red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl80)

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

# The DIAGPIN: the C section of each pin file, one line each. `--diags` rather than
# the dump, because every one of these units stops somewhere and the dump prints
# nothing for such a unit (TypeDump.emit's own note).
#
# ★ Every line was checked against the reference's own C section before this battery
# ran. SIX of the seven are EQUAL to it — which is stronger than the subsequence
# relation diagcheck compares, and is what makes a LOST report visible here. The
# seventh, checker_type_literal_duplicate_member, is a proper subsequence: the
# reference adds one TS2717 (*subsequent property declarations must have the same
# type*), which is the type system and not this chapter.
diags_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$("$WORK/tscaly_types" --diags "$f" 2>/dev/null | tr '\n' '|')"
  done
}

# The TAGPIN: the first unported tag of each fixture, read off the DUMP the way the
# artifact tree records it.
tags_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$("$WORK/tscaly_types" "$f" 2>/dev/null | grep '^UNPORTED ' | head -1 | cut -d' ' -f3-)"
  done
}

# The STOPGATE: stops.sh's internal agreement plus the two counts it prints. The
# EVENT count is the sensitive column for the table half — over the SAME 1 322 units
# the slice took the corpus from 8 008 stop events to 7 889, all of it the four
# emptied rows. The baseline below reads 7 901 over 1 326 units, the difference being
# this slice's own four fixtures.
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
  bold "BASELINE — four instruments"
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
  STOP_BASE=$(stopgate)
  echo
  echo "  the DIAGPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.diags"
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
    echo "  diagpin   unmoved — all seven pin files answer the same C section."
  else
    green "diagpin   RED"
    diff "$WORK/base.diags" "$WORK/ctl.diags" | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.tags" "$WORK/ctl.tags"; then
    echo "  tagpin    unmoved — all seven fixtures answer the same tag."
  else
    green "tagpin    RED"
    diff "$WORK/base.tags" "$WORK/ctl.tags" | sed 's/^/    /'
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
      echo "  ungated on all four, WITH A NUMBER: $DIAG_LINES/$DIAG_DIAGS -> $speaking/$diags."
    else
      red "UNGATED ON ALL FOUR AND NOTHING MOVED AT ALL."
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
# ★★★ THE PREMISE ROW: checkTypeLiteral's tail reverted to the stop slice 61 left
# there. PREDICTION: diagpin RED on both reporting fixtures (they lose four lines),
# tagpin RED on the three type-literal files whose tag this slice moved, diagcheck
# ungated AT A LOSS — the direction a subsequence cannot see — and the stopgate
# moved by the tail half of the slice.
old = """        this.get_type_from_type_literal_or_function_or_constructor_type_node(node)
        ; checkIndexConstraints(t, t.symbol, false) — getIndexInfosOfType, i.e.
        ; resolveStructuredTypeMembers and the members dimension.
        this.record_unported("check-index-constraints", KindTypeLiteral)
        ; ★ There is no once-guard on this call where the class and the interface
        ; have one: checkClassOrInterfaceForDuplicateIndexSignatures exists because
        ; a merged declaration reaches its container twice, and a type literal is
        ; one node with one symbol that nothing can merge into.
        this.check_type_for_duplicate_index_signatures(node)
        this.check_object_type_for_duplicate_declarations(node, false)"""
new = """        this.record_unported("get-type-from-type-literal-node", KindTypeLiteral)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g02.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# checkTypeForDuplicateIndexSignatures dropped from the tail. PREDICTION: diagpin
# RED on checker_type_literal_duplicate_index alone — the two TS2374 — with the
# sibling class and interface fixtures UNMOVED, which is what separates this call
# site from slice 77's.
old = """        this.check_type_for_duplicate_index_signatures(node)
        this.check_object_type_for_duplicate_declarations(node, false)"""
new = """        this.check_object_type_for_duplicate_declarations(node, false)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g03.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# checkObjectTypeForDuplicateDeclarations dropped from the tail. PREDICTION: diagpin
# RED on checker_type_literal_duplicate_member alone — the two TS2300 — and it is
# the row that shows slice 73's function had a call site with no input until now.
old = """        this.check_type_for_duplicate_index_signatures(node)
        this.check_object_type_for_duplicate_declarations(node, false)"""
new = """        this.check_type_for_duplicate_index_signatures(node)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g04.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The checkIndexConstraints stop removed while the tail stays. PREDICTION: tagpin
# RED on the type-literal fixtures that have no later stop, stopgate moved, and
# diagcheck ungated — a work-list row is not a diagnostic. It prices the stop
# rather than the checks around it.
old = """        this.record_unported("check-index-constraints", KindTypeLiteral)
        ; ★ There is no once-guard"""
new = """        ; ★ There is no once-guard"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g05.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The type-literal call routed through the class/interface ONCE-GUARD. PREDICTION:
# UNGATED with nothing moving, and that is the row's whole content — a type literal
# is one node with one symbol, so a guard that exists for a MERGED declaration can
# never fire twice here. Measured rather than argued, because the guard reads a
# per-symbol bit and a shared symbol would be the way it could bite.
old = """        this.check_type_for_duplicate_index_signatures(node)
        this.check_object_type_for_duplicate_declarations(node, false)"""
new = """        this.check_class_or_interface_for_duplicate_index_signatures(node)
        this.check_object_type_for_duplicate_declarations(node, false)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g06.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The TypeLiteral arm removed from getTypeFromTypeNode's table. PREDICTION: stopgate
# moved — 42 units of stage 1 go back to `get-type-from-type-node 188` — with
# diagcheck and both pins unmoved, because a type nothing prints is not a line.
old = """        if k = KindTypeLiteral
            return this.get_type_from_type_literal_or_function_or_constructor_type_node(node)
"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, "", 1))
PY

cat > "$PATCHDIR/g07.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The FunctionType arm removed. PREDICTION: stopgate moved by 23 units. Three rows
# rather than one, because a patch dropping all three kinds together could not say
# which kind the corpus actually holds.
old = """        if k = KindFunctionType
            return this.get_type_from_type_literal_or_function_or_constructor_type_node(node)
"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, "", 1))
PY

cat > "$PATCHDIR/g08.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The ConstructorType arm removed. PREDICTION: stopgate moved by 6 units — the
# smallest of the three, and the reason the three are separate rows.
old = """        if k = KindConstructorType
            return this.get_type_from_type_literal_or_function_or_constructor_type_node(node)
"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, "", 1))
PY

cat > "$PATCHDIR/g09.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The MEMBERS test dropped: every type literal with a symbol gets its own anonymous
# type and emptyTypeLiteralType is never answered. PREDICTION: UNGATED with nothing
# moving — the difference between the shared type and a fresh one is IDENTITY, and
# nothing in this port prints an object type. ★The reader that would make it
# observable is checkIndexConstraints, i.e. the members dimension, which is the very
# stop this arm now carries.
old = """            if SymbolTable.length(Symbol.members_of(sym as ref[Symbol])) = 0
            {
                set links.resolved_type: empty_type_literal_type
                return links.resolved_type
            }
"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, "", 1))
PY

cat > "$PATCHDIR/g10.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The alias forced ABSENT, call and all. PREDICTION (WRONG): the stopgate moves,
# because the alias's VALUE is invisible (g09's argument) while its CALL is not.
# MEASURED: nothing moves at all. getLateBoundSymbol reports only for a CLASS MEMBER
# named `__computed` and this walk hands it a TYPE ALIAS, so the alias lookup is
# report-free by construction — not merely uncovered.
old = """        let has_alias this.get_alias_symbol_for_type_node(node) <> null"""
new = """        let has_alias false"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g11.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE ORDER ROW. The alias moved INSIDE the short-circuit, where a reader would
# put it — it is only needed when the members are empty. PREDICTION (WRONG): the
# answer is identical on every input and the STOPGATE MOVES, because the call can
# report and the guard decides whether it happens. MEASURED: nothing moves, for
# g10's reason. ★The order is still the reference's in the source, and the row is
# why the comment there now says the ARGUMENT for it rather than a measurement it
# does not have.
old = """        let has_alias this.get_alias_symbol_for_type_node(node) <> null
        let sym AstNode.symbol_of(node)
        if sym = null
        {
            set links.resolved_type: empty_type_literal_type
            return links.resolved_type
        }
        if has_alias = false
        {
            if SymbolTable.length(Symbol.members_of(sym as ref[Symbol])) = 0"""
new = """        let sym AstNode.symbol_of(node)
        if sym = null
        {
            set links.resolved_type: empty_type_literal_type
            return links.resolved_type
        }
        if SymbolTable.length(Symbol.members_of(sym as ref[Symbol])) = 0
        {
            if this.get_alias_symbol_for_type_node(node) = null"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g12.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The ParenthesizedType arm of the alias walk-up dropped, so `type A = ({})` no
# longer finds its alias. PREDICTION: UNGATED — the fixture
# checker_type_literal_alias_empty holds exactly that shape and the answer it
# changes is an identity nothing prints. The arm is transcribed for the reader that
# will print one.
old = """            if k = KindParenthesizedType
            {
                set owner: AstNode.parent_node_of(o)
                continue
            }
"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, "", 1))
PY

cat > "$PATCHDIR/g13.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The readonly TypeOperator arm of the walk-up dropped. PREDICTION: UNGATED, and
# unlike g12 it is STRUCTURALLY unreachable from this port's only caller rather than
# merely uncovered: `readonly` is permitted on an array or tuple type only, so a
# readonly operator's operand is never one of the three kinds that reach this
# function. It is kept for the second caller and for a recovered parse.
old = """            if k = KindTypeOperator
            {
                if AstNode.type_operator_operator_of(o) = KindReadonlyKeyword
                {
                    set owner: AstNode.parent_node_of(o)
                    continue
                }
            }
"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, "", 1))
PY

cat > "$PATCHDIR/g14.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# isTypeAlias narrowed to the TypeScript spelling — the JS `@typedef` arm dropped.
# PREDICTION: UNGATED, and the reason is a corpus fact rather than a structural one:
# a JSDoc type alias over a bare type literal is the shape it needs and stage 1
# holds none.
old = """        if k = KindTypeAliasDeclaration
            return true
        k = KindJSTypeAliasDeclaration"""
new = """        k = KindTypeAliasDeclaration"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g15.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The node-links MEMO defeated: every ask mints a new type. PREDICTION: UNGATED with
# nothing moving, which is declared_type_links' note arriving a third time — a memo
# written for fidelity whose hit nothing in this slice can observe. ★Its reader is
# named: the first function that compares two object types by identity.
old = """        let links this.type_node_link_of(node)
        if links.resolved_type <> null
            return links.resolved_type"""
new = """        let links this.type_node_link_of(node)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

# ── the dry run ─────────────────────────────────────────────────────────────
bold "DRY RUN — every patch against a copy of the tree"
DRY=$WORK/dry
for g in g01 g02 g03 g04 g05 g06 g07 g08 g09 g10 g11 g12 g13 g14 g15; do
  rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
  if python3 "$PATCHDIR/$g.py" "$DRY/f.scaly" >/dev/null 2>&1; then
    echo "  $g applies"
  else
    red "  $g DOES NOT APPLY — its anchor has moved."; exit 2
  fi
done
rm -rf "$DRY"

baseline

control "g01 checkTypeLiteral's tail reverted to the stop (the premise)"   "$CHECKER" "$PATCHDIR/g01.py"
control "g02 checkTypeForDuplicateIndexSignatures dropped from the tail"   "$CHECKER" "$PATCHDIR/g02.py"
control "g03 checkObjectTypeForDuplicateDeclarations dropped from the tail" "$CHECKER" "$PATCHDIR/g03.py"
control "g04 the check-index-constraints stop removed, tail kept"          "$CHECKER" "$PATCHDIR/g04.py"
control "g05 the type literal routed through the class/interface once-guard" "$CHECKER" "$PATCHDIR/g05.py"
control "g06 the TypeLiteral arm removed from the type-node table"         "$CHECKER" "$PATCHDIR/g06.py"
control "g07 the FunctionType arm removed"                                 "$CHECKER" "$PATCHDIR/g07.py"
control "g08 the ConstructorType arm removed"                              "$CHECKER" "$PATCHDIR/g08.py"
control "g09 the members test dropped (emptyTypeLiteralType never answered)" "$CHECKER" "$PATCHDIR/g09.py"
control "g10 the alias forced absent, call and all"                        "$CHECKER" "$PATCHDIR/g10.py"
control "g11 the alias moved INSIDE the short-circuit (the ORDER row)"     "$CHECKER" "$PATCHDIR/g11.py"
control "g12 the ParenthesizedType arm of the alias walk-up dropped"       "$CHECKER" "$PATCHDIR/g12.py"
control "g13 the readonly TypeOperator arm of the walk-up dropped"         "$CHECKER" "$PATCHDIR/g13.py"
control "g14 isTypeAlias narrowed to the TypeScript spelling"              "$CHECKER" "$PATCHDIR/g14.py"
control "g15 the node-links memo defeated"                                 "$CHECKER" "$PATCHDIR/g15.py"

echo
echo "################################################################"
bold "DONE — read every row against its PREDICTION, not against its colour."
