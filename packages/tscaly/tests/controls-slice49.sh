#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice49.sh — the slice-49 battery, and EVERY row goes through the
# instrument rather than through the yardsticks.
#
# ★★★ THAT IS THE SLICE'S MEASUREMENT AND NOT A GAP IN THE BATTERY. run.sh's
# counters move when a unit changes COLUMN, and a unit is matched only when its
# check runs to the END — so a slice that ports the first grammar check of five
# arms and stops where the reference goes on moves the TAG in the unported column
# and nothing else. Slice 48 had two rows the counters could see because two of
# its arms were COMPLETE (checkGrammarStatementInAmbientContext is the whole body
# of the EmptyStatement and DebuggerStatement arms); checkGrammarModifiers is the
# whole body of no arm at all. So checker matched stays 10 across everything
# below, and tests/diagcheck.sh is what measures the slice.
#
# ★★★ THE INSTRUMENT IS ONE-DIRECTIONAL, WHICH DECIDES HOW EVERY ROW IS WRITTEN.
# diagcheck compares our C section as a SUBSEQUENCE of the reference's, so it
# cannot see a diagnostic we FAIL to report — printing nothing is a subsequence of
# anything. Seven of the nine rows below therefore break their claim in the
# direction that INVENTS a line, moves a span or changes a code. The remaining two
# (e8, e9) are coverage claims: they can only be broken by making the port measure
# LESS, which diagcheck cannot fail on — so they are UNGATED BY CONSTRUCTION and
# are read off the *units we speak on* counter instead, which is the number that
# line exists for.
#
# ★★ THE ROWS DO NOT GO THROUGH ctl.sh, for slice 48's reason: diagcheck reads the
# reference dumps run.sh produced, and a filtered run would rewrite part of that
# tree. Each row builds the package and the dumper into a scratch directory,
# points diagcheck's BIN at it, leaves tests/out alone, restores the source and
# PROVES the restore with `cmp`.
#
# Usage (nothing may edit the tree while this runs — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # the artifact tree, first
#   packages/tscaly/tests/controls-slice49.sh 2>&1 | tee /tmp/battery49.log

set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.2/tscaly/checker.scaly

. packages/tscaly/tests/toolchain.sh || exit 2

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  echo "Every row compares against the reference dumps that run produced."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl49)
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

build_diag_bin() {
  "$SCALYC" -c --no-prelude -o "$WORK/pkg.o" "$PKG/0.1.2/tscaly.scaly" > "$WORK/build.log" 2>&1 || return 1
  "$SCALYC" -c -o "$WORK/types.o" "$PKG/0.1.2/tscaly_types.scaly" >> "$WORK/build.log" 2>&1 || return 1
  clang -o "$WORK/tscaly_types" "$WORK/types.o" "$WORK/pkg.o" "$LIBSCALY" -lm >> "$WORK/build.log" 2>&1
}

DIAG_BASE=""
DIAG_LINES=""
# ★★ THE DIAGNOSTIC COUNT, not only the unit count. e8 and e9 shrink the port's
# coverage WITHIN a unit — the first statement still reports, so the unit still
# speaks and only the number of LINES falls. Reading the units counter alone made
# e8 look like it changed nothing, which is the instrument-too-coarse trap one
# level down from the one diagcheck itself exists to avoid.
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
    echo "  Decide which of §3.5v's four"
    echo "  kinds this is — and note that a control which REMOVES a diagnostic, or"
    echo "  narrows the port's COVERAGE, is ungated here by construction (header)."
  fi
  return 0
}

diag_baseline

# ── e1: the SPAN of a modifier report ────────────────────────────────────────

cat > "$WORK/e1.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ grammarErrorOnNode reports through GetErrorRangeForNode, which SKIPS LEADING
# TRIVIA before the node's own pos — a node's pos is its FULL start, whitespace
# included. `declare export var a` reports the `export` at 8, not at 7. This is
# the class §3.5's binder note records one phase earlier, where leaving the skip
# out was worth 31 units of stage 2 in four apparent signatures and one cause.
old = """        if b.error_range_for_node(n, &start, &stop) = false
        {
            this.record_unported("grammar-error-range", AstNode.kind_of(n))
            return false
        }
"""
new = """        if false
        {
            this.record_unported("grammar-error-range", AstNode.kind_of(n))
            return false
        }
        set start: AstNode.pos_of(n)
        set stop: AstNode.end_of(n)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "e1 a modifier report's span skips the leading trivia" "$CHECKER" "$WORK/e1.py"

# ── e2: the DECORATOR report's span ──────────────────────────────────────────

cat > "$WORK/e2.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★ reportObviousDecoratorErrors reports at the decorator's FIRST TOKEN — the `@`
# alone — while grammarErrorOnNode would report at the whole decorator. The two
# functions sit next to each other and answer different questions, which is why
# the reference has both; swapping them is a one-word edit with a visible answer.
old = """        this.grammar_error_on_first_token(decorator, DiagDecorators_are_not_valid_here)
"""
new = """        this.grammar_error_on_node(decorator, DiagDecorators_are_not_valid_here)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "e2 an illegal decorator is reported at its FIRST TOKEN" "$CHECKER" "$WORK/e2.py"

# ── e3: the top-level exemption of findFirstIllegalModifier ──────────────────

cat > "$WORK/e3.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ THE DEFAULT GROUP'S FIRST QUESTION IS THE PARENT'S. A declaration at the top
# level of a file or of a namespace body may carry modifiers; the per-kind tests
# below it are for a declaration somewhere else. Remove the exemption and every
# `export var`, `declare interface` and `export enum` in the corpus reports
# TS1184 *Modifiers cannot appear here* — which is the loudest invention this
# function can make.
old = """        if Checker.kind_or_unknown(parent) = KindModuleBlock
            return null
        if Checker.kind_or_unknown(parent) = KindSourceFile
            return null
"""
new = """        if false
            return null
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "e3 a top-level declaration is exempt from findFirstIllegalModifier" "$CHECKER" "$WORK/e3.py"

# ── e4: which GROUP a variable statement is judged by ────────────────────────

cat > "$WORK/e4.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★ findFirstIllegalModifier has three groups and the reference's switch decides
# which one a kind belongs to. Moving VariableStatement into the second — the
# kinds that may carry NO modifier at all — makes every `export var` and `declare
# var` in the corpus report TS1184. It is a different mechanism from e3 with the
# same message, which is why both rows exist: the exemption and the grouping are
# two independent ways to get this wrong.
old = """    function kind_admits_no_modifier(k: int) returns bool
    {
"""
new = """    function kind_admits_no_modifier(k: int) returns bool
    {
        if k = KindVariableStatement
            return true
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "e4 a variable statement is judged by the DEFAULT group" "$CHECKER" "$WORK/e4.py"

# ── e5: the flags accumulate ACROSS the modifier list ────────────────────────

cat > "$WORK/e5.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ `flags` is the whole state of the loop: each arm ORs its bit in and the
# LATER arms test it. Inverting the `already seen` test for `declare` makes the
# FIRST `declare` report TS1030 — so every ambient declaration in the corpus
# invents a line, and the row proves the flag is read rather than merely written.
old = """                if mk = KindDeclareKeyword
                {
                    if (flags & ModifierFlagsAmbient) <> 0
                        return this.grammar_error_on_node(modifier, DiagX_0_modifier_already_seen)
"""
new = """                if mk = KindDeclareKeyword
                {
                    if (flags & ModifierFlagsAmbient) = 0
                        return this.grammar_error_on_node(modifier, DiagX_0_modifier_already_seen)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "e5 the modifier flags accumulate across the list and are read back" "$CHECKER" "$WORK/e5.py"

# ── e6: the `async` arm reads the PARENT's ambient flag ──────────────────────

cat > "$WORK/e6.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ TWO SOURCES OF `ambient` IN ONE TEST, and only one of them is the modifier
# list: `flags&Ambient` is a `declare` earlier in the SAME list, while
# `node.Parent.Flags&Ambient` is the whole FILE being a .d.ts. Dropping the second
# makes `async var a` in a declaration file fall through to the tail and report
# TS1042 where the reference reports TS1040 — the same position, a different code,
# which is exactly what a subsequence test is for.
old = """                    if (Checker.flags_or_none(parent) & NodeFlagsAmbient) <> 0
                        set ambient: true
                    if ambient
                        return this.grammar_error_on_node(modifier, DiagX_0_modifier_cannot_be_used_in_an_ambient_context)
"""
new = """                    if ambient
                        return this.grammar_error_on_node(modifier, DiagX_0_modifier_cannot_be_used_in_an_ambient_context)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "e6 the async arm reads the PARENT's ambient flag, not only the list's" "$CHECKER" "$WORK/e6.py"

# ── e7: the reparsed guard on the must-precede family ────────────────────────

cat > "$WORK/e7.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ A MODIFIER THE JSDOC REPARSER SYNTHESIZED HAS NO SOURCE ORDER, so every
# *must precede* test in this function is guarded on NodeFlagsReparsed being
# clear. Eleven arms ask it. THIS ROW IS UNGATED AND THE REASON IS AN ENUMERATION
# RATHER THAN A CORPUS GAP: reparser.go's modifier-tag arm (@readonly, @private,
# @public, @protected, @override) attaches its synthesized modifier to exactly
# five parents — MethodDeclaration, GetAccessor, SetAccessor, PropertyDeclaration,
# Constructor and BinaryExpression — and NONE of the five kinds this slice's arms
# reach is among them. So no reparsed modifier can arrive at checkGrammarModifiers
# from here, in any corpus, and the guard goes live with the class and function
# arms. The row is kept because that is the moment it stops being ungated.
old = """                let reparsed (AstNode.flags_of(modifier) & NodeFlagsReparsed) <> 0
"""
new = """                let reparsed false
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "e7 a REPARSED modifier is exempt from the must-precede tests" "$CHECKER" "$WORK/e7.py"

# ── e8, e9: the two coverage claims, ungated by construction ─────────────────
#
# ★★★ BOTH OF THESE MAKE THE PORT MEASURE LESS, and diagcheck cannot fail on
# that — fewer lines are still a subsequence. They are here because the *units we
# speak on* counter is the instrument for exactly this, and because each names a
# mechanism that would otherwise shrink the slice's coverage in silence: the
# failure mode is not a wrong answer, it is a battery that looks the same while
# measuring a fraction of what it claims.

cat > "$WORK/e8.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# The guard asks whether THIS call reported, not whether the checker ever has.
# The blanket form is the obvious spelling and it is wrong the moment the
# statement loop stops bailing out: every statement after the first arrives with
# the flag set.
old = """        let unported_before this.is_unported()
"""
new = """        let unported_before false
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "e8 the unported guard is per-CALL, not per-checker" "$CHECKER" "$WORK/e8.py"

cat > "$WORK/e9.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# Slice 47's stop-at-the-first-report, restored. Its stated reason — nothing to
# gain from checking a file whose dump is suppressed — expired when slice 48 built
# the instrument that reads suppressed files.
old = """            this.check_source_element(AstNode.child_in_list(nodes, i))
            set i: i + 1
"""
new = """            if this.is_unported()
                return
            this.check_source_element(AstNode.child_in_list(nodes, i))
            set i: i + 1
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "e9 the statement loop no longer stops at the first unported arm" "$CHECKER" "$WORK/e9.py"

echo
echo "################################################################"
bold "BATTERY 49 COMPLETE"
