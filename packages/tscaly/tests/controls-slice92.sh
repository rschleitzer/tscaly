#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice92.sh — the slice-92 battery: THE CONTROL FLOW GRAPH, the
# binder's half, and the fifth yardstick that made it a measurable slice.
#
# ★★★ THIS BATTERY MEASURES A DIFFERENT INSTRUMENT FROM EVERY ONE BEFORE IT, and
# that is the slice. Slices 47–91 were graded by `diagcheck` — a SUBSEQUENCE
# relation, which by construction cannot see a diagnostic we fail to emit — so a
# row whose damage is a LOSS came back ungated and had to be read off the DIAGPIN
# instead. The flow graph has almost no diagnostic product under this harness (see
# the note on TS7027 below), and what it has instead is an EQUALITY: the flow
# yardstick compares our graph against the reference's, node for node and edge for
# edge, over every unit of the corpus. An equality catches a loss and an invention
# alike, so nearly every row here is expected RED and a row that is not is a claim
# about something the corpus does not contain.
#
# ★★★ WHY THE DIAGNOSTIC PRODUCT IS SO SMALL, MEASURED RATHER THAN ASSUMED. Three
# checker reports read the binder's reachability bits without touching the flow
# analyzer — TS7027 (unreachable code), TS7028 (unused label) and TS2378 (a get
# accessor must return a value) — and the first two are routed through
# `addErrorOrSuggestion(AllowUnreachableCode == TSFalse, …)`. The oracle builds its
# CompilerOptions with two unrelated fields, so both options are an unset Tristate:
# not TSFalse, so both diagnostics become SUGGESTIONS, and a suggestion is not in
# the list either yardstick compares. Counted off the reference's own dumps over
# stage 1: **0 × TS7027, 0 × TS7028, 2 × TS2378**. So the reachability half of this
# slice is graded by the flow dump's `r` section and by TWO diagnostics, and
# §3.5be's rule is why checkSourceElementUnreachable is NOT ported — its every
# output would be invisible to every instrument in this directory.
#
# ── the four instruments ────────────────────────────────────────────────────
#
#   FLOWPIN    our flow dump against the ORACLE's, over the eleven pin files.
#              The only instrument in this suite that is an equality against the
#              reference on a per-file basis rather than a subsequence.
#   FLOWGATE   the flow yardstick over the WHOLE corpus: matched / failed.
#              A row can be right on eleven files and wrong on 1 453.
#   DIAGPIN    the C section of the eleven pin files — the TS2378 half.
#   STOPGATE   the stop histogram over the whole corpus, which is where a change
#              to the WORK LIST shows up. The flow half moves it because
#              `flow-graph 178` (the accessor) stops firing.
#
# ★★★ ITERATE AT STAGE 1 AND CONFIRM AT STAGE 2 ONCE — slice 64's rule. The
# recorded verdicts are stage 1's.
#
# Usage (nothing may edit the tree while this runs, and no second harness may own
# tests/out — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # stage 1, leaves tests/out
#   packages/tscaly/tests/controls-slice92.sh 2>&1 | tee /tmp/battery92.log
#
set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
BINDER=$PKG/0.1.2/tscaly/binder.scaly
CHECKER=$PKG/0.1.2/tscaly/checker.scaly
FIX=$PKG/tests/fixtures
OUT=$PKG/tests/out

. packages/tscaly/tests/toolchain.sh || exit 2

# ★ ONE MECHANISM PER FILE (slice 72's rule). Eleven files, all written by this
# slice, and each is aimed at one arm of the flow half: the loops, the unreachable
# marker, the switch family, the try/finally reduce label, the conditional graph,
# the mutations, the optional chains, the two calls that join the graph, the get
# accessor (the one diagnostic), the label family and the initializer join.
PINFILES="
$FIX/flow_loops.ts
$FIX/flow_unreachable.ts
$FIX/flow_switch.ts
$FIX/flow_try.ts
$FIX/flow_conditions.ts
$FIX/flow_mutations.ts
$FIX/flow_chains.ts
$FIX/flow_calls.ts
$FIX/flow_get_accessor.ts
$FIX/flow_labels.ts
$FIX/flow_initializers.ts
"
red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$OUT/cases" ]; then
  red "no artifact tree at $OUT/cases — run tests/run.sh first."
  exit 2
fi
if [ ! -x "$OUT/oracle_flow" ]; then
  red "no flow oracle at $OUT/oracle_flow — run tests/run.sh first."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl92)

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
  clang -o "$WORK/tscaly_types" "$WORK/types.o" "$WORK/pkg.o" "$LIBSCALY" -lm >> "$WORK/build.log" 2>&1 || return 1
  "$SCALYC" -c -o "$WORK/flow.o" "$PKG/0.1.2/tscaly_flow.scaly" >> "$WORK/build.log" 2>&1 || return 1
  clang -o "$WORK/tscaly_flow" "$WORK/flow.o" "$WORK/pkg.o" "$LIBSCALY" -lm >> "$WORK/build.log" 2>&1
}

# ★★★ THE FLOWPIN IS THE ONLY EQUALITY IN THIS DIRECTORY, so it is written as a
# DIFF against the oracle and not as a snapshot of our own output. A snapshot
# would say *this row changed something*; the diff says *this row disagrees with
# the reference*, and only the second is a verdict.
flowpin_of() {
  local f
  for f in $PINFILES; do
    if diff -q <("$OUT/oracle_flow" "$f" 2>/dev/null) \
               <("$WORK/tscaly_flow" "$f" 2>/dev/null) > /dev/null 2>&1; then
      printf '%s\tAGREES\n' "$(basename "$f")"
    else
      printf '%s\tDIFFERS %s\n' "$(basename "$f")" \
        "$(diff <("$OUT/oracle_flow" "$f" 2>/dev/null) <("$WORK/tscaly_flow" "$f" 2>/dev/null) | grep -c '^[<>]')"
    fi
  done
}

diags_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$("$WORK/tscaly_types" --diags "$f" 2>/dev/null | tr '\n' '|')"
  done
}

# The whole-corpus flow verdict, read off the units the last run.sh left. Our
# binary is re-run per unit; the reference's answer is the `flow.ref` already on
# disk, which is what makes a row affordable.
flowgate() {   # writes "compared agreeing differing" to stdout
  python3 - "$OUT" "$WORK/tscaly_flow" <<'PY'
import os, subprocess, sys
out, binp = sys.argv[1], sys.argv[2]
cases = os.path.join(out, "cases")
compared = agree = differ = 0
for case in sorted(os.listdir(cases)):
    cdir = os.path.join(cases, case)
    man = os.path.join(cdir, "units.manifest")
    if not os.path.isfile(man):
        continue
    # ★ The manifest is TAB-SEPARATED — `idx\twritten\tunit_name` — and it had to
    # become so: a unit NAME may contain a space, which a whitespace split
    # truncates into a path that does not exist. compare.py's own reader carries
    # the same note and the same measurement.
    for line in open(man, errors="surrogateescape"):
        line = line.rstrip("\n")
        if not line:
            continue
        parts = line.split("\t")
        if len(parts) != 3 or not parts[1]:
            continue
        idx, written, _unit_name = parts
        ref = os.path.join(cdir, idx, "flow.ref")
        if not os.path.isfile(ref):
            continue
        compared += 1
        want = open(ref, "rb").read()
        try:
            got = subprocess.run([binp, written], capture_output=True, timeout=60).stdout
        except Exception:
            got = b"<crash>"
        if got == want:
            agree += 1
        else:
            differ += 1
print(compared, agree, differ)
PY
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
  flowpin_of > "$WORK/base.flowpin"
  diags_of   > "$WORK/base.diags"
  FLOW_BASE=$(flowgate)
  STOP_BASE=$(stopgate)
  # ★ A FLOWPIN that is not all-AGREES on the unpatched tree makes every row below
  # unreadable: a row's RED would then be indistinguishable from the baseline's.
  if grep -q DIFFERS "$WORK/base.flowpin"; then
    red "the FLOWPIN already disagrees on the unpatched tree:"
    sed 's/^/    /' "$WORK/base.flowpin"
    exit 2
  fi
  echo
  echo "  the FLOWPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.flowpin"
  echo
  echo "  BASELINE   diagcheck $DIAG_BASE consistent, $DIAG_LINES speaking, $DIAG_DIAGS diagnostics"
  echo "             flowgate  (compared agreeing differing) = $FLOW_BASE"
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
  local consistent differing speaking diags flow stop
  consistent=$(sed -n 's/^  consistent  *\([0-9]*\)$/\1/p' "$WORK/ctl.diag")
  differing=$(sed -n 's/^  differing  *\([0-9]*\)$/\1/p' "$WORK/ctl.diag")
  speaking=$(sed -n 's/^  units we speak on  *\([0-9]*\).*$/\1/p' "$WORK/ctl.diag")
  diags=$(sed -n 's/^.*(\([0-9]*\) diagnostics.*$/\1/p' "$WORK/ctl.diag")
  flowpin_of > "$WORK/ctl.flowpin"
  diags_of   > "$WORK/ctl.diags"
  flow=$(flowgate)
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
  if cmp -s "$WORK/base.flowpin" "$WORK/ctl.flowpin"; then
    echo "  flowpin   unmoved — all eleven pin files still agree with the oracle."
  else
    green "flowpin   RED"
    diff "$WORK/base.flowpin" "$WORK/ctl.flowpin" | sed 's/^/    /'
    moved=1
  fi
  if [ "$flow" = "$FLOW_BASE" ]; then
    echo "  flowgate  unmoved — $flow"
  else
    green "flowgate  MOVED   $FLOW_BASE -> $flow   (compared agreeing differing)"
    moved=1
  fi
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
  if [ "$stop" = "$STOP_BASE" ]; then
    echo "  stopgate  unmoved — $stop"
  else
    green "stopgate  MOVED   $STOP_BASE -> $stop   (matched units speaking events other)"
    moved=1
  fi
  if [ "$moved" = 0 ]; then
    red "UNGATED ON ALL FOUR AND NOTHING MOVED AT ALL."
    echo "  Decide which of §3.5v's four kinds this is. A row that predicted"
    echo "  this is a measurement; a row that did not is a hole in the battery."
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

P['h01'] = ('''# THE PREMISE — bindContainer's control-flow arm reverted to the bare walk it was
# until this slice, so no function gets a Start node and no graph is built at all.
# PREDICTION: FLOWPIN RED on all eleven, FLOWGATE collapsed, DIAGPIN RED (TS2378
# lost with HasImplicitReturn), STOPGATE moved. The whole chapter.''',
'''old = """        if (container_flags & ContainerFlagsIsControlFlowContainer) <> 0
        {
            let save_current_flow current_flow"""
new = """        if false
        {
            let save_current_flow current_flow"""''')

P['h02'] = ('''# The Start node CARRIES ITS NODE for every container, not only for a function
# expression and an object-literal/class-expression method. PREDICTION: FLOWPIN RED
# — the `N` section prints a Start with a node where the reference prints one
# without. The row that says the asymmetry is a claim and not a convenience.''',
'''old = """                if carries_node
                    set flow_start.node: n"""
new = """                if true
                    set flow_start.node: n"""''')

P['h03'] = ('''# isImmediatelyInvoked forced FALSE — an IIFE gets a Start node of its own instead
# of joining the containing flow. PREDICTION: FLOWPIN RED on flow_calls, which is
# the only pin file with one, and FLOWGATE moved.''',
'''old = """            if AstNode.kind_of(n) = KindClassStaticBlockDeclaration
                set is_immediately_invoked: true"""
new = """            set is_immediately_invoked: false"""''')

P['h04'] = ('''# The ASYNC and GENERATOR exclusions removed — every immediately invoked function
# expression counts, including `(async function(){})()`. PREDICTION: FLOWPIN RED on
# flow_calls, whose async and generator IIFEs are there for this row.''',
'''old = """                if this.has_syntactic_modifier(n, ModifierFlagsAsync) = false
                {
                    if Binder.is_generator_function_expression(n) = false
                    {
                        if AstNode.get_immediately_invoked_function_expression(n) <> null
                            set is_immediately_invoked: true
                    }
                }"""
new = """                if AstNode.get_immediately_invoked_function_expression(n) <> null
                    set is_immediately_invoked: true"""''')

P['h05'] = ('''# The CONSTRUCTOR's return target removed — only an IIFE gets one. PREDICTION:
# FLOWPIN RED on flow_calls, whose derived-class constructor is the input; the
# reference builds a return graph for a constructor so that strict property
# initialization can read it.''',
'''old = """            var wants_return_target is_immediately_invoked
            if AstNode.kind_of(n) = KindConstructor
                set wants_return_target: true"""
new = """            var wants_return_target is_immediately_invoked"""''')

P['h06'] = ('''# The HasImplicitReturn write removed. PREDICTION: FLOWPIN RED (the `r` section
# loses every function-like) and DIAGPIN RED **at a LOSS** — TS2378 stops firing,
# which diagcheck cannot see because a missing line is a subsequence of anything.
# The row that says why this slice needed an EQUALITY instrument.''',
'''old = """                        set n.flags: AstNode.flags_of(n) | NodeFlagsHasImplicitReturn"""
new = """                        set n.flags: AstNode.flags_of(n)"""''')

P['h07'] = ('''# The HasExplicitReturn write removed. PREDICTION: FLOWPIN RED and DIAGPIN RED **by
# INVENTION** — every get accessor with a body now looks like one that never
# returns, so TS2378 fires on `get present()`. h06's complement, and the pair is
# what makes the two bits a claim rather than one flag.''',
'''old = """                        if has_explicit_return
                            set n.flags: AstNode.flags_of(n) | NodeFlagsHasExplicitReturn"""
new = """                        if false
                            set n.flags: AstNode.flags_of(n) | NodeFlagsHasExplicitReturn"""''')

P['h08'] = ('''# bindChildren's UNREACHABLE arm loses its flow-slot clear. PREDICTION: FLOWPIN RED
# on flow_unreachable — an identifier in dead code arrives holding the sentinel,
# because `bind`'s own switch wrote it before this arm ran, and the reference takes
# it back out. The row that says the clear is not dead code.''',
'''old = """            set n.flow_node: null
            if Binder.is_potentially_executable_node(n)"""
new = """            if Binder.is_potentially_executable_node(n)"""''')

P['h09'] = ('''# IsPotentiallyExecutableNode forced TRUE — every node in dead code is marked.
# PREDICTION: FLOWPIN RED on flow_unreachable, whose `var hoisted;` is there
# precisely because a var list with no initializer is NOT executable.''',
'''old = """            if Binder.is_potentially_executable_node(n)
                set n.flags: AstNode.flags_of(n) | NodeFlagsUnreachable"""
new = """            if true
                set n.flags: AstNode.flags_of(n) | NodeFlagsUnreachable"""''')

P['h10'] = ('''# The statement KIND RANGE widened to every kind — every node gets the flow that
# reaches it. PREDICTION: FLOWPIN RED on all eleven and FLOWGATE collapsed. The row
# that prices the range, and it is worth a row because a Block and an
# EmptyStatement sit BELOW KindFirstStatement and still carry a slot.''',
'''old = """        if k0 >= KindFirstStatement
        {
            if k0 <= KindLastStatement
                set n.flow_node: current_flow
        }"""
new = """        set n.flow_node: current_flow"""''')

P['h11'] = ('''# addAntecedent's DEDUP removed. PREDICTION: FLOWPIN RED — a junction reached twice
# by the same flow lists it twice, which the `N` section prints. The row that says
# the linear scan is semantics and not a saving.''',
'''old = """            let l list as ref[FlowList]
            if l.flow = antecedent
                return
            set last: l"""
new = """            let l list as ref[FlowList]
            set last: l"""''')

P['h12'] = ('''# finishFlowLabel's ONE-ANTECEDENT collapse removed — a junction with one incoming
# edge stays a junction. PREDICTION: FLOWPIN RED on all eleven; this is the single
# largest source of node count in the graph.''',
'''old = """        let a flow_label.antecedents as ref[FlowList]
        if a.next = null
            return a.flow
        flow_label"""
new = """        flow_label"""''')

P['h13'] = ('''# createFlowCondition's isNarrowingExpression early-out removed — every condition
# gets a node. PREDICTION: FLOWPIN RED on flow_conditions and flow_loops. The row
# that prices the seven narrowing predicates.''',
'''old = """        if Binder.is_narrowing_expression(e) = false
            return antecedent"""
new = """        if false
            return antecedent"""''')

P['h14'] = ('''# createFlowCondition's LITERAL arm removed — `while (true)` and `if (false)` keep
# a reachable branch. PREDICTION: FLOWPIN RED on flow_conditions and flow_loops,
# and the `r` section changes too: the code after `while (true) { break }` is no
# longer decided the same way.''',
'''old = """        if literal_kills
        {
            if Binder.is_expression_of_optional_chain_root(e) = false
            {
                if Binder.is_nullish_coalesce(AstNode.parent_node_of(e)) = false
                    return unreachable_flow
            }
        }"""
new = """        if false
        {
            if Binder.is_expression_of_optional_chain_root(e) = false
            {
                if Binder.is_nullish_coalesce(AstNode.parent_node_of(e)) = false
                    return unreachable_flow
            }
        }"""''')

P['h15'] = ('''# setFlowNodeReferenced's SHARED branch removed — a node referenced twice never
# gets the second bit. PREDICTION: FLOWPIN RED on every file with a junction; the
# flags column is compared, and Shared is what the checker reads to decide what is
# worth memoising.''',
'''old = """        if (f.flags & FlowFlagsReferenced) = 0
            set f.flags: f.flags | FlowFlagsReferenced
        else
            set f.flags: f.flags | FlowFlagsShared"""
new = """        set f.flags: f.flags | FlowFlagsReferenced"""''')

P['h16'] = ('''# bindLogicalLikeExpression's `&&`/`||` asymmetry INVERTED. PREDICTION: FLOWPIN RED
# on flow_conditions. Three lines, and every narrowing of a guarded expression
# rests on them.''',
'''old = """        if is_and
            this.bind_condition(AstNode.binary_left_of(n), pre_right_label, false_target)
        else
            this.bind_condition(AstNode.binary_left_of(n), true_target, pre_right_label)"""
new = """        if is_and
            this.bind_condition(AstNode.binary_left_of(n), true_target, pre_right_label)
        else
            this.bind_condition(AstNode.binary_left_of(n), pre_right_label, false_target)"""''')

P['h17'] = ('''# The `!` TARGET SWAP removed. PREDICTION: FLOWPIN RED on flow_conditions, whose
# `if (!(a && b))` is there for this row. A negation is not a node in the graph; it
# is an exchange of the labels the operand will be added to.''',
'''old = """            let save_true current_true_target
            set current_true_target: current_false_target
            set current_false_target: save_true
            this.bind_each_child(n)
            set current_false_target: current_true_target
            set current_true_target: save_true
            return"""
new = """            this.bind_each_child(n)
            return"""''')

P['h18'] = ('''# bindCaseBlock's EMPTY-CLAUSE inner loop removed, so a fallthrough group does not
# share one label. PREDICTION: FLOWPIN RED on flow_switch, whose `case 1: case 2:`
# is there for this row.''',
'''old = """            while true
            {
                if AstNode.list_count(AstNode.statements_of(AstNode.child_in_list(clauses, i))) <> 0
                    break
                if (i + 1) >= cnt
                    break
                if Binder.flow_is_unreachable(fallthrough_flow)
                    set current_flow: pre_switch_case_flow
                this.bind(AstNode.child_in_list(clauses, i))
                set i: i + 1
            }"""
new = """            while false
            {
                set i: i + 1
            }"""''')

P['h19'] = ('''# The FallthroughFlowNode write removed. PREDICTION: FLOWPIN RED on flow_switch —
# the `f` line's fourth flow column. It is the one per-node flow slot that is not
# about how a node is REACHED, and no other instrument in this directory has ever
# read it.''',
'''old = """                if i <> (cnt - 1)
                    set clause.fallthrough_flow_node: current_flow"""
new = """                if false
                    set clause.fallthrough_flow_node: current_flow"""''')

P['h20'] = ('''# The NO-DEFAULT extra switch clause removed. PREDICTION: FLOWPIN RED on
# flow_switch, whose `noDefault` is there for this row: without the 0..0 clause a
# switch that matches nothing has no edge past the statement.''',
'''old = """        if has_default = false
            this.add_antecedent(post_switch_label, this.create_flow_switch_clause(pre_switch_case_flow, n, 0, 0))"""
new = """        if false
            this.add_antecedent(post_switch_label, this.create_flow_switch_clause(pre_switch_case_flow, n, 0, 0))"""''')

P['h21'] = ('''# The REDUCE LABEL replaced by the finally label itself at the statement's exit.
# PREDICTION: FLOWPIN RED on flow_try. The reduce label is the whole reason a
# `finally` can be analysed from three directions with three antecedent sets.''',
'''old = """        set current_flow: this.create_reduce_label(finally_label, normal_exit_label.antecedents, current_flow)"""
new = """        set current_flow: finally_label"""''')

P['h22'] = ('''# bindInitializer's JOIN removed — a default initializer's flow is not merged with
# the flow that skipped it. PREDICTION: FLOWPIN RED on flow_initializers, whose
# every default assigns to an outer variable so that the join is visible.''',
'''old = """        let exit_flow this.create_branch_label()
        this.add_antecedent(exit_flow, entry_flow)
        this.add_antecedent(exit_flow, current_flow)
        set current_flow: this.finish_flow_label(exit_flow)"""
new = """        return"""''')

P['h23'] = ('''# The label `referenced` flag forced TRUE, so no label is ever marked unused.
# PREDICTION: FLOWPIN RED on flow_labels — the `r` section loses the mark on
# `unused:`. It is the TS7028 half, and the diagnostic itself is a SUGGESTION under
# this harness, which is why only the flow dump can see it.''',
'''old = """        if al.referenced = false
            set label_name.flags: AstNode.flags_of(label_name) | NodeFlagsUnreachable"""
new = """        if false
            set label_name.flags: AstNode.flags_of(label_name) | NodeFlagsUnreachable"""''')

P['h24'] = ('''# bindFunctionExpression's flow-slot write removed. PREDICTION: FLOWPIN RED on
# flow_calls and flow_initializers. This is the write no reading of `bind`'s switch
# finds — it lives in a DECLARATION arm — and 91 of 1 453 units named it in the
# first line of their diff on the day the yardstick landed.''',
'''old = """        set n.flow_node: current_flow
        var nd null as pointer[char]"""
new = """        var nd null as pointer[char]"""''')

P['h25'] = ('''# The for-in/of bindAssignmentTargetFlow call removed — slice 36 deferred it with
# the reason *"it binds NOTHING"*. PREDICTION: FLOWPIN RED on flow_loops. True of
# the traversal and false of the graph: `for (x of xs)` assigns to x on every
# iteration, and without the mutation a narrowing survives the loop.''',
'''old = """        if AstNode.kind_of(initializer) <> KindVariableDeclarationList
            this.bind_assignment_target_flow(initializer)"""
new = """        if false
            this.bind_assignment_target_flow(initializer)"""''')

P['h26'] = ('''# combineFlowLists replaced by the head list alone, so a finally label sees only
# the NORMAL exit. PREDICTION: FLOWPIN RED on flow_try. The row also witnesses the
# one label in the file whose antecedents may contain DUPLICATES — the three lists
# are combined by direct assignment, not through addAntecedent.''',
'''old = """        set finally_label.antecedents: this.combine_flow_lists(normal_exit_label.antecedents, this.combine_flow_lists(exception_label.antecedents, return_label.antecedents))"""
new = """        set finally_label.antecedents: normal_exit_label.antecedents"""''')

P['h27'] = ('''# maybeBindExpressionFlowIfCall's IsDottedName test forced TRUE — every top-level
# call joins the flow graph. PREDICTION: FLOWPIN RED on flow_calls, whose
# `plain(v)` is the undotted control against `ns.assert(v)`.''',
'''old = """        if Binder.is_dotted_name(callee) = false
            return"""
new = """        if false
            return"""''')

P['h28'] = ('''# The array-mutation tail of bindCallExpressionFlow removed. PREDICTION: FLOWPIN
# RED on flow_mutations, whose `xs.push` and `xs.unshift` are there for this row and
# whose `delete` and element write are the neighbours that must NOT move.''',
'''old = """        if Binder.is_push_or_unshift_identifier(name) = false
            return
        set current_flow: this.create_flow_mutation(FlowFlagsArrayMutation, current_flow, n)"""
new = """        if Binder.is_push_or_unshift_identifier(name) = false
            return"""''')

for k, (pred, body) in P.items():
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

control "h01 THE PREMISE — bindContainer's control-flow arm reverted" $BINDER "$PATCHDIR/h01.py"
control "h02 the Start node carries its node for EVERY container"    $BINDER "$PATCHDIR/h02.py"
control "h03 isImmediatelyInvoked forced FALSE"                      $BINDER "$PATCHDIR/h03.py"
control "h04 the async/generator IIFE exclusions removed"            $BINDER "$PATCHDIR/h04.py"
control "h05 the constructor's return target removed"                $BINDER "$PATCHDIR/h05.py"
control "h06 the HasImplicitReturn write removed"                    $BINDER "$PATCHDIR/h06.py"
control "h07 the HasExplicitReturn write removed"                    $BINDER "$PATCHDIR/h07.py"
control "h08 the unreachable arm's flow-slot clear removed"          $BINDER "$PATCHDIR/h08.py"
control "h09 IsPotentiallyExecutableNode forced TRUE"                $BINDER "$PATCHDIR/h09.py"
control "h10 the statement kind range widened to every kind"         $BINDER "$PATCHDIR/h10.py"
control "h11 addAntecedent's dedup removed"                          $BINDER "$PATCHDIR/h11.py"
control "h12 finishFlowLabel's one-antecedent collapse removed"      $BINDER "$PATCHDIR/h12.py"
control "h13 createFlowCondition's narrowing early-out removed"      $BINDER "$PATCHDIR/h13.py"
control "h14 createFlowCondition's literal arm removed"              $BINDER "$PATCHDIR/h14.py"
control "h15 setFlowNodeReferenced's Shared branch removed"          $BINDER "$PATCHDIR/h15.py"
control "h16 the &&/|| target asymmetry inverted"                    $BINDER "$PATCHDIR/h16.py"
control "h17 the ! target swap removed"                              $BINDER "$PATCHDIR/h17.py"
control "h18 bindCaseBlock's empty-clause loop removed"              $BINDER "$PATCHDIR/h18.py"
control "h19 the FallthroughFlowNode write removed"                  $BINDER "$PATCHDIR/h19.py"
control "h20 the no-default extra switch clause removed"             $BINDER "$PATCHDIR/h20.py"
control "h21 the reduce label replaced by the finally label"         $BINDER "$PATCHDIR/h21.py"
control "h22 bindInitializer's join removed"                         $BINDER "$PATCHDIR/h22.py"
control "h23 the label referenced flag forced TRUE"                  $BINDER "$PATCHDIR/h23.py"
control "h24 bindFunctionExpression's flow-slot write removed"       $BINDER "$PATCHDIR/h24.py"
control "h25 the for-in/of bindAssignmentTargetFlow call removed"    $BINDER "$PATCHDIR/h25.py"
control "h26 combineFlowLists reduced to the head list"              $BINDER "$PATCHDIR/h26.py"
control "h27 maybeBindExpressionFlowIfCall's dotted test forced TRUE" $BINDER "$PATCHDIR/h27.py"
control "h28 the array-mutation tail removed"                        $BINDER "$PATCHDIR/h28.py"

echo
echo "################################################################"
bold "DONE — read every row against its PREDICTION, not against its colour."
