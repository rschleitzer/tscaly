#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice85.sh — the slice-85 battery: THE MEMBERS, and a chapter whose
# whole product is a table nothing reads yet.
#
# ★★★ THE SLICE CLOSES A ROW AND OPENS TWO. `check-index-constraints` was 496 units
# over three kinds — the largest REACHABLE row of the work list since slice 63 — and
# it is now zero. What stands in its place is `resolve-type-reference-members` (the
# instantiating arm, which every CLASS takes) and `resolve-anonymous-type-members`
# (the class's STATIC side), and between them they are the members chapter's own
# successor. The two container kinds the slice covers — a non-generic interface free
# of `this`, and a type literal — walk PAST the row entirely.
#
# ★★★ WHAT AN INSTRUMENT CAN SEE HERE IS ONE THING: `check-index-constraint` IN A
# STOP LOG MEANS AN IndexInfo WAS BUILT. checkIndexConstraints' first two lines are
# `getIndexInfosOfType` and `if len == 0 return`, and everything after them needs
# isTypeAssignableTo — so the stop fires exactly when the whole chain under it
# answered a non-empty list. That one bit is what gates the key-type test, the index
# symbol, the declared members, the base loop, the anonymous branch, the structured
# slot and the accessor in front of it; the rows below are that bit read from
# thirteen sides. Everything else the chapter produces — the members table, the
# properties list, the signatures — has NO READER until the relation and call
# resolution land, and the ungated rows are where that is priced.
#
# ★★★ THE SLICE'S ONE METHOD FINDING IS g26, AND IT IS A SILENCE THAT READ AS A
# GUARD. getMembersOfSymbol's late-binding fork was first written to ask the members
# table for the binder's `%FEcomputed` entry — the same marker get_late_bound_symbol
# reads — and it came back silent on a fixture that has a computed member. Measured
# with a probe: the interface symbol's members table has length ZERO for that shape.
# **A marker is a fact about the object that carries it, not about the object that
# owns that one**, and the reference asks the question the other way round: a loop
# over the container's DECLARATIONS and their member lists.
#
# ★★★ ITERATE AT STAGE 1 AND CONFIRM AT STAGE 2 ONCE — slice 64's rule. The recorded
# verdicts are stage 1's.
#
# Usage (nothing may edit the tree while this runs, and no second harness may own
# tests/out — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # stage 1, ~35 s
#   packages/tscaly/tests/controls-slice85.sh 2>&1 | tee /tmp/battery85.log
#
set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.2/tscaly/checker.scaly
BINDER=$PKG/0.1.2/tscaly/binder.scaly
FIX=$PKG/tests/fixtures

. packages/tscaly/tests/toolchain.sh || exit 2

# ★ ONE MECHANISM PER FILE (slice 72's rule): the tagpin is first-wins, so a fixture
# naming two mechanisms is a fixture nobody can read a red row off.
#
# ★★ THE STOPPIN IS THE INSTRUMENT THAT CARRIES THIS SLICE, and for a sharper
# reason than slice 84 had. What this chapter produces is a members table nothing
# reads yet — so the ONE thing an instrument can see is where the walk gets to, and
# the eighteen fixtures below are chosen so that each mechanism decides a stop:
# every `check-index-constraint` in the log is an IndexInfo that was actually built,
# every `resolve-type-reference-members` is a type the slice deliberately does not
# cover, and the two `extends` fixtures put the base loop on the same footing.
PINFILES="
$FIX/checker_members_interface_index.ts
$FIX/checker_members_interface_index_number.ts
$FIX/checker_members_interface_index_symbol.ts
$FIX/checker_members_interface_index_readonly.ts
$FIX/checker_members_interface_index_invalid.ts
$FIX/checker_members_interface_index_duplicate_key.ts
$FIX/checker_members_interface_extends_index.ts
$FIX/checker_members_interface_extends_two.ts
$FIX/checker_members_interface_extends_plain.ts
$FIX/checker_members_interface_merged_index.ts
$FIX/checker_members_interface_generic.ts
$FIX/checker_members_interface_this.ts
$FIX/checker_members_interface_computed.ts
$FIX/checker_members_type_literal_index.ts
$FIX/checker_members_type_literal_call.ts
$FIX/checker_members_type_literal_construct.ts
$FIX/checker_members_type_literal_call_overload.ts
$FIX/checker_members_class_index.ts
"
red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl85)

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

# The DIAGPIN: the C section of each pin file, one line each. `--diags` rather than
# the dump, because every one of these units stops somewhere and the dump prints
# nothing for such a unit (TypeDump.emit's own note).
#
# ★★★ THE SLICE ADDS NO DIAGNOSTIC AT ALL, so this instrument and diagcheck are
# purely NEGATIVE here: what they are for is to say that a row which moves a stop
# does not also move a report. Slice 67's battery had the same shape and said so.
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

# The STOPPIN: the WHOLE stop log of each pin file, in order — slice 82's fifth
# instrument, and the ONE that carries this battery.
#
# ★★★ WHY IT AND NOT THE OTHER FOUR — slice 84's argument, one dimension further
# down. The tagpin reads only the FIRST stop, and most of these fixtures have their
# first stop somewhere the slice does not touch; the stopgate sees COUNTS over the
# whole corpus, which a row that swaps one stop for another leaves alone; and both
# diagnostic instruments are negative. The whole log, in order, per fixture, is the
# only thing that can tell `an IndexInfo was built` from `an IndexInfo was not`.
stops_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$("$WORK/tscaly_types" --stops "$f" 2>/dev/null | tr '\n' '|')"
  done
}

# The STOPGATE: stops.sh's internal agreement plus the counts it prints.
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
    echo "  diagpin   unmoved — all eighteen pin files answer the same C section."
  else
    green "diagpin   RED"
    diff "$WORK/base.diags" "$WORK/ctl.diags" | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.tags" "$WORK/ctl.tags"; then
    echo "  tagpin    unmoved — all eighteen fixtures answer the same tag."
  else
    green "tagpin    RED"
    diff "$WORK/base.tags" "$WORK/ctl.tags" | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.stops" "$WORK/ctl.stops"; then
    echo "  stoppin   unmoved — all eighteen fixtures log the same stops, in order."
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

cat > "$PATCHDIR/g01.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PREDICTION: STOPPIN RED on every fixture that reaches a members question,
# STOPGATE moved by the whole chapter, and `check-index-constraints` back on the
# work list at 496 units over three kinds. diagcheck cannot move: the slice adds
# no diagnostic.
old = """        this.check_index_constraints(class_type as ref[Type], sym, false)
        this.check_index_constraints(static_type as ref[Type], sym, true)"""
new = """        this.record_unported("check-index-constraints", AstNode.kind_of(node))"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g02.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PREDICTION: STOPGATE moved with MORE EVENTS. MEASURED: UNGATED ON ALL FIVE — a
# WRONG PREDICTION, and it is slice 84's g02 arriving at a different memo. Nothing
# in this port asks one type for its members twice: checkIndexConstraints asks each
# container's type once, the base loop that would ask a second time is unreachable
# (g11), and the two accessors beside getIndexInfosOfType have no caller yet. The
# memo is written for fidelity and its reader is the relation.
old = """        if (t.object_flags & ObjectFlagsMembersResolved) = 0
        {
            if (t.flags & TypeFlagsObject) <> 0"""
new = """        if true
        {
            if (t.flags & TypeFlagsObject) <> 0"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g03.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PREDICTION: STOPPIN RED on the class and on both Reference-flagged interfaces —
# they would take the class-or-interface arm, whose resolve_object_type_members
# then finds typeParameters (allTypeParameters) against typeArguments (nil) and
# stops at `instantiate-structured-members` instead. The arm ORDER is the
# reference's and this row is what says it is load-bearing.
old = """                if (t.object_flags & ObjectFlagsReference) <> 0
                {
                    ; resolveTypeReferenceMembers — see the chapter header.
                    this.record_unported("resolve-type-reference-members", t.object_flags)
                    return null
                }
                if (t.object_flags & ObjectFlagsClassOrInterface) <> 0
                    this.resolve_class_or_interface_members(t)
                if (t.object_flags & ObjectFlagsClassOrInterface) = 0
                {"""
new = """                if (t.object_flags & ObjectFlagsClassOrInterface) <> 0
                    this.resolve_class_or_interface_members(t)
                if (t.object_flags & ObjectFlagsClassOrInterface) = 0
                {
                    if (t.object_flags & ObjectFlagsReference) <> 0
                    {
                        this.record_unported("resolve-type-reference-members", t.object_flags)
                        return null
                    }"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g04.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PREDICTION: UNGATED, and the row is a claim about the CORPUS rather than about
# the code. The order is the reference's recursion guard — a signature whose
# annotation names the type it belongs to would recurse forever — and no fixture
# here writes one. A row that predicts silence and gets it is a measurement.
old = """        set made.members: members
        Checker.attach_declared_members(t, made)"""
new = """        set made.members: members"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g05.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PREDICTION: STOPGATE moved. MEASURED: UNGATED — a WRONG PREDICTION with a
# one-line reason. The only symbols this slice hands getSignaturesOfSymbol are
# `%FEcall` and `%FEnew`, and the binder puts nothing but call and construct
# SIGNATURES under those names, so the filter has nothing to reject. Read beside
# g06: two guards of one function, both unreachable, and for the same fact about
# the input rather than about the corpus.
old = """            if AstNode.is_function_like(decl) = false
            {
                set i: i + 1
                continue
            }"""
new = """            if false
            {
                set i: i + 1
                continue
            }"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g06.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PREDICTION: UNGATED, and a PROOF rather than a hole. The skip drops the
# IMPLEMENTATION of an overloaded function, recognised by its having a BODY — and
# the only symbols this slice hands getSignaturesOfSymbol are `%FEcall` and
# `%FEnew`, whose declarations are SIGNATURES and never have one.
# checker_members_type_literal_call_overload.ts holds the two-signature shape, which
# is what separates uncovered from unreachable.
old = """            if skip
            {
                set i: i + 1
                continue
            }"""
new = """            if false
            {
                set i: i + 1
                continue
            }"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g07.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PREDICTION: STOPPIN RED on the NUMBER and SYMBOL index fixtures — their index
# signature builds no IndexInfo, so checkIndexConstraints returns at its first line
# and `check-index-constraint` disappears from both logs. The string fixtures do
# not move, which is what says the row is the key TYPE and not the machinery.
old = """        if (t.flags & (TypeFlagsString | TypeFlagsNumber | TypeFlagsESSymbol)) <> 0
            return true"""
new = """        if (t.flags & TypeFlagsString) <> 0
            return true"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g08.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PREDICTION: STOPPIN RED on the INVALID fixture in the other direction — `[k: 1]`
# would build an IndexInfo the reference does not, and `check-index-constraint`
# appears where it does not belong. The one INVENTING row of this pair.
old = """        if (t.flags & (TypeFlagsString | TypeFlagsNumber | TypeFlagsESSymbol)) <> 0
            return true"""
new = """        if true
            return true"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g09.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PREDICTION: UNGATED with the reader named, and MEASURED so. Two declarations of
# one key type contribute two IndexInfos instead of one, and the only thing that
# reads the COUNT is checkIndexConstraints' `len(indexInfos) > 1` loop, behind
# isTypeAssignableTo. checker_members_interface_index_duplicate_key.ts holds the
# shape, which is what separates uncovered from unreachable.
old = """                if Checker.find_index_info(infos, key_type) = null
                {
                    let readonly b.has_syntactic_modifier(decl, ModifierFlagsReadonly)
                    infos.add(this.new_index_info(key_type, value_type, readonly, decl))
                }"""
new = """                let readonly b.has_syntactic_modifier(decl, ModifierFlagsReadonly)
                infos.add(this.new_index_info(key_type, value_type, readonly, decl))"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g10.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PREDICTION: STOPGATE moved with FEWER EVENTS. MEASURED: UNGATED — a WRONG
# PREDICTION, and it is the same fact as g17 and g18: an index signature's return
# annotation is walked by the members walk before this chapter ever asks, and
# getTypeFromTypeNode MEMOISES per node, so the second ask logs nothing. **A walk
# this slice adds is invisible wherever another walk already went there.**
old = """            let return_type_node AstNode.type_of(decl)
            if return_type_node <> null
            {
                let vt this.get_type_from_type_node(return_type_node as ref[AstNode])
                if vt = null
                    return null
                set value_type: vt as ref[Type]
            }"""
new = """            let return_type_node AstNode.type_of(decl)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g11.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PREDICTION: STOPPIN RED on both `extends` fixtures. MEASURED: UNGATED, and the
# WRONG PREDICTION is the battery's largest finding — **the base loop cannot run at
# all.** getBaseTypes answers a non-empty list only for an interface whose `extends`
# clause resolves, and resolve_base_types_of_interface stops at
# getTypeFromTypeNode(ExpressionWithTypeArguments) for every one of them. Probed
# over the whole stage-1 corpus with a counter on the loop's own guard: `base_count`
# is **ZERO at every arrival**. So the `extends` fixtures' `check-index-constraint`
# is the BASE interface's own and never the derived one's, and g11 through g14 are
# one unreachability rather than four missing readers. ★It is also what found the
# defect g29 reproduces: before that fix the derived interface came back with an
# EMPTY base list and no stop at all.
old = """        if base_count <> 0
        {
            set members: this.clone_symbol_table(members)"""
new = """        if false
        {
            set members: this.clone_symbol_table(members)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g12.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PREDICTION: UNGATED with the reader named. MEASURED so, and for a STRONGER reason
# than the prediction gave — see g11: the loop this line sits in never runs. The
# reader is still named (getPropertiesOfType, i.e. the relation and property
# access), but the row is unreachable before it is unread.
old = """                set members: this.add_inherited_members(members, props)"""
new = """                this.add_inherited_members(members, props)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g13.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PREDICTION: UNGATED with a number at most. MEASURED: ungated with nothing moving,
# and g11's reason again — the filter is inside the loop that cannot run.
old = """                        if Checker.find_index_info(merged_infos, (info as ref[IndexInfo]).key_type) = null
                            merged_infos.add(info)"""
new = """                        merged_infos.add(info)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g14.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PREDICTION: STOPPIN RED on both `extends` fixtures, exactly as g11. MEASURED:
# UNGATED, exactly as g11 — and the pair is the proof rather than the hole. Two
# patches that break the loop in two different places leave the same five
# instruments silent, which is what an unreachable body looks like from outside.
old = """                let inherited this.get_index_infos_of_type(base)"""
new = """                let inherited null as ref[Array[ref[IndexInfo]?]]?"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g15.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PREDICTION: UNGATED, reader named. The reference stores a class's or interface's
# OWN members ahead of the inherited ones because a type RELATION is more likely to
# find a discriminating difference in them first; nothing here compares two types.
# The row exists so that the slice which does meets it.
old = """        if container_is_class_or_interface
        {
            let cs container as ref[Symbol]
            var i 0
            while i < n"""
new = """        if false
        {
            let cs container as ref[Symbol]
            var i 0
            while i < n"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g16.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PREDICTION: UNGATED, reader named — `%FEcall`, `%FEnew` and `%FEindex` would
# enter the property list as if they were members. Same slot as g12 and g15, and
# the third row that prices it: a members table nothing asks about.
old = """        if Checker.is_reserved_member_name(d, n)
            return false"""
new = """        if false
            return false"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g17.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PREDICTION: STOPGATE moved with FEWER EVENTS. MEASURED: UNGATED ON ALL FIVE — a
# WRONG PREDICTION, and the sharpest of the four. checkSignatureDeclaration already
# walks a call signature's parameter and return annotations from the members walk,
# and getTypeFromTypeNode memoises per NODE, so the signature this chapter builds
# asks a question that has already been asked and answered. **The chapter's walk is
# a SECOND visit everywhere, and a second visit logs nothing.** That is what makes
# the signature half of this slice invisible to every instrument here, and it is
# why the row names its reader instead: getSignaturesOfType, the call-resolution
# chapter.
old = """        set made.call_signatures: this.get_signatures_of_symbol(call_symbol)"""
new = """        set made.call_signatures: null"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g18.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PREDICTION: STOPGATE moved with FEWER EVENTS. MEASURED: UNGATED, g17's finding on
# the anonymous branch and the second half of it.
old = """        let construct_signatures this.get_signatures_of_symbol(new_symbol)
        if this.unported_mark() <> mark
            return
        let index_infos this.get_index_infos_of_symbol(symbol)"""
new = """        let construct_signatures null as ref[Array[ref[Signature]?]]?
        let index_infos this.get_index_infos_of_symbol(symbol)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g19.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PREDICTION: STOPPIN RED on all four type-literal fixtures — the branch is the
# whole of the second container kind this slice covers, so its removal puts
# `resolve-anonymous-type-members` back where `check-index-constraints` used to be.
old = """        if (Symbol.flags_of(symbol) & SymbolFlagsTypeLiteral) = 0
        {
            this.record_unported("resolve-anonymous-type-members", Symbol.flags_of(symbol))
            return
        }"""
new = """        if true
        {
            this.record_unported("resolve-anonymous-type-members", Symbol.flags_of(symbol))
            return
        }"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g20.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PREDICTION: STOPPIN RED on the type-literal fixtures AND on the class — the two
# swap places, the type literals stopping and the class's static side taking a
# branch built for a symbol it is not. Read beside g19: one row removes the branch,
# this one gives it the wrong input, and only the second says the TEST is what
# selects it.
old = """        if (Symbol.flags_of(symbol) & SymbolFlagsTypeLiteral) = 0"""
new = """        if (Symbol.flags_of(symbol) & SymbolFlagsTypeLiteral) <> 0"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g21.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PREDICTION: UNGATED WITH NOTHING MOVING, and it is a PROOF rather than a hole.
# The chapter header claims the sandwich is the identity for every type these three
# accessors are handed here — an object type is neither a union nor an
# intersection, and it is not instantiable and carries no primitive flag. This row
# is that claim measured instead of read.
old = """    function get_reduced_apparent_type(this, t: ref[Type]) returns ref[Type]?
    {
        let a this.get_reduced_type(t)"""
new = """    function get_reduced_apparent_type(this, t: ref[Type]) returns ref[Type]?
    {
        if true
            return t
        let a this.get_reduced_type(t)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g22.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PREDICTION: UNGATED, and the second half of g21's proof. The arm is WRITTEN
# because getBaseConstraintOfType exists (slice 81) and unknownType does; this row
# says nothing in this corpus reaches it, so writing it was fidelity rather than
# coverage.
old = """            let constraint this.get_base_constraint_of_type(t)
            if this.unported_mark() <> mark
                return null"""
new = """            this.record_unported("get-apparent-type-instantiable", t.flags)
            let constraint this.get_base_constraint_of_type(t)
            if this.unported_mark() <> mark
                return null"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g23.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PREDICTION: STOPPIN RED on every fixture that has an index signature — the guard
# is what routes an object type into the resolution at all, so inverting it makes
# every `check-index-constraint` disappear and nothing take its place.
old = """    function get_index_infos_of_structured_type(this, t: ref[Type]) returns ref[Array[ref[IndexInfo]?]]?
    {
        if (t.flags & TypeFlagsStructuredType) = 0
            return null"""
new = """    function get_index_infos_of_structured_type(this, t: ref[Type]) returns ref[Array[ref[IndexInfo]?]]?
    {
        if (t.flags & TypeFlagsStructuredType) <> 0
            return null"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g24.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PREDICTION: STOPPIN RED on every index fixture. It is g23's row one level down —
# the resolution runs, the infos are computed, and the slot they are stored in is
# not filled, so getIndexInfosOfType answers nothing. The pair is what separates
# `the members were not resolved` from `the members were resolved into nowhere`.
old = """        set sm.index_infos: index_infos"""
new = """        set sm.index_infos: null"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g25.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PREDICTION: STOPPIN RED on checker_members_interface_computed.ts at a LOSS — the
# `late-bound-members` stop disappears and the walk carries on with a members table
# the reference would have filled in. It is the direction no diagnostic instrument
# can see, which is why it is a pin row.
old = """        let dn Symbol.declaration_count(symbol)
        var i 0
        while i < dn
        {
            let d Symbol.declaration_at(symbol, i)"""
new = """        let dn 0
        var i 0
        while i < dn
        {
            let d Symbol.declaration_at(symbol, i)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g26.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PREDICTION: STOPPIN RED on the computed fixture — this is the FIRST DRAFT of the
# test and the slice's method finding. The marker is on the MEMBER's symbol and the
# question is asked of the CONTAINER, whose members table is empty for exactly this
# shape; measured, `SymbolTable.length` answers 0. The row reproduces a silence
# that read as a working guard.
old = """        let dn Symbol.declaration_count(symbol)
        var i 0
        while i < dn
        {
            let d Symbol.declaration_at(symbol, i)
            set i: i + 1
            if d = null
                continue
            let list AstNode.member_list_of(d as ref[AstNode])
            let mn AstNode.list_count(list)
            var j 0
            while j < mn
            {
                let m AstNode.child_in_list(list, j)
                set j: j + 1
                if m = null
                    continue
                let name AstNode.name_of(m as ref[AstNode])
                if name = null
                    continue
                if AstNode.kind_of(name as ref[AstNode]) = KindComputedPropertyName
                {
                    this.record_unported("late-bound-members", Symbol.flags_of(symbol))
                    return null
                }
            }
        }
        members"""
new = """        if members = null
            return members
        var cd null as pointer[char]
        let cl Binder.internal_name(host, "computed", &cd)
        if SymbolTable.get(members as pointer[SymbolTable], cd, cl) <> null
        {
            this.record_unported("late-bound-members", Symbol.flags_of(symbol))
            return null
        }
        members"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g27.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PREDICTION: STOPPIN RED on nearly EVERY fixture by INVENTION. MEASURED: STOPGATE
# moved and the STOPPIN did NOT — a WRONG PREDICTION that says something about the
# port's own shape. A container with no index signature has no `%FEindex` symbol, so
# get_index_infos_of_symbol answers NULL and the FIRST guard (`if infos = null`)
# takes it; the length test can only fire where a list EXISTS and is empty, which in
# this port is nowhere the pin files reach. Upstream the two are ONE test, because a
# nil Go slice has length zero — **the port has two states where the reference has
# one, and only the first of them is load-bearing.**
old = """        let list infos as ref[Array[ref[IndexInfo]?]]
        if list.get_length() = 0
            return"""
new = """        let list infos as ref[Array[ref[IndexInfo]?]]
        if false
            return"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY
cat > "$PATCHDIR/g28.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PREDICTION: UNGATED with nothing moving — not one of the eighteen pin files is a
# JavaScript file, so the guard's first conjunct is false everywhere here. It is
# the fourth copy of a guard that stands three times already, and the row is what
# says this copy has the same input as the others: none.
old = """        if Parser.is_in_js_file(node) = false
            return false
        let k AstNode.kind_of(node)
        var full_kind false
        if k = KindFunctionDeclaration
            set full_kind: true
        if k = KindMethodDeclaration
            set full_kind: true
        if k = KindFunctionExpression
            set full_kind: true
        if k = KindArrowFunction
            set full_kind: true
        if full_kind = false
            return false
        if AstNode.full_signature_of(node) = null
            return false
        this.record_unported("get-signature-of-full-signature-type", k)
        true"""
new = """        false"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g29.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# THE DEFECT ROW, and it is the WHOLE of the pre-slice state: both guards of the
# base-type chain reverted from the COUNTER to the FLAG.
# PREDICTION: STOPGATE moved. MEASURED: moved, and the direction is worth reading —
# events 8489 -> 8501, i.e. the DEFECT costs twelve MORE arrivals, because a walk
# that should have stopped carries on and stops somewhere else. The flag answers
# *has this UNIT stopped*, so after a file's first report neither pair can fire
# again — getBaseTypes
# MEMOISES AN EMPTY BASE-TYPE LIST for an interface that has a base, and
# checkInheritedPropertiesAreIdentical then reads `len < 2` off it and answers TRUE,
# so the interface arm walks on past a stop it should have taken. It is the one row
# of this battery that is a fix rather than a port, and it is here because slice 85
# is the first READER of the answer: resolve_object_type_members would skip every
# inherited member without a word. Read beside g30, which shows which half of the
# pair is the observable one. The 48 sites in this file that still spell the pair
# with the flag are a sweep of their own.
old = """            let before this.unported_mark()
            if (t.object_flags & ObjectFlagsTuple) <> 0"""
new = """            let before this.is_unported()
            if (t.object_flags & ObjectFlagsTuple) <> 0"""
assert s.count(old) == 1
s = s.replace(old, new, 1)
old2 = """                this.resolve_base_types_of_interface(t)
                if this.unported_mark() <> before"""
new2 = """                this.resolve_base_types_of_interface(t)
                if this.is_unported() <> before"""
assert s.count(old2) == 1
s = s.replace(old2, new2, 1)
old3 = """        let before this.unported_mark()
        let base_types this.get_base_types(t)
        if this.unported_mark() <> before
            return false"""
new3 = """        let before this.is_unported()
        let base_types this.get_base_types(t)
        if this.is_unported() <> before
            return false"""
assert s.count(old3) == 1
open(p, "w").write(s.replace(old3, new3, 1))
PY
cat > "$PATCHDIR/g30.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# g29's INNER half alone: getBaseTypes' own pair back on the flag, the caller's left
# on the counter.
# PREDICTION: UNGATED, and MEASURED so — the row that says which half of g29 an
# instrument can see. getBaseTypes with the flag answers an EMPTY list where it should answer a
# stop — but the stop was already recorded by resolve_base_types_of_interface, and
# checkInheritedPropertiesAreIdentical's counter-guard reads exactly that. So the
# caller catches what the callee dropped, and the two spellings coincide from
# outside. **A guard that is subsumed is still a guard: it is what the SECOND caller
# will find missing**, and resolve_object_type_members is that caller.
old = """            let before this.unported_mark()
            if (t.object_flags & ObjectFlagsTuple) <> 0"""
new = """            let before this.is_unported()
            if (t.object_flags & ObjectFlagsTuple) <> 0"""
assert s.count(old) == 1
s = s.replace(old, new, 1)
old2 = """                this.resolve_base_types_of_interface(t)
                if this.unported_mark() <> before"""
new2 = """                this.resolve_base_types_of_interface(t)
                if this.is_unported() <> before"""
assert s.count(old2) == 1
open(p, "w").write(s.replace(old2, new2, 1))
PY

# ── the DRY RUN: every patch is applied to a COPY before the first build ──
DRY=$WORK/dry
bold "DRY RUN — every patch applied to a copy, so a moved anchor is found before any measuring"
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g01.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g01 applies"; else red "  g01 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g02.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g02 applies"; else red "  g02 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g03.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g03 applies"; else red "  g03 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g04.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g04 applies"; else red "  g04 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g05.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g05 applies"; else red "  g05 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g06.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g06 applies"; else red "  g06 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g07.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g07 applies"; else red "  g07 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g08.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g08 applies"; else red "  g08 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g09.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g09 applies"; else red "  g09 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g10.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g10 applies"; else red "  g10 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g11.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g11 applies"; else red "  g11 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g12.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g12 applies"; else red "  g12 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g13.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g13 applies"; else red "  g13 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g14.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g14 applies"; else red "  g14 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g15.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g15 applies"; else red "  g15 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g16.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g16 applies"; else red "  g16 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g17.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g17 applies"; else red "  g17 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g18.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g18 applies"; else red "  g18 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g19.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g19 applies"; else red "  g19 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g20.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g20 applies"; else red "  g20 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g21.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g21 applies"; else red "  g21 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g22.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g22 applies"; else red "  g22 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g23.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g23 applies"; else red "  g23 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g24.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g24 applies"; else red "  g24 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g25.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g25 applies"; else red "  g25 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g26.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g26 applies"; else red "  g26 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g27.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g27 applies"; else red "  g27 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g28.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g28 applies"; else red "  g28 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g29.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g29 applies"; else red "  g29 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
if python3 "$PATCHDIR/g30.py" "$DRY/f.scaly" >/dev/null 2>&1; then echo "  g30 applies"; else red "  g30 DOES NOT APPLY — its anchor has moved."; exit 2; fi
rm -rf "$DRY"

baseline

control "g01 the three call sites reverted to their stop (the premise)" $CHECKER "$PATCHDIR/g01.py"
control "g02 resolveStructuredTypeMembers' MembersResolved memo removed" $CHECKER "$PATCHDIR/g02.py"
control "g03 the Reference arm tested AFTER ClassOrInterface" $CHECKER "$PATCHDIR/g03.py"
control "g04 resolveDeclaredMembers' record attached AFTER its three lists" $CHECKER "$PATCHDIR/g04.py"
control "g05 getSignaturesOfSymbol's is_function_like filter removed" $CHECKER "$PATCHDIR/g05.py"
control "g06 getSignaturesOfSymbol's overload skip removed" $CHECKER "$PATCHDIR/g06.py"
control "g07 isValidIndexKeyType narrowed to String" $CHECKER "$PATCHDIR/g07.py"
control "g08 isValidIndexKeyType forced true" $CHECKER "$PATCHDIR/g08.py"
control "g09 the duplicate-key guard inside getIndexInfosOfIndexSymbol removed" $CHECKER "$PATCHDIR/g09.py"
control "g10 the index signature's VALUE type frozen at `any`" $CHECKER "$PATCHDIR/g10.py"
control "g11 the BASE LOOP removed" $CHECKER "$PATCHDIR/g11.py"
control "g12 addInheritedMembers made a no-op" $CHECKER "$PATCHDIR/g12.py"
control "g13 the inherited index infos' findIndexInfo filter dropped" $CHECKER "$PATCHDIR/g13.py"
control "g14 the base loop's inherited index infos dropped entirely" $CHECKER "$PATCHDIR/g14.py"
control "g15 getNamedMembers' two passes collapsed into one" $CHECKER "$PATCHDIR/g15.py"
control "g16 isReservedMemberName forced false" $CHECKER "$PATCHDIR/g16.py"
control "g17 resolveDeclaredMembers' CALL signatures dropped" $CHECKER "$PATCHDIR/g17.py"
control "g18 resolveAnonymousTypeMembers' CONSTRUCT signatures dropped" $CHECKER "$PATCHDIR/g18.py"
control "g19 resolveAnonymousTypeMembers' TypeLiteral branch turned into a stop" $CHECKER "$PATCHDIR/g19.py"
control "g20 the TypeLiteral test inverted" $CHECKER "$PATCHDIR/g20.py"
control "g21 getReducedApparentType replaced by the identity" $CHECKER "$PATCHDIR/g21.py"
control "g22 getApparentType's instantiable arm turned into a stop" $CHECKER "$PATCHDIR/g22.py"
control "g23 getIndexInfosOfStructuredType's StructuredType guard inverted" $CHECKER "$PATCHDIR/g23.py"
control "g24 setStructuredTypeMembers' index_infos slot never written" $CHECKER "$PATCHDIR/g24.py"
control "g25 getMembersOfSymbol's late-binding walk removed" $CHECKER "$PATCHDIR/g25.py"
control "g26 the late-binding test put back on the binder's `%FEcomputed` MARKER" $CHECKER "$PATCHDIR/g26.py"
control "g27 checkIndexConstraints' empty-list guard dropped" $CHECKER "$PATCHDIR/g27.py"
control "g28 getSignatureOfFullSignatureType's guard removed" $CHECKER "$PATCHDIR/g28.py"
control "g29 both base-type marks reverted from the counter to the flag (the defect)" $CHECKER "$PATCHDIR/g29.py"
control "g30 only getBaseTypes' own mark reverted (the subsumed half)" $CHECKER "$PATCHDIR/g30.py"

echo
echo "################################################################"
bold "DONE — read every row against its PREDICTION, not against its colour."
