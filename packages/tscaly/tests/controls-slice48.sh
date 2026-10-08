#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice48.sh — the slice-48 battery, in TWO families, and the split is
# the same finding slice 47 made one step further along.
#
# ★★★ THIS SLICE HAS ALMOST NOTHING THE FIVE YARDSTICKS CAN MEASURE, and that is
# a measurement rather than a complaint. run.sh's counters move when a unit
# changes column, and a unit is matched only when its check runs to the END — so
# a slice that ports three arms of a sixty-arm switch changes the TAG in the
# unported column and not the counts: matched stays 9 of 1 042 across everything
# below. §3.5v's fourth kind of ungated row, and the answer to it is an INSTRUMENT
# again:
#
#   c1..c2   patched through ctl.sh, measured by the five yardsticks' counters —
#            the two rows that CAN move a count, because the fixture they act on
#            is the first unit in this dimension whose check completes
#   d1..d6   patched here, measured by tests/diagcheck.sh — our C section as a
#            SUBSEQUENCE of the reference's, over every unit of the corpus
#
# ★★★ AND THE INSTRUMENT IS ONE-DIRECTIONAL, WHICH DECIDES HOW EVERY d-ROW IS
# WRITTEN. diagcheck cannot see a diagnostic we FAIL to report — printing nothing
# is a subsequence of anything — so a control that DISABLES a grammar check is
# ungated there by construction, and would be a row that measures the instrument's
# hole instead of the claim. Every d-row below therefore breaks its claim in the
# direction that INVENTS a line, moves a span, or reorders a pair. The removal
# direction is the yardstick's, and c1/c2 are where it is finally reachable:
# checker_ambient_statements_only.d.ts is made of nothing but the three arms this
# slice ports, so its check completes, its dump is compared, and both directions
# are red there.
#
# ★★ THE d-ROWS DO NOT GO THROUGH ctl.sh, for walkcheck's reason: diagcheck reads
# the reference dumps run.sh produced, and a filtered run would rewrite part of
# that tree. Each d-row builds the package and the dumper into a scratch
# directory, points diagcheck's `BIN` at it, leaves tests/out alone, restores the
# source and PROVES the restore with `cmp`.
#
# Usage (nothing may edit the tree while this runs — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # the artifact tree, first
#   packages/tscaly/tests/controls-slice48.sh 2>&1 | tee /tmp/battery48.log

set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

CTL=packages/tscaly/tests/ctl.sh
DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.1/tscaly/checker.scaly
DIAGS=$PKG/0.1.1/tscaly/Diagnostics.scaly
DECLKINDS=$PKG/0.1.1/tscaly/DeclarationKinds.scaly

. packages/tscaly/tests/toolchain.sh || exit 2

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  echo "The d-rows compare against the reference dumps that run produced."
  exit 2
fi

export TSCALY_BASELINE=$(mktemp -t tscaly-baseline)
WORK=$(mktemp -d -t tscaly-ctl48)
cleanup() { rm -f "$TSCALY_BASELINE" "$TSCALY_BASELINE.fp"; rm -rf "$WORK"; }
trap cleanup EXIT

echo "################################################################"
if ! "$CTL" --establish-baseline </dev/null; then
  exit 2
fi

run() { echo; echo "################################################################"; "$CTL" "$1"; }

# ── the ctl family: the two claims a completed unit makes reachable ──────────

# ★ c1 is the row the whole slice hangs on being able to make at all. Until an
# ARM of checkSourceElementWorker was ported, no unit with a statement could
# complete its check, so nothing about the checker's DIAGNOSTICS could move a
# yardstick counter in either direction. Disabling the ambient check drops the one
# TS1036 of checker_ambient_statements_only.d.ts, which diagcheck is blind to and
# this is not.
run "c1 checkGrammarStatementInAmbientContext is what reports TS1036" <<SPEC
FILE $CHECKER
<<<OLD
        if (AstNode.flags_of(node) & NodeFlagsAmbient) = 0
            return false
        let parent AstNode.parent_node_of(node)
>>>NEW
        if true
            return false
        let parent AstNode.parent_node_of(node)
SPEC

# ★★ c2 is the ONCE-BIT, and it is the half of that function no single-statement
# fixture could reach: four ambient statements, one diagnostic. The patch makes the
# bit unreadable — never set — which is the reference's own noisiness failure and
# the direction that ADDS lines, so it is red in the yardstick AND in diagcheck.
run "c2 the once-bit is what keeps four ambient statements to one TS1036" <<SPEC
FILE $CHECKER
<<<OLD
    procedure mark_reported_ambient(this, n: pointer[AstNode])
        reported_ambient.add(n)
>>>NEW
    procedure mark_reported_ambient(this, n: pointer[AstNode])
    {
    }
SPEC

# ── the diagnostics family: measured by the instrument ───────────────────────

build_diag_bin() {
  "$SCALYC" -c --no-prelude -o "$WORK/pkg.o" "$PKG/0.1.1/tscaly.scaly" > "$WORK/build.log" 2>&1 || return 1
  "$SCALYC" -c -o "$WORK/types.o" "$PKG/0.1.1/tscaly_types.scaly" >> "$WORK/build.log" 2>&1 || return 1
  clang -o "$WORK/tscaly_types" "$WORK/types.o" "$WORK/pkg.o" "$LIBSCALY" -lm >> "$WORK/build.log" 2>&1
}

DIAG_BASE=""
DIAG_LINES=""

diag_baseline() {
  echo
  echo "################################################################"
  bold "DIAGNOSTICS BASELINE"
  if ! build_diag_bin; then
    red "the unpatched tree did not build — every d-row below would be measuring that."
    sed 's/^/    /' "$WORK/build.log"
    exit 2
  fi
  BIN=$WORK/tscaly_types "$DIAGCHECK" > "$WORK/base.diag" 2>&1
  local rc=$?
  DIAG_BASE=$(sed -n 's/^  consistent  *\([0-9]*\)$/\1/p' "$WORK/base.diag")
  DIAG_LINES=$(sed -n 's/^  units we speak on  *\([0-9]*\).*$/\1/p' "$WORK/base.diag")
  sed -n '/^diagcheck/,$p' "$WORK/base.diag" | sed 's/^/  /'
  if [ "$rc" != 0 ]; then
    red "the diagnostics instrument is already red on the unpatched tree — fix that first."
    exit 2
  fi
  echo "  BASELINE   $DIAG_BASE units consistent, $DIAG_LINES of them speaking"
}

diag_control() {   # $1 = label, $2 = file, $3 = python patch file
  echo
  echo "################################################################"
  bold "CONTROL (diagnostics): $1"
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
  cp "$WORK/orig" "$2"
  if ! cmp -s "$WORK/orig" "$2"; then
    red "the source did NOT come back — every number below is suspect."
    return 1
  fi
  echo "  RESTORE VERIFIED   $2 byte-identical"
  echo
  if [ "$rc" != 0 ]; then
    green "RED $differing   (consistent $consistent, was $DIAG_BASE; speaking on $speaking, was $DIAG_LINES)"
  else
    red "UNGATED: every line we print is still a subsequence of the reference's."
    echo "  Speaking on $speaking units, was $DIAG_LINES. Decide which of §3.5v's four"
    echo "  kinds this is — and note that a control which REMOVES a diagnostic is"
    echo "  ungated here by construction (see the header)."
  fi
  return 0
}

diag_baseline

cat > "$WORK/d1.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★ ast.IsDeclarationNode is what admits an element to the declare-modifier walk.
# The patch admits EVERYTHING, which is the direction the instrument can see: an
# ambient file's plain statements then each want a `declare` and TS1046 appears
# where the reference has nothing. The removal direction — admitting nothing — is
# the one diagcheck is blind to, which is why the row is written this way round.
old = """function is_declaration_node_kind(k: int) returns bool
{
"""
new = """function is_declaration_node_kind(k: int) returns bool
{
    if true
        return true
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "d1 IsDeclarationNode is what admits an element to the declare walk" "$DECLKINDS" "$WORK/d1.py"

cat > "$WORK/d2.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# The EXEMPT list of checkGrammarTopLevelElementForRequiredDeclareModifier. Emptying
# it makes an interface, a type alias and an import in a .d.ts each want a `declare`
# — eight kinds that the reference lists precisely because they do not.
old = """    function kind_is_exempt_from_declare_modifier(k: int) returns bool
    {
"""
new = """    function kind_is_exempt_from_declare_modifier(k: int) returns bool
    {
        if true
            return false
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "d2 the eight kinds exempt from the declare modifier" "$CHECKER" "$WORK/d2.py"

cat > "$WORK/d3.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★ ast.HasSyntacticModifier(node, Ambient|Export|Default) — the OTHER half of the
# exemption, and the one that does the work in a real .d.ts, where almost every
# declaration carries `declare` or `export`.
old = """        var exempting: int ModifierFlagsAmbient | ModifierFlagsExport | ModifierFlagsDefault
        if b.has_syntactic_modifier(node, exempting)
            return false
"""
new = """        var exempting: int ModifierFlagsAmbient | ModifierFlagsExport | ModifierFlagsDefault
        if false
            return false
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "d3 the ambient/export/default modifier is the other exemption" "$CHECKER" "$WORK/d3.py"

cat > "$WORK/d4.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ THE SPAN. grammarErrorOnFirstToken reports at GetRangeOfTokenAtPosition, which
# SCANS from the node's pos — so the start is past the leading trivia and the end is
# the first token's end, neither of which is the node's own range. Using the node's
# range instead is the same code at the same place with a different answer, and it
# is exactly the class binder.error_on_node's own note records one phase earlier.
old = """        b.range_of_token_at_position(AstNode.pos_of(n), &start, &stop)
"""
new = """        set start: AstNode.pos_of(n)
        set stop: AstNode.end_of(n)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "d4 the span is the first TOKEN, scanned, not the node's range" "$CHECKER" "$WORK/d4.py"

cat > "$WORK/d5.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ THE PARSE-DIAGNOSTIC SUPPRESSION. A file that failed to parse has a tree the
# grammar checks read as a stream of violations, so the reference suppresses all of
# them. Removing the guard reports on exactly the units the parser yardstick already
# calls broken — and the row says how many of them the corpus holds.
old = """        if this.has_parse_diagnostics()
            return false
"""
new = """        if false
            return false
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "d5 a parse diagnostic suppresses every grammar check in the file" "$CHECKER" "$WORK/d5.py"

cat > "$WORK/d6.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ THE SORT, which slice 47 transcribed and declined to write because nothing
# produced a diagnostic to sort. Reversing the comparison emits in the opposite
# order, and the subsequence relation is what sees it: our lines are sorted among
# themselves and the reference's are sorted globally, so a wrongly ordered PAIR
# cannot be embedded. ★ A subset test would pass this — which is the whole reason
# diagcheck compares as a subsequence.
old = """        if a.pos <> b.pos
            return a.pos < b.pos
        if a.end <> b.end
            return a.end < b.end
        a.code < b.code
"""
new = """        if a.pos <> b.pos
            return a.pos > b.pos
        if a.end <> b.end
            return a.end > b.end
        a.code > b.code
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "d6 the diagnostic list is sorted the way CompareDiagnostics sorts" "$DIAGS" "$WORK/d6.py"

echo
echo "################################################################"
bold "BATTERY 48 COMPLETE"
