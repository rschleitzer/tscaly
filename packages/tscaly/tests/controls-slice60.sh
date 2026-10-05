#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice60.sh — the slice-60 battery: checkTypeParameters and
# checkTypeParameter, the head four ported arms have been stopping at since
# slice 52.
#
# ★★★ TWO INSTRUMENTS, AND THE SPLIT IS THE SLICE'S OWN SHAPE. Ten of the eighteen
# rows break a live report — four codes fire here (TS2706, TS2300, TS2368, TS1110)
# and every one of them is reachable without a type — so diagcheck gates them. The
# other five aim at the three things this slice ports that produce NO diagnostic:
# the two checkSourceElement recursions, and the two reports that stand BEHIND
# check_type_parameter's unconditional stop (checkTypeParametersNotReferenced's and
# the deferred arm's). Those are tags, and no yardstick compares a tag.
#
# ★★★ FIVE ROWS ARE PROBES RATHER THAN BREAKS, AND TWO DRAFTS OF THIS BATTERY ARE
# WHY. Two of the things this slice ports leave a report that CANNOT BE FIRST — the
# deferred arm's and checkTypeParametersNotReferenced's — so no pin over tags can
# reach either, and the instrument has to INSERT a diagnostic where the report
# stands. Getting there took two refutations, and both are worth more than the rows
# they replaced:
#
#   (1) The first g14/g15 assumed removing check_type_parameter's STOP would expose
#       the deferred report. g13 refutes it — the drain runs after every declaration
#       and all three container kinds the deferred guard admits report from their own
#       arms, so the interface fixture's tag under g13 is
#       checkExportsOnMergedDeclarations. ★The reason was already written down in
#       this file, about a DIFFERENT drain (check_unused_renamed_binding_elements:
#       *a deferred element does not remove a report from the unit — it hands the
#       unit to its container's*).
#   (2) The second draft probed the deferred arm with a diagnostic and STILL moved
#       nothing, which is a stronger statement than (1): check_source_file returns
#       as soon as any statement has reported and the drain sits BELOW that return,
#       so for a type parameter the drain does not merely report late — it never
#       runs. g14 lifts that early return as its PREMISE and says so; lifting it for
#       real is a slice of its own.
#
# ★ g16's predicted verdict is *back to the baseline*, and it is a measurement only
# because it is paired with g14.
#
# ★★ ROWS THAT ONLY REMOVE A DIAGNOSTIC ARE UNGATED ON diagcheck BY CONSTRUCTION
# (its relation is a SUBSEQUENCE — its own header says so), and are measurements
# when the falling count is printed: g01, g06 and g10 are exactly that, and each of
# the three is a DIFFERENT claim about the same loop.
#
# ★ The `control` helper takes an optional fourth argument, the tag file to diff
# against. Nothing uses it any more — the rows that needed it are the two the
# refutation above removed — and it is kept because the next slice that stacks two
# patches will want it.
#
# ★ ONE FILE IS PATCHED, checker.scaly. Every patch is dry-run against a copy of
# the tree before the first build is spent (slice 57's lesson), and the restore is
# proven with `cmp` and survives a kill (slice 58's).
#
# Usage (nothing may edit the tree while this runs — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # the artifact tree, first
#   packages/tscaly/tests/controls-slice60.sh 2>&1 | tee /tmp/battery60.log

set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.0/tscaly/checker.scaly
FIX=$PKG/tests/fixtures

. packages/tscaly/tests/toolchain.sh || exit 2

# The fixtures the PIN reads — all nine of this slice's, because the tag is the
# only thing five of the rows can move and three of the files produce no
# diagnostic at all. One shape per file (slice 56's *a fixture that cannot be
# first is not a witness*): record_unported keeps the FIRST report, so a second
# generic declaration in the same file would hide whatever the first one does.
TAGFILES="
$FIX/checker_type_parameter_constraint_keyword.ts
$FIX/checker_type_parameter_constraint_reference.ts
$FIX/checker_type_parameter_default_reference.ts
$FIX/checker_type_parameter_deferred_variance.ts
$FIX/checker_type_parameter_required_after_optional.ts
$FIX/checker_type_parameter_duplicate.ts
$FIX/checker_type_parameter_spans.ts
$FIX/checker_type_parameter_reserved_name.ts
$FIX/checker_type_parameter_expression_constraint.ts
"

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  echo "Both instruments compare against the reference dumps that run produced."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl60)

PATCHED_FILE=""
PATCHED_ORIG=""
cleanup() {
  if [ -n "$PATCHED_FILE" ] && [ -f "$PATCHED_ORIG" ]; then
    cp "$PATCHED_ORIG" "$PATCHED_FILE"
    red "INTERRUPTED — $PATCHED_FILE restored from the row that was running."
  fi
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

control() {   # $1 = label, $2 = file, $3 = python patch file, $4 = optional tag file to diff against
  echo
  echo "################################################################"
  bold "CONTROL: $1"
  cp "$2" "$WORK/orig"
  PATCHED_ORIG=$WORK/orig
  PATCHED_FILE=$2
  if ! python3 "$3" "$2"; then
    red "the patch did not apply — the anchor moved. The row measures nothing."
    cp "$WORK/orig" "$2"
    PATCHED_FILE=""
    return 1
  fi
  echo "  patched $2"
  if ! build_diag_bin; then
    red "the patched tree did not build — the row measures nothing:"
    tail -5 "$WORK/build.log" | sed 's/^/    /'
    cp "$WORK/orig" "$2"
    PATCHED_FILE=""
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
  cp "$WORK/orig" "$2"
  if ! cmp -s "$WORK/orig" "$2"; then
    red "the source did NOT come back — every number below is suspect."
    return 1
  fi
  PATCHED_FILE=""
  echo "  RESTORE VERIFIED   $2 byte-identical"
  echo
  if [ "$rc" != 0 ]; then
    green "diagcheck RED $differing   (consistent $consistent, was $DIAG_BASE; speaking on $speaking/$diags, was $DIAG_LINES/$DIAG_DIAGS)"
  else
    echo "  diagcheck ungated — speaking on $speaking units with $diags diagnostics, was $DIAG_LINES/$DIAG_DIAGS."
  fi
  # ★ The comparison PARTNER is a parameter, because three rows of this battery
  # remove check_type_parameter's stop as their PREMISE: their pin has to be read
  # against the row that removes only the stop, not against the unpatched tree.
  local against=${4:-$WORK/base.tags}
  local againstname="the baseline"
  [ "$against" = "$WORK/base.tags" ] || againstname="$(basename "$against" .tags)"
  if cmp -s "$against" "$WORK/ctl.tags"; then
    echo "  pin       unmoved against $againstname — all nine fixtures answer the same tag."
  else
    green "pin       RED against $againstname"
    diff "$against" "$WORK/ctl.tags" | sed 's/^/    /'
  fi
  cp "$WORK/ctl.tags" "$WORK/last.tags"
  if [ "$rc" = 0 ] && cmp -s "$against" "$WORK/ctl.tags"; then
    if [ "$speaking" != "$DIAG_LINES" ] || [ "$diags" != "$DIAG_DIAGS" ]; then
      echo "  ungated on both, WITH A NUMBER: $DIAG_LINES/$DIAG_DIAGS -> $speaking/$diags."
      echo "  A control which REMOVES a diagnostic is ungated on diagcheck by"
      echo "  construction (its header), and the falling count is then the row."
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
# copy of the tree before a single build is spent.

cat > "$PATCHDIR/g01.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ seenDefault MADE NON-STICKY — the reading that a parameter is judged against
# its IMMEDIATE PREDECESSOR rather than against every parameter before it. Both
# TS2706 reports of the fixture set disappear (in `<A = string, B = number, C>` the
# flag is reset at C's own iteration), so the row is ungated on diagcheck by
# construction and its whole content is the falling count. It is also why the
# fixture has THREE parameters: at two, sticky and non-sticky agree.
old = """            let node AstNode.child_in_list(type_parameters, i)
            this.check_type_parameter(node)"""
new = """            let node AstNode.child_in_list(type_parameters, i)
            set seen_default: false
            this.check_type_parameter(node)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g02.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE SAME FLAG FROM THE OTHER SIDE: started TRUE, so every type parameter
# without a default reports TS2706 — the loudest way to say that the flag is what
# gates the report rather than the shape of the list.
old = "        var seen_default false"
new = "        var seen_default true"
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g03.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ TS2706's SPAN MOVED TO THE NAME. `c.error(node, …)` spans the whole
# parameter, modifiers included; this is the confusion with the line two below it,
# which spans the name. Only a parameter that HAS a modifier or a constraint can
# tell them apart — checker_type_parameter_spans.ts is that file.
old = "                    this.error_on_node(node, DiagRequired_type_parameters_may_not_follow_optional_type_parameters)"
new = "                    this.error_on_node(AstNode.name_of(node), DiagRequired_type_parameters_may_not_follow_optional_type_parameters)"
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g04.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ AND THE SAME CONFUSION THE OTHER WAY: TS2300 on the whole parameter instead
# of on its name. The pair g03/g04 is what proves the two spans are two spans.
old = "                    this.error_on_node(AstNode.name_of(node), DiagDuplicate_identifier_0)"
new = "                    this.error_on_node(node, DiagDuplicate_identifier_0)"
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g05.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE INNER LOOP'S BOUND WIDENED BY ONE, so the parameter is compared with
# ITSELF. Every type parameter in the corpus then reports TS2300 — the loudest row
# of the battery, and the point of it is that `for j := range i` is an exclusive
# bound rather than a detail of the spelling.
old = """            var j 0
            while j < i"""
new = """            var j 0
            while j < i + 1"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g06.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE LOOP STOPPED AT ITS FIRST MATCH — *once per duplicate* instead of *once
# per PAIR*. That is the reading this slice's first comment got wrong, and the only
# thing that separates the two is a list with THREE equal names: the third T loses
# one of its two reports and nothing else moves. Removing a diagnostic is ungated
# on diagcheck, so the row IS the number.
old = """                if AstNode.symbol_of(AstNode.child_in_list(type_parameters, j)) = AstNode.symbol_of(node)
                    this.error_on_node(AstNode.name_of(node), DiagDuplicate_identifier_0)
                set j: j + 1"""
new = """                if AstNode.symbol_of(AstNode.child_in_list(type_parameters, j)) = AstNode.symbol_of(node)
                {
                    this.error_on_node(AstNode.name_of(node), DiagDuplicate_identifier_0)
                    set j: i
                }
                set j: j + 1"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g07.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE TWO CODES SWAPPED. Nothing about the counts or the spans moves — the row
# says the codes are checked, which is worth a line because a diagnostic's message
# ARGUMENTS are not compared (the dump is `C pos end code`) and the code is
# therefore the whole of its identity.
old = "                    this.error_on_node(node, DiagRequired_type_parameters_may_not_follow_optional_type_parameters)"
new = "                    this.error_on_node(node, DiagDuplicate_identifier_0)"
old2 = "                    this.error_on_node(AstNode.name_of(node), DiagDuplicate_identifier_0)"
new2 = "                    this.error_on_node(AstNode.name_of(node), DiagRequired_type_parameters_may_not_follow_optional_type_parameters)"
assert s.count(old) == 1, s.count(old)
assert s.count(old2) == 1, s.count(old2)
open(p, "w").write(s.replace(old, new).replace(old2, new2))
PY

cat > "$PATCHDIR/g08.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ TS1110 REPORTED ON THE WHOLE EXPRESSION rather than on its FIRST TOKEN.
# grammarErrorOnFirstToken exists for exactly this difference, and on `-x` it is one
# character wide: the `-` alone against `-x`.
old = "            this.grammar_error_on_first_token(expr, DiagType_expected)"
new = "            this.error_on_node(expr, DiagType_expected)"
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g09.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE SLOT CONFUSED: TS1110 read off the CONSTRAINT instead of the Expression.
# The two are mutually exclusive in the parser, so this makes every CONSTRAINED type
# parameter in the corpus report *type expected* — and it is the row that says the
# recovery slot is a slot of its own rather than a spelling of the constraint.
old = "        let expr AstNode.type_parameter_expression_of(node)"
new = "        let expr AstNode.type_parameter_constraint_of(node)"
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g10.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ checkTypeNameIsReserved's THIRD CALLER REMOVED — the one line of this arm that
# sits BELOW the stop and is ported anyway. Two diagnostics go, which is the price
# of that convention stated as a number rather than as an argument.
old = "        this.check_type_name_is_reserved(AstNode.name_of(node), DiagType_parameter_name_cannot_be_0)\n"
new = ""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g11.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ BOTH checkSourceElement RECURSIONS REMOVED. They produce no diagnostic on any
# fixture, so the pin is the only instrument that can see them: the constraint's and
# the default's TypeReference stop naming themselves and both files fall back to the
# type parameter's own tag. g12 removes only one of the two, and the PAIR is what
# says there are two calls.
old = """        this.check_source_element(AstNode.type_parameter_constraint_of(node))
        this.check_source_element(AstNode.type_parameter_default_of(node))"""
new = ""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g12.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ ONLY THE DEFAULT'S RECURSION REMOVED, so checker_type_parameter_default_reference
# moves and checker_type_parameter_constraint_reference must NOT. Read with g11.
old = "        this.check_source_element(AstNode.type_parameter_default_of(node))\n"
new = ""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g13.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE STOP REMOVED, AND THIS ROW IS THE PREMISE OF THE NEXT TWO. Everything
# this arm ports BELOW getDeclaredTypeOfTypeParameter — the deferred registration,
# and checkTypeParametersNotReferenced one function up — is invisible while the stop
# stands, because record_unported keeps the FIRST report. With it gone, the deferred
# arm's own report becomes the tag of the interface fixture and the not-referenced
# walk's becomes the tag of the default fixture. No diagnostic moves: a
# record_unported writes no C line.
old = '        this.record_unported("get-symbol-of-declaration", KindTypeParameter)\n'
new = ""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g14.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE PREMISE IS A SECOND EDIT, AND FINDING THAT OUT IS WHAT THIS ROW COST.
# check_source_file returns as soon as any statement has reported, and the drain
# sits BELOW that return — so for a type parameter, whose own arm always reports,
# checkDeferredNodes is code that never executes at all. The first draft of this row
# probed the deferred arm alone and moved nothing; it lifts the early return as its
# premise and then probes, which is the only way to ask whether the queue was
# filled and the drain walks it. TS2716 is the code because the reference emits it
# only for a genuinely circular default.
old0 = """        this.check_source_elements(AstNode.statements_of(file))
        if this.is_unported()
            return

        this.check_deferred_nodes()"""
new0 = """        this.check_source_elements(AstNode.statements_of(file))

        this.check_deferred_nodes()"""
assert s.count(old0) == 1, s.count(old0)
s = s.replace(old0, new0)
old = '        this.record_unported("get-declared-type-of-type-parameter", KindTypeParameter)'
new = '        this.error_on_node(node, DiagType_parameter_0_has_a_circular_default)'
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g15.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ g14 PLUS THE GUARD FORCED OPEN. checkTypeParameterDeferred owes the variance
# machinery for exactly three parent kinds; without the guard a FUNCTION's type
# parameter owes it too, so the probe speaks on every generic declaration instead of
# only on the class-like, interface and alias ones. The PAIR g14/g15 is what says the
# guard is a kind test on the PARENT rather than a formality.
old0 = """        this.check_source_elements(AstNode.statements_of(file))
        if this.is_unported()
            return

        this.check_deferred_nodes()"""
new0 = """        this.check_source_elements(AstNode.statements_of(file))

        this.check_deferred_nodes()"""
assert s.count(old0) == 1, s.count(old0)
s = s.replace(old0, new0)
old = '        this.record_unported("get-declared-type-of-type-parameter", KindTypeParameter)'
new = '        this.error_on_node(node, DiagType_parameter_0_has_a_circular_default)'
assert s.count(old) == 1, s.count(old)
s = s.replace(old, new)
old2 = """        if owes = false
            return
"""
assert s.count(old2) == 1, s.count(old2)
open(p, "w").write(s.replace(old2, ""))
PY

cat > "$PATCHDIR/g16.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ g14 PLUS THE REGISTRATION REMOVED, and its PREDICTED verdict is *back to the
# baseline*. The premise is lifted and the probe is in place, and it still cannot
# fire, because checkNodeDeferred is what puts the node in the queue the drain walks.
# Paired with g14 it separates the two halves of a mechanism the reference splits
# across two functions; alone it would read as a row that measures nothing.
old0 = """        this.check_source_elements(AstNode.statements_of(file))
        if this.is_unported()
            return

        this.check_deferred_nodes()"""
new0 = """        this.check_source_elements(AstNode.statements_of(file))

        this.check_deferred_nodes()"""
assert s.count(old0) == 1, s.count(old0)
s = s.replace(old0, new0)
old = '        this.record_unported("get-declared-type-of-type-parameter", KindTypeParameter)'
new = '        this.error_on_node(node, DiagType_parameter_0_has_a_circular_default)'
assert s.count(old) == 1, s.count(old)
s = s.replace(old, new)
old2 = "        this.check_node_deferred(node)\n"
assert s.count(old2) == 1, s.count(old2)
open(p, "w").write(s.replace(old2, ""))
PY

cat > "$PATCHDIR/g17.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE SAME TECHNIQUE ON checkTypeParametersNotReferenced, whose report is
# unreachable for the THIRD variant of the same reason: checkSourceElement(DefaultType)
# runs first, and every type kind that can CONTAIN a type reference has an arm this
# port does not implement, so it reports before this walk is entered. The probe asks
# the question the tag cannot — over the whole corpus, how often does the walk
# actually reach a TypeReference?
old = '            this.record_unported("get-type-from-type-reference", KindTypeReference)'
new = '            this.error_on_node(root, DiagType_parameter_0_has_a_circular_default)'
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g18.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ g17's PROBE WITH THE KIND TEST INVERTED, and this is the ONLY row that gates
# the RECURSION. Every node of every default type then reports, so the count is a
# measurement of the walk itself — without it, a walk that visited only its root
# would be indistinguishable from the ported one, since the report it guards can
# never be first.
old = """        if AstNode.kind_of(root) = KindTypeReference
            this.record_unported("get-type-from-type-reference", KindTypeReference)"""
new = """        if AstNode.kind_of(root) <> KindTypeReference
            this.error_on_node(root, DiagType_parameter_0_has_a_circular_default)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

# ── the dry run ─────────────────────────────────────────────────────────────

bold "DRY RUN — every patch against a COPY of the tree"
DRY=$WORK/dry
mkdir -p "$DRY"
dry_ok=1
for id in g01 g02 g03 g04 g05 g06 g07 g08 g09 g10 g11 g12 g13 g14 g15 g16 g17 g18; do
  cp "$CHECKER" "$DRY/copy"
  if python3 "$PATCHDIR/$id.py" "$DRY/copy" 2> "$DRY/err"; then
    printf '  %s  ok\n' "$id"
  else
    red "  $id  DID NOT APPLY — $(tail -1 "$DRY/err")"
    dry_ok=0
  fi
done
if [ "$dry_ok" != 1 ]; then
  red "at least one anchor is wrong. Fix them before spending the battery."
  exit 2
fi

baseline

control "g01 seenDefault made NON-STICKY (judged against the predecessor)" "$CHECKER" "$PATCHDIR/g01.py"
control "g02 seenDefault started TRUE"                                     "$CHECKER" "$PATCHDIR/g02.py"
control "g03 TS2706's span moved to the NAME"                              "$CHECKER" "$PATCHDIR/g03.py"
control "g04 TS2300's span moved to the whole PARAMETER"                   "$CHECKER" "$PATCHDIR/g04.py"
control "g05 the duplicate loop compares the parameter with ITSELF"        "$CHECKER" "$PATCHDIR/g05.py"
control "g06 the duplicate loop STOPS at its first match (per duplicate)"  "$CHECKER" "$PATCHDIR/g06.py"
control "g07 the two codes SWAPPED"                                        "$CHECKER" "$PATCHDIR/g07.py"
control "g08 TS1110 on the whole expression, not its first token"          "$CHECKER" "$PATCHDIR/g08.py"
control "g09 TS1110 read off the CONSTRAINT slot"                          "$CHECKER" "$PATCHDIR/g09.py"
control "g10 checkTypeNameIsReserved's call removed"                       "$CHECKER" "$PATCHDIR/g10.py"
control "g11 BOTH checkSourceElement recursions removed"                   "$CHECKER" "$PATCHDIR/g11.py"
control "g12 only the DEFAULT's recursion removed"                         "$CHECKER" "$PATCHDIR/g12.py"
control "g13 the arm's STOP removed"                                       "$CHECKER" "$PATCHDIR/g13.py"
control "g14 the file-level early return lifted + the deferred arm PROBED" "$CHECKER" "$PATCHDIR/g14.py"
control "g15 g14 + the deferred GUARD forced open"                          "$CHECKER" "$PATCHDIR/g15.py"
control "g16 g14 + the REGISTRATION removed (predicts: baseline)"           "$CHECKER" "$PATCHDIR/g16.py"
control "g17 checkTypeParametersNotReferenced PROBED"                      "$CHECKER" "$PATCHDIR/g17.py"
control "g18 g17's probe with the kind test INVERTED (gates the recursion)" "$CHECKER" "$PATCHDIR/g18.py"

echo
echo "################################################################"
bold "RESTORED — checker.scaly, byte-identical"
git -C "$REPO" diff --stat -- "$CHECKER" | tail -3
