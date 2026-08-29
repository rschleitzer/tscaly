#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice93.sh — the slice-93 battery: THE FLOW WALK.
#
# ★★★ THE CHAPTER HAS TWO CALLERS AND THEY NEEDED DIFFERENT HALVES OF IT, WHICH IS
# WHY THIS BATTERY HAS TWO FAMILIES. checkIdentifier wants a flow TYPE and stands
# behind getUnionType at nine different doors; checkAllCodePathsInNonVoidFunction
# ReturnOrThrow wants only isReachableFlowNode, which asks for no type at all.
# Both wore the tag `flow-graph` (slice 77 named it precisely because two chapters
# share it) and they are two walls, not one — h20 to h24 are the second family and
# they are the rows that carry the slice's whole DIAGNOSTIC product.
#
# ★★★ THE POSITIVE INSTRUMENT IS THE STOP LOG AND NOT diagcheck, and the reason is
# arithmetic: this slice adds THREE diagnostics over the corpus (two TS2355 and one
# TS7022) and REMOVES 127 stop events. A battery graded on diagnostics would call
# almost every row here indistinguishable. What each row breaks is where the walk
# STOPS, which the STOPPIN reads per pin file in order and the STOPGATE counts over
# the whole corpus.
#
# ★★★ ITERATE AT STAGE 1 AND CONFIRM AT STAGE 2 ONCE — slice 64's rule. The
# recorded verdicts are stage 1's.
#
# Usage (nothing may edit the tree while this runs, and no second harness may own
# tests/out — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # stage 1
#   packages/tscaly/tests/controls-slice93.sh 2>&1 | tee /tmp/battery93.log
#
set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.0/tscaly/checker.scaly
AST=$PKG/0.1.0/tscaly/ast.scaly
PARSER=$PKG/0.1.0/tscaly/parser.scaly
FIX=$PKG/tests/fixtures

LIBSCALY=${LIBSCALY:-/tmp/libscaly.a}
SCALYC=${SCALYC:-$REPO/scalyc/build/scalyc}

# ★ ONE MECHANISM PER FILE (slice 72's rule). Eleven files: the ten this slice wrote,
# one per arm of the walk (the tenth, `flowwalk_never_call.ts`, arriving from stage
# 2 as finding six's reduction and turning h24 into a control), plus slice 92's `flow_unreachable.ts` — kept because it
# is the only pin file whose graph carries an UNREACHABLE flow node that an
# identifier is actually reached through, and the walk's default arm is the one arm
# no fixture written around a TYPE produces.
PINFILES="
$FIX/flowwalk_straight.ts
$FIX/flowwalk_branch.ts
$FIX/flowwalk_start.ts
$FIX/flowwalk_unreachable.ts
$FIX/flowwalk_loop.ts
$FIX/flowwalk_uninitialized.ts
$FIX/flowwalk_return_paths.ts
$FIX/flowwalk_reduce.ts
$FIX/flowwalk_matching.ts
$FIX/flowwalk_never_call.ts
$FIX/flow_unreachable.ts
"
red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl93)

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

flowpin_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$("$WORK/tscaly_types" --flow "$f" 2>/dev/null | tr '\n' '|')"
  done
}

# ★★★ THE WHOLE-CORPUS FLOWGATE, and slice 92's h08/h11/h25 are why it is here
# beside a pin rather than instead of it: eleven fixtures aimed at eleven
# mechanisms still missed three of them, because the shape that distinguishes an
# arm is not the shape a fixture author writes around. The eleven pin files here
# carry a few dozen trace lines between them; the corpus carries two thousand.
#
# ★ The units are dispatched in PARALLEL and each writes its own file, then the
# files are concatenated in a fixed order. A shared pipe would interleave and the
# checksum would move on its own — an instrument that disagrees with itself is
# worse than none.
flowgate() {
  local i=0 u
  rm -rf "$WORK/flowout" "$WORK/pairs"; mkdir -p "$WORK/flowout"
  while IFS= read -r u; do
    printf '%s\n%s\n' "$u" "$(printf '%s/flowout/%06d' "$WORK" "$i")"
    i=$((i+1))
  done < "$WORK/units.txt" > "$WORK/pairs"
  xargs -P 8 -n 2 sh -c '"$0" --flow "$1" > "$2" 2>/dev/null' "$WORK/tscaly_types" < "$WORK/pairs"
  cat "$WORK"/flowout/* > "$WORK/flow.all"
  local f v a
  f=$(grep -c '^F ' "$WORK/flow.all"); v=$(grep -c '^V ' "$WORK/flow.all"); a=$(grep -c '^A ' "$WORK/flow.all")
  echo "$f $v $a $(cksum < "$WORK/flow.all" | cut -d' ' -f1)"
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

DIAG_BASE=""; DIAG_LINES=""; DIAG_DIAGS=""; STOP_BASE=""; FLOW_BASE=""

baseline() {
  echo "################################################################"
  bold "BASELINE — seven instruments"
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
  flowpin_of > "$WORK/base.flow"
  find "$PKG/tests/out/cases" -path '*/units/*' -type f \
       \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.mjs' -o -name '*.cjs' \) \
       | sort > "$WORK/units.txt"
  STOP_BASE=$(stopgate)
  FLOW_BASE=$(flowgate)
  echo
  echo "  the STOPPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.stops"
  echo
  echo "  the TAGPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.tags"
  echo
  echo "  BASELINE   diagcheck $DIAG_BASE consistent, $DIAG_LINES speaking, $DIAG_DIAGS diagnostics"
  echo "             stopgate  (matched units speaking events other) = $STOP_BASE"
  echo "             flowgate  (invocations visits answers checksum) over $(wc -l < "$WORK/units.txt" | tr -d ' ') units = $FLOW_BASE"
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
  flowpin_of > "$WORK/ctl.flow"
  stop=$(stopgate)
  local flow
  flow=$(flowgate)
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
    echo "  diagpin   unmoved — all eleven pin files answer the same C section."
  else
    green "diagpin   RED"
    diff "$WORK/base.diags" "$WORK/ctl.diags" | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.tags" "$WORK/ctl.tags"; then
    echo "  tagpin    unmoved — all eleven fixtures answer the same tag."
  else
    green "tagpin    RED"
    diff "$WORK/base.tags" "$WORK/ctl.tags" | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.stops" "$WORK/ctl.stops"; then
    echo "  stoppin   unmoved — all eleven fixtures log the same stops, in order."
  else
    green "stoppin   RED"
    diff "$WORK/base.stops" "$WORK/ctl.stops" | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.flow" "$WORK/ctl.flow"; then
    echo "  flowpin   unmoved — all eleven fixtures trace the same walk."
  else
    green "flowpin   RED"
    diff "$WORK/base.flow" "$WORK/ctl.flow" | cut -c1-200 | sed 's/^/    /'
    moved=1
  fi
  if [ "$stop" = "$STOP_BASE" ]; then
    echo "  stopgate  unmoved — $stop"
  else
    green "stopgate  MOVED   $STOP_BASE -> $stop   (matched units speaking events other)"
    moved=1
  fi
  if [ "$flow" = "$FLOW_BASE" ]; then
    echo "  flowgate  unmoved — $flow"
  else
    green "flowgate  MOVED   $FLOW_BASE -> $flow   (invocations visits answers checksum)"
    moved=1
  fi
  if [ "$moved" = 0 ]; then
    if [ "$speaking" != "$DIAG_LINES" ] || [ "$diags" != "$DIAG_DIAGS" ]; then
      echo "  ungated on all seven, WITH A NUMBER: $DIAG_LINES/$DIAG_DIAGS -> $speaking/$diags."
    else
      red "UNGATED ON ALL SEVEN AND NOTHING MOVED AT ALL."
      echo "  Decide which of §3.5v's four kinds this is. A row that predicted"
      echo "  this is a measurement; a row that did not is a hole in the battery."
    fi
  fi
  return 0
}

PATCHDIR=$WORK/patches
mkdir -p "$PATCHDIR"

python3 - "$PATCHDIR" <<'MKPATCHES'
import os, sys
D = sys.argv[1]
os.makedirs(D, exist_ok=True)

P = {}
P['h01'] = ('''# THE PREMISE (family one) — checkIdentifier's flow call reverted to the stop that
# stood there until this slice. PREDICTION: TAGPIN + STOPPIN RED on every pin file
# whose identifiers reach the flow, and the STOPGATE moved by the whole chapter.''',
'''old = """        let flow_type this.get_flow_type_of_reference_ex(node, ty, initial, flow_container, null)"""
new = """        this.record_unported("flow-graph", KindIdentifier)
        let flow_type: ref[Type]? null"""''')
P['h02'] = ('''# THE PREMISE (family two) — the non-void return path reverted to its stop.
# PREDICTION: diagcheck UNGATED at a LOSS (both codes disappear, and a subsequence
# cannot see a line we fail to emit), DIAGPIN RED on flowwalk_return_paths, STOPGATE
# moved. The row that separates the two families: this one needs no type at all.''',
'''old = """        let fhir_mark this.unported_mark()
        let fhir this.function_has_implicit_return(fn)"""
new = """        let fhir_mark this.unported_mark()
        this.record_unported("flow-graph", AstNode.kind_of(fn))
        let fhir this.function_has_implicit_return(fn)"""''')
P['h03'] = ('''# The Start arm never hops into the containing function. PREDICTION: STOPPIN RED on
# flowwalk_start — a nested function's reference to an outer name stops at its own
# container's initial type instead of walking the outer graph.''',
'''old = """                if hop
                {
                    let next AstNode.flow_node_of(cn)"""
new = """                if false
                {
                    let next AstNode.flow_node_of(cn)"""''')
P['h04'] = ('''# The Start arm ALWAYS hops — the four exclusions dropped. PREDICTION: STOPPIN RED,
# h03's complement. The container test is what keeps the walk from leaving its own
# function; without it a reference walks out of the file.''',
'''old = """                if hop
                {
                    let next AstNode.flow_node_of(cn)"""
new = """                set hop: true
                if hop
                {
                    let next AstNode.flow_node_of(cn)"""''')
P['h05'] = ('''# The Start arm answers the DECLARED type instead of the initial one. PREDICTION:
# nothing moves — and that is the measurement. Where assumeInitialized holds the two
# are the same object; where it does not, getOptionalType stops before the walk
# begins. The row prices the whole distinction at the corpus this slice can see.''',
'''old = """            ; "At the top of the flow we have the initial type."
            return f.initial_type"""
new = """            ; "At the top of the flow we have the initial type."
            return f.declared_type"""''')
P['h06'] = ('''# The per-invocation shared-node MEMO never hits. PREDICTION: nothing moves. It is a
# memo of a pure function of (reference, graph), so removing it can only cost time —
# the row exists to say that in a number rather than in a comment.''',
'''old = """                        if sfr.flow = flow
                        {
                            set f.depth: f.depth - 1"""
new = """                        if false
                        {
                            set f.depth: f.depth - 1"""''')
P['h07'] = ('''# The shared-node memo POISONED — it records the declared type instead of the type
# the arm answered. PREDICTION: h06's complement. If h06 is silent because the memo
# never hits, this is silent too; if the memo hits, this one is red and h06 is not.
# The pair is the only way to tell *unused* from *unusable*.''',
'''old = """                set *made: SharedFlow(shared_flow, t, inc)"""
new = """                set *made: SharedFlow(shared_flow, f.declared_type, inc)"""''')
P['h08'] = ('''# The assignment arm never matches its target. PREDICTION: STOPPIN RED and the
# STOPGATE moved — every assignment becomes *does not affect the reference*, so the
# walk runs past it to the declaration and answers the initial type.''',
'''old = """        if this.is_matching_reference(reference, node)
        {
            if this.is_reachable_flow_node(flow) = false"""
new = """        if false
        {
            if this.is_reachable_flow_node(flow) = false"""''')
P['h09'] = ('''# The assignment arm's REACHABILITY test removed. PREDICTION: STOPPIN RED on
# flowwalk_unreachable — an assignment behind a `return` answers the declared type
# instead of unreachableNeverType, and the tail that turns that back into the
# declared type never runs.''',
'''old = """            if this.is_reachable_flow_node(flow) = false
                return unreachable_never_type
            if Checker.get_assignment_target_kind(node) = AssignmentKindCompound"""
new = """            if false
                return unreachable_never_type
            if Checker.get_assignment_target_kind(node) = AssignmentKindCompound"""''')
P['h10'] = ('''# The assignment arm's UNION test forced TRUE. PREDICTION: STOPGATE moved by every
# assignment on a walked path — the reference's own comment says an assignment
# narrows only a union, and this row is what that comment costs when it is wrong.''',
'''old = """            if (declared.flags & TypeFlagsUnion) <> 0
            {"""
new = """            if true
            {"""''')
P['h11'] = ('''# containsMatchingReference's branch removed. PREDICTION: ungated — the reference is
# an identifier at every arrival this slice has, and an identifier has no dotted
# prefix, so the walk over `source.Expression()` runs zero times. The row is the
# containment proof for the whole dotted half of the chapter.''',
'''old = """        if this.contains_matching_reference(reference, node)
        {"""
new = """        if false
        {"""''')
P['h12'] = ('''# The `for (const _ in ref)` non-null arm removed. PREDICTION: ungated, and paired
# with h11: both are shapes only a dotted reference reaches.''',
'''old = """                            if hit
                            {"""
new = """                            if false
                            {"""''')
P['h13'] = ('''# getBranchLabelAntecedents ignores the reduce stack. PREDICTION: STOPPIN RED on
# flowwalk_reduce — a `try`/`finally` label answers its ORIGINAL antecedents instead
# of the reduced set, which is three antecedent sets from three directions.''',
'''old = """        var cur reduce_labels
        while cur <> null"""
new = """        var cur: ref[ReduceLabelStack]? null
        while cur <> null"""''')
P['h14'] = ('''# The BRANCH label's single-antecedent collapse removed. PREDICTION: STOPGATE moved
# — a one-antecedent junction goes through the antecedent loop instead of being
# walked past, and the loop's early-out is the only thing between it and the union.''',
'''old = """            let al ants as ref[FlowList]
            if al.next = null
            {
                set out_next: al.flow
                return null
            }
            return this.get_type_at_flow_branch_label(f, flow, al, out_incomplete)"""
new = """            let al ants as ref[FlowList]
            if false
            {
                set out_next: al.flow
                return null
            }
            return this.get_type_at_flow_branch_label(f, flow, al, out_incomplete)"""''')
P['h15'] = ('''# The LOOP label's single-antecedent collapse removed. PREDICTION: STOPGATE moved
# hard — every single-antecedent loop label becomes the loop-label stop, and that is
# the shape a `for` header produces before its back edge exists.''',
'''old = """            let al ants as ref[FlowList]
            if al.next = null
            {
                set out_next: al.flow
                return null
            }
            return this.get_type_at_flow_loop_label(f, flow, out_incomplete)"""
new = """            let al ants as ref[FlowList]
            if false
            {
                set out_next: al.flow
                return null
            }
            return this.get_type_at_flow_loop_label(f, flow, out_incomplete)"""''')
P['h16'] = ('''# THE BRANCH LABEL'S EARLY-OUT REMOVED, and this is the row the chapter turns on:
# *"if the type at a particular antecedent path is the declared type and the
# reference is known to always be assigned, there is no reason to process more
# antecedents"*. PREDICTION: STOPGATE moved by every junction in the corpus, because
# without it the antecedent list is built and a second distinct type is the union.''',
'''old = """            if fty = (f.declared_type as ref[Type])
            {
                if (f.declared_type as ref[Type]) = (f.initial_type as ref[Type])
                    return fty
            }"""
new = """            if false
            {
                if (f.declared_type as ref[Type]) = (f.initial_type as ref[Type])
                    return fty
            }"""''')
P['h17'] = ('''# The branch label's DUPLICATE check removed — every antecedent type is appended.
# PREDICTION: h16's complement. With the early-out live the list rarely gets past
# one member at all, so this should move much less than h16 does; the pair says
# which of the two mechanisms keeps the union out of this corpus.''',
'''old = """            if present = false
                types.add(fty)"""
new = """            types.add(fty)"""''')
P['h18'] = ('''# The switch BYPASS branch never recognised. PREDICTION: measured rather than
# predicted. A bypass antecedent is an empty switch clause, which exists only where
# a `switch` with no default sits on the walked path.''',
'''old = """                    if AstNode.flow_clause_start_of(antecedent.node) = AstNode.flow_clause_end_of(antecedent.node)
                    {"""
new = """                    if false
                    {"""''')
P['h19'] = ('''# The condition arm's NEVER early-out removed. PREDICTION: STOPGATE moved — without
# it a condition whose antecedent is already never falls into narrowType, which is
# a stop, so a reference after `if (false) {}` stops instead of answering.''',
'''old = """        if (ty.flags & TypeFlagsNever) <> 0
        {
            set out_incomplete: inc
            return ty
        }"""
new = """        if false
        {
            set out_incomplete: inc
            return ty
        }"""''')
P['h20'] = ('''# The ReduceLabel arm pushes NOTHING. PREDICTION: STOPPIN RED on flowwalk_reduce,
# and it is h13 from the other side — h13 breaks the READ of the stack and this
# breaks the WRITE, so a battery with only one of them cannot tell a broken stack
# from a stack nothing consults.''',
'''old = """            set f.reduce_labels: cell
            let t this.get_type_at_flow_node(f, flow.antecedent as ref[FlowNode], out_incomplete)"""
new = """            set f.reduce_labels: saved
            let t this.get_type_at_flow_node(f, flow.antecedent as ref[FlowNode], out_incomplete)"""''')
P['h21'] = ('''# isReachableFlowNodeWorker's SHARED cache never hits. PREDICTION: nothing moves —
# it is a memo of a pure walk over the graph. The row exists because the reference's
# own comment calls it a cache and the reduce-label arm INVALIDATES a neighbouring
# one, which reads as correctness rather than as speed.''',
'''old = """                if no_cache_check = false
                {
                    let hit this.flow_reachable_lookup(flow)"""
new = """                if false
                {
                    let hit this.flow_reachable_lookup(flow)"""''')
P['h22'] = ('''# isReachableFlowNodeWorker's branch-label arm answers FALSE — no branch is ever
# reachable. PREDICTION: diagcheck RED by INVENTION or DIAGPIN RED: a function whose
# end point is reached through a junction stops looking like one that falls off the
# end, so TS2355 and TS2534 disappear, and every assignment behind a junction
# answers unreachableNeverType.''',
'''old = """                            if this.is_reachable_flow_node_worker(reduce_labels, l.flow as ref[FlowNode], false)
                                return true"""
new = """                            if false
                                return true"""''')
P['h23'] = ('''# The reachability walk's DEFAULT arm ignores the Unreachable flag. PREDICTION:
# DIAGPIN RED on flowwalk_return_paths — a body that ends in `throw` has an
# unreachable end flow node, and with the bit ignored it reports as one that falls
# off the end.''',
'''old = """            if advance = false
                return (flags & FlowFlagsUnreachable) = 0"""
new = """            if advance = false
                return true"""''')
P['h24'] = ('''# functionHasImplicitReturn forced TRUE. PREDICTION: diagcheck RED by INVENTION —
# every annotated function in the corpus reports TS2355 or TS2534, including the
# ones that return on every path.''',
'''old = """        let end AstNode.end_flow_node_of(fn)
        if end = null
            return false
        this.is_reachable_flow_node(end as ref[FlowNode])"""
new = """        let end AstNode.end_flow_node_of(fn)
        if end = null
            return false
        true"""''')
P['h25'] = ('''# functionHasImplicitReturn forced FALSE. PREDICTION: DIAGPIN RED at a LOSS on
# flowwalk_return_paths with diagcheck ungated — h24's complement, and the half a
# subsequence instrument cannot see on its own.''',
'''old = """        let end AstNode.end_flow_node_of(fn)
        if end = null
            return false
        this.is_reachable_flow_node(end as ref[FlowNode])"""
new = """        let end AstNode.end_flow_node_of(fn)
        if end = null
            return false
        false"""''')
P['h26'] = ('''# The two reachable report arms SWAPPED. PREDICTION: DIAGPIN RED on
# flowwalk_return_paths — a `never` return type answers TS2355 and an unannotated
# fall-off answers TS2534. A `switch` with no subject is an ORDERED chain and the
# order is the answer (§3.5u); this row is that sentence measured.''',
'''old = """        if (ty.flags & TypeFlagsNever) <> 0
        {
            this.error_on_node(error_node, DiagA_function_returning_never_cannot_have_a_reachable_end_point)
            return
        }
        if has_explicit_return = false
        {
            this.error_on_node(error_node, DiagA_function_whose_declared_type_is_neither_undefined_void_nor_any_must_return_a_value)
            return
        }"""
new = """        if has_explicit_return = false
        {
            this.error_on_node(error_node, DiagA_function_whose_declared_type_is_neither_undefined_void_nor_any_must_return_a_value)
            return
        }
        if (ty.flags & TypeFlagsNever) <> 0
        {
            this.error_on_node(error_node, DiagA_function_returning_never_cannot_have_a_reachable_end_point)
            return
        }"""''')
P['h27'] = ('''# The errorNode walk reduced to the function itself. PREDICTION: DIAGPIN RED on
# flowwalk_return_paths — the SPAN moves from the return type annotation to the
# whole declaration, which is the half of a diagnostic no message text carries.''',
'''old = """        var error_node: ref[AstNode]? AstNode.type_of(fn)
        if error_node = null
            set error_node: AstNode.full_signature_of(fn)"""
new = """        var error_node: ref[AstNode]? null
        if error_node = null
            set error_node: null"""''')
P['h28'] = ('''# assumeInitialized forced TRUE. PREDICTION: the STOPGATE moved — every
# getOptionalType stop disappears and an uninitialized `let` answers its declared
# type. ★It is the direction that would pass a diagcheck run green while answering
# wrongly, which is why the stop log is this battery's positive instrument.''',
'''old = """        var assume_initialized false
        if is_parameter
            set assume_initialized: true"""
new = """        var assume_initialized true
        if is_parameter
            set assume_initialized: true"""''')
P['h29'] = ('''# assumeInitialized forced FALSE. PREDICTION: the STOPGATE moved the other way —
# every reference reaching the flow stops at getOptionalType, so the chapter
# produces nothing at all. h28's complement, and between them they price the
# eleven-term disjunction that slice 91 called not worth asking.''',
'''old = """        if (AstNode.flags_of(decl) & NodeFlagsAmbient) <> 0
            set assume_initialized: true"""
new = """        if (AstNode.flags_of(decl) & NodeFlagsAmbient) <> 0
            set assume_initialized: true
        set assume_initialized: false"""''')
P['h30'] = ('''# The container-extending loop never runs. PREDICTION: measured. A closed-over
# `const` is what the loop exists for, and flowwalk_start is written around one —
# if this comes back silent, the flow container the loop would have reached is the
# one the walk reaches anyway through the Start arm's hop.''',
'''old = """        var extending true
        while extending"""
new = """        var extending false
        while extending"""''')
P['h31'] = ('''# isMatchingReference's declaration half removed — a VariableDeclaration or
# BindingElement target no longer matches the reference's exported symbol.
# PREDICTION: STOPGATE moved. It is the arm that makes `let s: string = p` an
# assignment TO s rather than a node the walk runs past.''',
'''old = """        var target_declares false
        if tk = KindVariableDeclaration
            set target_declares: true"""
new = """        var target_declares false
        if false
            set target_declares: true"""''')

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

control "h01 THE PREMISE — checkIdentifier's flow call reverted" $CHECKER "$PATCHDIR/h01.py"
control "h02 THE PREMISE — the non-void return path reverted" $CHECKER "$PATCHDIR/h02.py"
control "h03 the Start arm's hop forced FALSE" $CHECKER "$PATCHDIR/h03.py"
control "h04 the Start arm's hop forced TRUE" $CHECKER "$PATCHDIR/h04.py"
control "h05 the Start arm answers declaredType, not initialType" $CHECKER "$PATCHDIR/h05.py"
control "h06 the shared-flow memo never hits" $CHECKER "$PATCHDIR/h06.py"
control "h07 the shared-flow memo poisoned" $CHECKER "$PATCHDIR/h07.py"
control "h08 the assignment arm never matches" $CHECKER "$PATCHDIR/h08.py"
control "h09 the assignment arm's reachability test removed" $CHECKER "$PATCHDIR/h09.py"
control "h10 the assignment arm's union test forced TRUE" $CHECKER "$PATCHDIR/h10.py"
control "h11 containsMatchingReference's branch removed" $CHECKER "$PATCHDIR/h11.py"
control "h12 the for-in non-null arm removed" $CHECKER "$PATCHDIR/h12.py"
control "h13 getBranchLabelAntecedents ignores the reduce stack" $CHECKER "$PATCHDIR/h13.py"
control "h14 the branch label's single-antecedent collapse removed" $CHECKER "$PATCHDIR/h14.py"
control "h15 the loop label's single-antecedent collapse removed" $CHECKER "$PATCHDIR/h15.py"
control "h16 the branch label's early-out removed" $CHECKER "$PATCHDIR/h16.py"
control "h17 the branch label's duplicate check removed" $CHECKER "$PATCHDIR/h17.py"
control "h18 the switch bypass branch never recognised" $CHECKER "$PATCHDIR/h18.py"
control "h19 the condition arm's never early-out removed" $CHECKER "$PATCHDIR/h19.py"
control "h20 the ReduceLabel arm pushes nothing" $CHECKER "$PATCHDIR/h20.py"
control "h21 the reachability memo never hits" $CHECKER "$PATCHDIR/h21.py"
control "h22 the reachability branch-label arm answers FALSE" $CHECKER "$PATCHDIR/h22.py"
control "h23 the reachability default arm ignores Unreachable" $CHECKER "$PATCHDIR/h23.py"
control "h24 functionHasImplicitReturn forced TRUE" $CHECKER "$PATCHDIR/h24.py"
control "h25 functionHasImplicitReturn forced FALSE" $CHECKER "$PATCHDIR/h25.py"
control "h26 the two reachable report arms swapped" $CHECKER "$PATCHDIR/h26.py"
control "h27 the errorNode walk reduced to the function" $CHECKER "$PATCHDIR/h27.py"
control "h28 assumeInitialized forced TRUE" $CHECKER "$PATCHDIR/h28.py"
control "h29 assumeInitialized forced FALSE" $CHECKER "$PATCHDIR/h29.py"
control "h30 the container-extending loop never runs" $CHECKER "$PATCHDIR/h30.py"
control "h31 isMatchingReference's declaration half removed" $CHECKER "$PATCHDIR/h31.py"

echo
echo "################################################################"
bold "DONE — read every row against its PREDICTION, not against its colour."
