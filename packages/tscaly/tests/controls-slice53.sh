#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice53.sh — the slice-53 battery. Every row goes through
# tests/diagcheck.sh, for slices 49-52's reason: no yardstick counter can move,
# because a VariableDeclaration has no ported check arm, so not one variable
# statement can be claimed. Checker matched is 10 / 109 before and after
# everything below.
#
# ★★★ ITS SUBJECT IS A FUNCTION WHOSE REPORTS ARE MOSTLY OUT OF REACH, and that
# is what shapes the battery. checkGrammarVariableDeclarationList has five terms
# and checkGrammarForDisallowedBlockScopedVariableStatement one (its four keyword
# arms collapse to one code); of those NINE reports, THREE are reachable from this
# slice's only caller (the trailing comma and the two ambient ones) and six are not
# — the empty list and the for-in pair need checkForStatement /
# checkGrammarForInOrForOfStatement, the case/default pair needs the switch arms,
# and every TS1156 needs a variable statement whose PARENT is a loop, a branch or a
# label, which means the parent's own arm. So eight rows break a reachable claim
# and three are UNGATED BY CONSTRUCTION.
#
# ★★★ AND THE TWO ROWS ABOUT THE UNREACHABLE HALF REFUTED THEIR OWN FIRST DRAFT,
# WHICH IS THE MOST USEFUL THING IN THIS BATTERY. f9 and f10 were written as a
# matched pair of UNGATED measurements — *the reachable population of TS1156 is
# empty, here it is from both ends* — and f10 came back RED 345. The distinction the
# draft missed: checkGrammarForDisallowedBlockScopedVariableStatement RUNS on every
# variable statement in the corpus; what no corpus reaches is its REPORT, because
# `containerAllowsBlockScopedVariable` answers TRUE for the only three parents in
# reach. An arm that is never EXECUTED and an arm that is executed and always
# answers nothing look identical in the histogram and are not the same thing, and
# only a control can tell them apart.
#
# ★★★ THE INSTRUMENT IS ONE-DIRECTIONAL, WHICH DECIDES HOW EVERY ROW IS WRITTEN.
# diagcheck compares our C section as a SUBSEQUENCE of the reference's, so it
# cannot see a diagnostic we FAIL to report. The eight gated rows therefore break
# their claim in the direction that INVENTS a line, moves a span or changes a
# code — which is why five of the six that aim at the using fork point an
# unreachable guard at the one shape that IS reachable (`using c = null;` at file
# scope) instead of at the shape the guard is about.
#
# ★★ TWO MECHANISMS OF THIS SLICE HAVE NO ROW AT ALL, and saying so is cheaper than
# a row that proves nothing. The parser's new list-range row for
# `createMissingList` has no reader until the for-statement arm lands — it was added
# by reading the reference, not by a failing unit, and no instrument in this package
# can see it. And `containerAllowsBlockScopedVariable`'s LabeledStatement RECURSION
# cannot be reddened by any patch of f11's shape: to make it invent a line it would
# have to walk UP to a refusing kind, and there is none within reach.
# `checker_variable_block_scoped_deferred.ts` is the DEFERRED witness for both, and
# its comment names what turns each live.
#
# ★★ THE ROWS DO NOT GO THROUGH ctl.sh, for slice 48's reason: diagcheck reads the
# reference dumps run.sh produced, and a filtered run would rewrite part of that
# tree. Each row builds the package and the dumper into a scratch directory, points
# diagcheck's BIN at it, leaves tests/out alone, restores the source and PROVES the
# restore with `cmp`.
#
# Usage (nothing may edit the tree while this runs — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # the artifact tree, first
#   packages/tscaly/tests/controls-slice53.sh 2>&1 | tee /tmp/battery53.log

set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.0/tscaly/checker.scaly
BINDER=$PKG/0.1.0/tscaly/binder.scaly

. packages/tscaly/tests/toolchain.sh || exit 2

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  echo "Every row compares against the reference dumps that run produced."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl53)
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

build_diag_bin() {
  "$SCALYC" -c --no-prelude -o "$WORK/pkg.o" "$PKG/0.1.0/tscaly.scaly" > "$WORK/build.log" 2>&1 || return 1
  "$SCALYC" -c -o "$WORK/types.o" "$PKG/0.1.0/tscaly_types.scaly" >> "$WORK/build.log" 2>&1 || return 1
  clang -o "$WORK/tscaly_types" "$WORK/types.o" "$WORK/pkg.o" "$LIBSCALY" -lm >> "$WORK/build.log" 2>&1
}

DIAG_BASE=""
DIAG_LINES=""
DIAG_DIAGS=""

diag_baseline() {
  echo "################################################################"
  bold "DIAGNOSTICS BASELINE"
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
  echo "  BASELINE   $DIAG_BASE units consistent, $DIAG_LINES speaking, $DIAG_DIAGS diagnostics"
}

diag_control() {   # $1 = label, $2 = file, $3 = python patch file
  echo
  echo "################################################################"
  bold "CONTROL: $1"
  cp "$2" "$WORK/orig"
  if ! python3 "$3" "$2"; then
    red "the patch did not apply — the anchor moved. The row measures nothing."
    cp "$WORK/orig" "$2"
    return 1
  fi
  echo "  patched $2"
  if ! build_diag_bin; then
    red "the patched tree did not build — the row measures nothing:"
    tail -5 "$WORK/build.log" | sed 's/^/    /'
    cp "$WORK/orig" "$2"
    return 1
  fi
  BIN=$WORK/tscaly_types "$DIAGCHECK" > "$WORK/ctl.diag" 2>&1
  local rc=$?
  local consistent differing speaking
  consistent=$(sed -n 's/^  consistent  *\([0-9]*\)$/\1/p' "$WORK/ctl.diag")
  differing=$(sed -n 's/^  differing  *\([0-9]*\)$/\1/p' "$WORK/ctl.diag")
  speaking=$(sed -n 's/^  units we speak on  *\([0-9]*\).*$/\1/p' "$WORK/ctl.diag")
  local diags
  diags=$(sed -n 's/^.*(\([0-9]*\) diagnostics.*$/\1/p' "$WORK/ctl.diag")
  cp "$WORK/orig" "$2"
  if ! cmp -s "$WORK/orig" "$2"; then
    red "the source did NOT come back — every number below is suspect."
    return 1
  fi
  echo "  RESTORE VERIFIED   $2 byte-identical"
  echo
  if [ "$rc" != 0 ]; then
    green "RED $differing   (consistent $consistent, was $DIAG_BASE; speaking on $speaking/$diags, was $DIAG_LINES/$DIAG_DIAGS)"
  else
    red "UNGATED: every line we print is still a subsequence of the reference's."
    echo "  Speaking on $speaking units with $diags diagnostics, was $DIAG_LINES/$DIAG_DIAGS."
    echo "  Decide which of §3.5v's four kinds this is — and note that a control"
    echo "  which REMOVES a diagnostic, or narrows the port's COVERAGE, is ungated"
    echo "  here by construction (header)."
  fi
  return 0
}


diag_baseline

# ── f1: the for-in guard is a test on the PARENT'S KIND ──────────────────────

cat > "$WORK/f1.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ `ast.IsForInStatement(declarationList.Parent)`. Aimed at the one parent kind
# this slice can actually reach — a VariableStatement — the guard invents TS1493 on
# every `using` declaration at statement position, which is what
# checker_variable_using_plain.ts is the smallest case of. MEASURED: 5 units,
# speaking 49 -> 53. The row is written this way round on purpose: the shape the
# guard is ABOUT (`for (using x in y)`) is behind the for-in arm, so a row that fixed
# the guard's own shape could not be red.
old = """            if Checker.kind_or_unknown(parent) = KindForInStatement
"""
new = """            if Checker.kind_or_unknown(parent) = KindVariableStatement
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f1 the for-in guard tests the parent's KIND" "$CHECKER" "$WORK/f1.py"

# ── f2: the ambient guard is a FLAG on the declaration list ──────────────────

cat > "$WORK/f2.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ Drop the flag test and every `using` declaration reports TS1545, ambient or
# not. This is the guard that makes checker_variable_using_ambient.ts and
# checker_variable_using_plain.ts two different units rather than one, and the row
# is what says the pair is not decoration.
old = """            if (AstNode.flags_of(declaration_list) & NodeFlagsAmbient) <> 0
            {
                if is_using
"""
new = """            if true
            {
                if is_using
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f2 the ambient using report needs the ambient FLAG" "$CHECKER" "$WORK/f2.py"

# ── f3: the case/default guard is on the GRANDPARENT ─────────────────────────

cat > "$WORK/f3.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ `IsVariableStatement(parent) && (IsCaseClause(parent.Parent) ||
# IsDefaultClause(parent.Parent))` — two hops, and the second is the one that
# matters. Force the clause test true and TS1547 lands on every `using` declaration
# in a block; the shape it is about needs the switch arms, so again the row is
# aimed at the reachable side.
old = """                if in_clause
                {
                    if is_using
"""
new = """                if true
                {
                    if is_using
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f3 the case/default report needs a clause GRANDPARENT" "$CHECKER" "$WORK/f3.py"

# ── f4: `using` and `await using` are two codes, not one ─────────────────────

cat > "$WORK/f4.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ THE ROW FOR THE MASK. NodeFlagsAwaitUsing is Const|Using and NodeFlagsUsing is
# Using alone, so the two are told apart by a masked EQUALITY and not by a bit test —
# and every one of the six reports in this fork exists in two versions for exactly
# that reason. Swapping the ambient pair keeps both spans and both counts and moves
# the CODES, which is what checker_variable_using_ambient.ts's two lines catch.
old = """                if is_using
                    return this.grammar_error_on_node(declaration_list, DiagX_using_declarations_are_not_allowed_in_ambient_contexts)
                return this.grammar_error_on_node(declaration_list, DiagX_await_using_declarations_are_not_allowed_in_ambient_contexts)
"""
new = """                if is_using
                    return this.grammar_error_on_node(declaration_list, DiagX_await_using_declarations_are_not_allowed_in_ambient_contexts)
                return this.grammar_error_on_node(declaration_list, DiagX_using_declarations_are_not_allowed_in_ambient_contexts)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f4 the ambient fork answers two different codes" "$CHECKER" "$WORK/f4.py"

# ── f5: the fork is entered by a MASKED EQUALITY, not by a bit test ──────────

cat > "$WORK/f5.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ `blockScopeFlags == NodeFlagsUsing`. Read as a bit test — the most plausible
# wrong port there is, since the value is already masked — every `let` and `const`
# enters the fork, and in an ambient context that is TS1545 on each of them. The
# loudest row here, and it reaches the corpus rather than a fixture: declaration
# files are full of `declare const`.
old = """        if block_scope_flags = NodeFlagsUsing
            set is_using: true
"""
new = """        if block_scope_flags <> 0
            set is_using: true
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f5 the using fork is entered by a masked EQUALITY" "$CHECKER" "$WORK/f5.py"

# ── f6: the six reports are on the LIST, not on the statement ────────────────

cat > "$WORK/f6.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ `grammarErrorOnNode(declarationList.AsNode(), …)` — the declaration list, whose
# error range starts at `using` and ends at the last declaration, not the statement,
# whose range runs to the semicolon. Same code, same count, every span moved, which
# is the failure mode a subsequence test is sharpest on.
old = """                    return this.grammar_error_on_node(declaration_list, DiagX_using_declarations_are_not_allowed_in_ambient_contexts)
"""
new = """                    return this.grammar_error_on_node(AstNode.parent_node_of(declaration_list), DiagX_using_declarations_are_not_allowed_in_ambient_contexts)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f6 the using reports are on the declaration LIST" "$CHECKER" "$WORK/f6.py"

# ── f7: the arm runs the chain to its end ────────────────────────────────────

cat > "$WORK/f7.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ UNGATED BY CONSTRUCTION, and it is the row for the SLICE ITSELF: put slice
# 52's two-report body back and the whole chain past checkGrammarModifiers is gone,
# so this port says nothing about any variable statement — which a subsequence test
# accepts. The gate is the counters. ★★★MEASURED: 49/93 falls back to **47/90**,
# which is slice 52's baseline to the digit, so the three diagnostics this slice
# adds on stage 1 are exactly the three its fixtures carry.
old = """        let list AstNode.variable_statement_list_of(node)
        if this.check_grammar_modifiers(node) = false
        {
            if this.check_grammar_variable_declaration_list(list) = false
                this.check_grammar_for_disallowed_block_scoped_variable_statement(node)
        }
        this.check_variable_declaration_list(list)
"""
new = """        if this.check_grammar_modifiers(node)
        {
            this.record_unported("check-variable-declaration-list", KindVariableStatement)
            return
        }
        this.record_unported("check-grammar-variable-declaration-list", KindVariableStatement)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f7 the variable statement arm runs to its end" "$CHECKER" "$WORK/f7.py"

# ── f8: the declarations are walked as source elements ───────────────────────

cat > "$WORK/f8.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ UNGATED BY CONSTRUCTION, and it is the row for what this slice BOUGHT rather
# than for what it checks. checkVariableDeclarationList's last line is the step that
# moves 285 stage-1 units off two VariableStatement tags and onto `check
# VariableDeclaration`; removing it changes no diagnostic at all — a declaration has
# no ported arm — and the whole difference is which kind the work list names. Read it
# off tests/triage.py: `check 261` disappears and the two old tags come back.
# MEASURED: 49/93 unchanged, which is the claim.
old = """        this.check_source_elements(AstNode.variable_declarations_of(node))
"""
new = """"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f8 the declarations are walked as source elements" "$CHECKER" "$WORK/f8.py"

# ── f9: the await-using deferral answers TRUE ───────────────────────────────

cat > "$WORK/f9.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ UNGATED, AND THAT IS THE MEASUREMENT. The deferred term answers true so that
# checkGrammarForDisallowedBlockScopedVariableStatement does not run behind a check
# we did not make; flipping it to false runs that check on every `await using`
# statement and NOTHING changes, because its container is a Block, a ModuleBlock or a
# SourceFile in every unit that can reach it, and all three allow a block-scoped
# variable. So the conservative answer costs nothing TODAY — and the row is here to
# be re-run on the day the statement arms land, when it should turn red.
old = """            this.record_unported("check-grammar-await-or-await-using", KindVariableDeclarationList)
            return true
"""
new = """            this.record_unported("check-grammar-await-or-await-using", KindVariableDeclarationList)
            return false
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f9 the deferred await-using term answers true" "$CHECKER" "$WORK/f9.py"

# ── f10: the container test is what suppresses TS1156, and it is LOAD-BEARING ─

cat > "$WORK/f10.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ THE ROW THAT REFUTED ITS OWN FIRST DRAFT, AND IT IS THE LOUDEST HERE.
# It was written as the ungated twin of f9 — *make every container refuse and
# nothing changes, because TS1156 is out of reach* — and it came back RED 345,
# speaking on 390 units with 917 diagnostics. The reason is the distinction the
# first draft missed: checkGrammarForDisallowedBlockScopedVariableStatement RUNS on
# every variable statement in the corpus, and what no corpus reaches is its REPORT,
# which this one line suppresses. So the function is not transcribed code nobody
# executes — it is executed everywhere and answers "nothing to say" everywhere, and
# this row is the proof of both halves at once.
old = """    function container_allows_block_scoped_variable(this, parent: pointer[AstNode]) returns bool
    {
        var p parent
"""
new = """    function container_allows_block_scoped_variable(this, parent: pointer[AstNode]) returns bool
    {
        if true
            return false
        var p parent
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f10 the container test is what suppresses TS1156" "$CHECKER" "$WORK/f10.py"

# ── f11: the seven kinds are a test on the KIND, not a constant ──────────────

cat > "$WORK/f11.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ f10 proves the FUNCTION runs; this proves the LIST is read. Point one of the
# seven refusing kinds at a container the corpus actually has and every top-level
# `let` and `const` reports TS1156 — which is the sharpest statement available about
# an arm list whose seven real members are all out of reach. ★What stays UNPROVEN
# after this row is the LabeledStatement RECURSION: to make it invent a line it
# would have to walk UP to a refusing kind, and there is none within reach, so no
# patch of this shape can redden it. `checker_variable_block_scoped_deferred.ts`
# is its deferred witness and says so.
old = """            if k = KindIfStatement
                return false
"""
new = """            if k = KindSourceFile
                return false
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f11 the refusing containers are a list of KINDS" "$CHECKER" "$WORK/f11.py"

echo
echo "################################################################"
bold "BATTERY 53 COMPLETE"
echo "Eleven rows. Eight must be RED. Three are UNGATED and each says why: f7 and"
echo "f8 are COVERAGE rows read off diagcheck's two counters and tests/triage.py's"
echo "histogram, and f9 says that the deferred term's conservative TRUE costs"
echo "nothing today — it is the row to re-run when the statement arms land."
echo "See the header for f10, which was drafted as f9's ungated twin and came back"
echo "RED, and for the two mechanisms of this slice that have no row at all."
