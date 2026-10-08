#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice87.sh — the slice-87 battery: THE STATIC SIDE OF A CLASS, and a
# chapter whose product is a SIGNATURE nothing in the suite could see.
#
# ★★★ THE SLICE CLOSES THE WORK LIST'S HEAD. `resolve-anonymous-type-members` was
# 274 units and 422 events at stage 1 — 3 264 units at stage 2, the largest
# reachable row since slice 63 — and it is now ZERO on all three of its details.
# What stands in its place is two stops of its own making, `exports-of-module` and
# `late-bound-exports`, at 7 units of 1 415 together.
#
# ★★★ THE BATTERY GAINED THE SEVENTH INSTRUMENT AND SLICE 86'S ARGUMENT IS WHY.
# That slice put thirty-three rows against five instruments and twenty-nine came
# back silent, because the chapter's product was a members table with one reader.
# This chapter's product is a members table AND A SIGNATURE LIST, and the member
# log printed only the signature COUNT — so `class C {}`, `abstract class C {}`
# and `class C<T> {}` had member logs that are IDENTICAL to the byte. The
# `G <flags> <typeparams> <params> <minargs>` line is what separates them, and
# three of the rows below would otherwise have been three more rows measuring the
# absence of a reader.
#
# ★★★ THE SLICE ADDS NO DIAGNOSTIC, so diagcheck and the DIAGPIN are purely
# NEGATIVE here — what they are for is to say that a row which moves a stop does
# not also move a report. Slices 67, 85 and 86 had the same shape and said so.
#
# ★★★ ITERATE AT STAGE 1 AND CONFIRM AT STAGE 2 ONCE — slice 64's rule. The
# recorded verdicts are stage 1's.
#
# Usage (nothing may edit the tree while this runs, and no second harness may own
# tests/out — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # stage 1, ~25 s
#   packages/tscaly/tests/controls-slice87.sh 2>&1 | tee /tmp/battery87.log
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
# ★★ THE LAST TWO ARE SLICE 85'S AND 86'S, KEPT ON PURPOSE. This slice moves the
# STATIC side of a class and those two files exercise the INSTANCE side of the same
# chapter, so they are the row that says a patch aimed at the statics did not move
# the members table beside it.
#
# ★★ THE STOPPIN IS THE INSTRUMENT THAT CARRIES THIS BATTERY, for slice 85's reason
# and one more: a row here typically swaps ONE stop for another inside a single
# unit, which the tagpin (first stop only) and the stopgate (counts over the whole
# corpus) can both miss. The whole log, in order, per fixture, is what separates
# `the members table was built` from `it was not`.
PINFILES="
$FIX/checker_statics_class_plain.ts
$FIX/checker_statics_class_abstract.ts
$FIX/checker_statics_class_generic.ts
$FIX/checker_statics_class_ctor.ts
$FIX/checker_statics_class_static_index.ts
$FIX/checker_statics_class_computed_static.ts
$FIX/checker_statics_class_computed_instance.ts
$FIX/checker_statics_class_extends.ts
$FIX/checker_instantiate_class_plain.ts
$FIX/checker_members_class_index.ts
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
#
# ★★★ SLICE 87 GIVES IT A THIRD LINE FOR THE SAME REASON: `G <flags> <typeparams>
# <params> <minargs>` per signature, because the header's count column cannot tell
# a synthesized `new C(): C` from an abstract one, from a generic one, or from a
# DECLARED constructor — and four of this battery's rows move nothing else.
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
    echo "  diagpin   unmoved — all ten pin files answer the same C section."
  else
    green "diagpin   RED"
    diff "$WORK/base.diags" "$WORK/ctl.diags" | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.tags" "$WORK/ctl.tags"; then
    echo "  tagpin    unmoved — all ten fixtures answer the same tag."
  else
    green "tagpin    RED"
    diff "$WORK/base.tags" "$WORK/ctl.tags" | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.stops" "$WORK/ctl.stops"; then
    echo "  stoppin   unmoved — all ten fixtures log the same stops, in order."
  else
    green "stoppin   RED"
    diff "$WORK/base.stops" "$WORK/ctl.stops" | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.members" "$WORK/ctl.members"; then
    echo "  memberpin unmoved — all ten fixtures resolve the same members."
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

python3 - "$PATCHDIR" <<'MKPATCHES'
import os, textwrap
import sys
D=sys.argv[1]
os.makedirs(D, exist_ok=True)

P = {}

P['g01'] = ('''# THE PREMISE. PREDICTION: TAGPIN + STOPPIN + MEMBERPIN RED on every fixture whose
# static side resolves, STOPGATE moved by the whole chapter (`resolve-anonymous-
# type-members` back at 274 units). diagcheck cannot move: the slice adds no
# diagnostic.''',
'''old = """        ; \\u2500\\u2500 combinations of function, class, enum and module \\u2500\\u2500\\u2500\\u2500"""
new = """        this.record_unported("resolve-anonymous-type-members", Symbol.flags_of(symbol))
        return
        ; \\u2500\\u2500 combinations of function, class, enum and module \\u2500\\u2500\\u2500\\u2500"""''')

P['g02'] = ('''# The exports table swapped for the MEMBERS table. PREDICTION: MEMBERPIN RED — the
# static side would answer the INSTANCE members, which is the wrong table and the
# one mistake this whole function exists to avoid.''',
'''old = """        var members this.get_exports_of_symbol(symbol)
        if this.unported_mark() <> mark"""
new = """        var members this.get_members_of_symbol(symbol)
        if this.unported_mark() <> mark"""''')

P['g03'] = ('''# getExportsOfSymbol' MODULE arm removed. PREDICTION: STOPGATE moved — the five
# `exports-of-module` events go away and a merged class+namespace resolves its
# exports from the wrong table instead. No pin file is such a merge, so the pins
# stay put; the row is here to price the reordering the function's header argues
# for.''',
'''old = """        if (Symbol.flags_of(symbol) & SymbolFlagsModule) <> 0
        {
            this.record_unported("exports-of-module", Symbol.flags_of(symbol))
            return null
        }"""
new = """"""''')

P['g04'] = ('''# getExportsOfSymbol' late-binding scan removed. PREDICTION: STOPPIN RED on
# checker_statics_class_computed_static — the `late-bound-exports` line goes away
# and the static side resolves a table that is missing the computed member.''',
'''old = """                if AstNode.kind_of(name as ref[AstNode]) = KindComputedPropertyName
                {
                    this.record_unported("late-bound-exports", Symbol.flags_of(symbol))
                    return null
                }"""
new = """"""''')

P['g05'] = ('''# The scan's STATIC test inverted, i.e. it looks at the INSTANCE members. PREDICTION:
# STOPPIN RED on BOTH computed fixtures and in OPPOSITE directions — computed_static
# stops being reported and computed_instance starts. It is the row that says
# getExportsOfSymbol and getMembersOfSymbol cannot be one function with a flag.''',
'''old = """                if b.has_syntactic_modifier(member, ModifierFlagsStatic) = false
                    continue"""
new = """                if b.has_syntactic_modifier(member, ModifierFlagsStatic)
                    continue"""''')

P['g06'] = ('''# The `%FEassignment` entry test removed. PREDICTION: UNGATED at stage 1 — no pin
# file carries a dynamically named `this.x = v` in a JavaScript file, and the row
# names what a fixture would have to hold.''',
'''old = """            if SymbolTable.get(exports as pointer[SymbolTable], ad, al) <> null
            {
                this.record_unported("late-bound-exports", Symbol.flags_of(symbol))
                return null
            }"""
new = """"""''')

P['g07'] = ('''# The EARLY setStructuredTypeMembers removed. PREDICTION: MEMBERPIN RED on every
# resolving fixture — one R line fewer per static side. The reference's own comment
# says the call is there to close a `typeof` recursion; what the pin can see is only
# that it happens, which is worth exactly that much.''',
'''old = """        var base_constructor_index_info: ref[IndexInfo]? null
        this.set_structured_type_members(t, members, null, null, null)"""
new = """        var base_constructor_index_info: ref[IndexInfo]? null"""''')

P['g08'] = ('''# The class arm of the index-info half removed (no declared type, no base
# constructor type). PREDICTION: UNGATED — its only product is
# base_constructor_index_info, which is null for every class in this corpus because
# a base-less class answers undefinedType. The row prices an arm that runs and
# decides nothing.''',
'''old = """            var inherits false
            if (bct.flags & TypeFlagsObject) <> 0
                set inherits: true"""
new = """            var inherits false
            if false
                set inherits: true"""''')

P['g09'] = ('''# The inheriting branch forced TAKEN. PREDICTION: UNGATED, and a PROOF — the base
# constructor type is undefinedType, getPropertiesOfType of it is nothing, and
# addInheritedMembers over nothing answers the clone unchanged. The clone is
# therefore invisible here and its argument is about a reader that does not exist
# yet.''',
'''old = """            var inherits false
            if (bct.flags & TypeFlagsObject) <> 0
                set inherits: true"""
new = """            var inherits true
            if (bct.flags & TypeFlagsObject) <> 0
                set inherits: true"""''')

P['g10'] = ('''# anyBaseTypeIndexInfo forced ON for every class. PREDICTION: MEMBERPIN RED — every
# static side gains an index info it has no signature for. It is the row that says
# `extends any` is a shape this port cannot reach, and what it would do if it could.''',
'''old = """                if bct = any_type
                    set base_constructor_index_info: any_base_type_index_info"""
new = """                set base_constructor_index_info: any_base_type_index_info"""''')

P['g11'] = ('''# The index-symbol lookup skipped. PREDICTION: MEMBERPIN RED on
# checker_statics_class_static_index (index count 1 -> 0) and STOPPIN RED there too:
# `check-index-constraint` disappears, because a class with no index info never
# reaches the constraint check.''',
'''old = """            set index_symbol: SymbolTable.get(members as pointer[SymbolTable], idd, idl)"""
new = """            set index_symbol: null"""''')

P['g12'] = ('''# The enum arm removed. PREDICTION: UNGATED — an enum's static side does not arrive
# here at stage 1 (computeEnumMemberValues stops first), which the stop histogram
# says from the other side: the closed row carried three details and none of them
# was an enum.''',
'''old = """            if (Symbol.flags_of(symbol) & SymbolFlagsEnum) <> 0
            {
                var enum_index false"""
new = """            if false
            {
                var enum_index false"""''')

P['g13'] = ('''# The nil-when-empty test dropped, so an EMPTY list is answered instead. PREDICTION:
# UNGATED, and a PROOF that today the two agree — checkIndexConstraints asks a
# LENGTH, so a nil and an empty list are the same answer to the one reader there is.
# The line is written for the reader that tells them apart, not for this one.''',
'''old = """            if infos.get_length() <> (0 as size_t)
                set index_infos: infos"""
new = """            set index_infos: infos"""''')

P['g14'] = ('''# The Function|Method arm forced ON for a class symbol. PREDICTION: the class symbol
# has no signature declarations, so getSignaturesOfSymbol answers an empty list and
# nothing moves — UNGATED, and the row that prices the arm the histogram already
# proved unreachable (a function\\'s type comes through getTypeFromTypeQueryNode,
# which stops).''',
'''old = """        var function_like false
        if (Symbol.flags_of(symbol) & SymbolFlagsFunction) <> 0
            set function_like: true"""
new = """        var function_like true
        if (Symbol.flags_of(symbol) & SymbolFlagsFunction) <> 0
            set function_like: true"""''')

P['g15'] = ('''# The class construct-signature arm removed whole. PREDICTION: MEMBERPIN RED on
# every resolving fixture — the G line disappears and the header count goes 1 -> 0.
# It is g01 confined to the signature half.''',
'''old = """            set construct_signatures: this.get_signatures_of_symbol(ctor_symbol)
            if this.unported_mark() <> mark
                return"""
new = """            set construct_signatures: null
            if this.unported_mark() <> mark
                return"""''')

P['g16'] = ('''# The declared-constructor lookup skipped, so the DEFAULT is always used.
# PREDICTION: MEMBERPIN RED on checker_statics_class_ctor alone — `G 4 0 2 1`
# becomes `G 4 0 0 0`, a signature that takes no arguments where the source declares
# two. Nothing else moves, because no other fixture declares a constructor.''',
'''old = """            if own_members <> null
                set ctor_symbol: SymbolTable.get(own_members as pointer[SymbolTable], ctord, ctorl)"""
new = """            if own_members <> null
                set ctor_symbol: null"""''')

P['g17'] = ('''# The empty-list test inverted, so the default construct signature is NEVER minted.
# PREDICTION: MEMBERPIN RED on every fixture EXCEPT checker_statics_class_ctor — the
# G line disappears from the four that have no declared constructor and stays on the
# one that has.''',
'''old = """            if declared_count = 0
            {
                set construct_signatures: this.get_default_construct_signatures(declared as ref[Type])"""
new = """            if declared_count < 0
            {
                set construct_signatures: this.get_default_construct_signatures(declared as ref[Type])"""''')

P['g18'] = ('''# getDefaultConstructSignatures\\' isAbstract forced FALSE. PREDICTION: MEMBERPIN RED
# on checker_statics_class_abstract ALONE, `G 12` -> `G 4`. Before the G line existed
# this row was invisible on all six instruments, which is the measurement that bought
# the seventh.''',
'''old = """            if declaration <> null
                set is_abstract: b.has_syntactic_modifier(declaration as ref[AstNode], ModifierFlagsAbstract)"""
new = """            if declaration <> null
                set is_abstract: false"""''')

P['g19'] = ('''# getDefaultConstructSignatures\\' LocalTypeParameters replaced by nothing.
# PREDICTION: MEMBERPIN RED on checker_statics_class_generic ALONE, `G 4 1 0 0` ->
# `G 4 0 0 0`. The second row the G line bought, and the first reader
# InterfaceType.LocalTypeParameters() has that is not a stop.''',
'''old = """            let local_tps this.local_type_parameters_of(class_type)"""
new = """            let local_tps: ref[Array[ref[Type]?]]? null"""''')

P['g20'] = ('''# getDefaultConstructSignatures\\' base-less branch turned back into its stop.
# PREDICTION: TAGPIN + STOPPIN + MEMBERPIN RED and the STOPGATE moved — every class
# without a declared constructor stops, which is most of the corpus. It is the half
# of the slice that gives the static side its one signature.''',
'''old = """        if base_count = 0
        {
            var flags SignatureFlagsConstruct"""
new = """        if base_count < 0
        {
            var flags SignatureFlagsConstruct"""''')

P['g21'] = ('''# getDefaultConstructSignatures\\' base loop reached unconditionally instead of its
# guard. PREDICTION: UNGATED — base_count is zero at every arrival, so the stop below
# it is dead code today and this row is what says so rather than asserting it.''',
'''old = """        this.record_unported("get-default-construct-signatures-with-base", base_count)
        null"""
new = """        null"""''')

P['g22'] = ('''# The FINAL setStructuredTypeMembers removed, so the branch stops after the early
# one. PREDICTION: MEMBERPIN RED on every resolving fixture — the signatures and the
# index infos never reach the record, so the static side comes out with a members
# table and nothing else. g07 from the other end of the same function.''',
'''old = """        this.set_structured_type_members(t, members, call_signatures, construct_signatures, index_infos)
    }

    ; resolveStructuredTypeMembers, whole"""
new = """    }

    ; resolveStructuredTypeMembers, whole"""''')

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

control "g01 the third branch reverted to its stop (the premise)" $CHECKER "$PATCHDIR/g01.py"
control "g02 getExportsOfSymbol swapped for getMembersOfSymbol" $CHECKER "$PATCHDIR/g02.py"
control "g03 getExportsOfSymbol' module arm removed" $CHECKER "$PATCHDIR/g03.py"
control "g04 getExportsOfSymbol' late-binding scan removed" $CHECKER "$PATCHDIR/g04.py"
control "g05 the late-binding scan's STATIC test inverted" $CHECKER "$PATCHDIR/g05.py"
control "g06 the %FEassignment entry test removed" $CHECKER "$PATCHDIR/g06.py"
control "g07 the EARLY setStructuredTypeMembers removed" $CHECKER "$PATCHDIR/g07.py"
control "g08 the class arm of the index-info half removed" $CHECKER "$PATCHDIR/g08.py"
control "g09 the inheriting branch forced taken" $CHECKER "$PATCHDIR/g09.py"
control "g10 anyBaseTypeIndexInfo forced on for every class" $CHECKER "$PATCHDIR/g10.py"
control "g11 the index-symbol lookup skipped" $CHECKER "$PATCHDIR/g11.py"
control "g12 the enum arm removed" $CHECKER "$PATCHDIR/g12.py"
control "g13 the nil-when-empty index-info test dropped" $CHECKER "$PATCHDIR/g13.py"
control "g14 the Function|Method arm forced on" $CHECKER "$PATCHDIR/g14.py"
control "g15 the class construct-signature arm removed" $CHECKER "$PATCHDIR/g15.py"
control "g16 the declared-constructor lookup skipped" $CHECKER "$PATCHDIR/g16.py"
control "g17 the default construct signature never minted" $CHECKER "$PATCHDIR/g17.py"
control "g18 getDefaultConstructSignatures' isAbstract forced false" $CHECKER "$PATCHDIR/g18.py"
control "g19 getDefaultConstructSignatures' LocalTypeParameters dropped" $CHECKER "$PATCHDIR/g19.py"
control "g20 getDefaultConstructSignatures' base-less branch back to a stop" $CHECKER "$PATCHDIR/g20.py"
control "g21 getDefaultConstructSignatures' base loop reached unconditionally" $CHECKER "$PATCHDIR/g21.py"
control "g22 the FINAL setStructuredTypeMembers removed" $CHECKER "$PATCHDIR/g22.py"

echo
echo "################################################################"
bold "DONE — read every row against its PREDICTION, not against its colour."
