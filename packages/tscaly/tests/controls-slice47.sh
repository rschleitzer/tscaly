#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice47.sh — the slice-47 control battery, seventeen of them, in TWO
# families, and the split is the slice's own finding rather than a convenience.
#
# ★★★ THE C SECTION GATES THE T SECTION, so a control aimed at the type WALK
# cannot be measured by the yardstick. The checker skeleton answers nine units of
# 1 040 — the ones with no statements — because a unit counts as matched only when
# BOTH sections agree and the C section is complete only when the check of every
# statement is ported. Everything the walk is made of (forEachASTNode's two
# Reparsed conditions, skipForType's four exclusions, ast.IsPartOfTypeNode's twenty
# arms, GetMeaningFromDeclaration's six, the nameless-import guard) is therefore
# invisible to run.sh's counters — which is §3.5v's fourth kind of ungated row, and
# the answer to it is an INSTRUMENT rather than a shrug:
#
#   c1..c6   patched through ctl.sh, measured by the five yardsticks' counters
#   w1..w11  patched here, measured by tests/walkcheck.sh — the walk's NODE LIST
#            against the reference's own, over every unit of the corpus
#
# ★★ THE w-ROWS DO NOT GO THROUGH ctl.sh, and the reason is the artifact tree:
# walkcheck reads the reference dumps run.sh produced, so a control must not
# re-run run.sh (a filtered run rewrites part of that tree). Each w-row therefore
# builds the package and the dumper into a scratch directory, points walkcheck's
# `BIN` at it and leaves tests/out alone — and it restores the source and PROVES
# the restore with `cmp`, which is ctl.sh's own rule and the one that matters most
# here.
#
# Usage (nothing may edit the tree while this runs — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # the artifact tree, first
#   packages/tscaly/tests/controls-slice47.sh 2>&1 | tee /tmp/battery47.log
#
# 1 baseline + 6 ctl controls + 11 walk controls, about 40 minutes on this box.

set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

CTL=packages/tscaly/tests/ctl.sh
WALKCHECK=packages/tscaly/tests/walkcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.0/tscaly/checker.scaly
DUMP=$PKG/0.1.0/tscaly/TypeDump.scaly
AST=$PKG/0.1.0/tscaly/ast.scaly

LIBSCALY=${LIBSCALY:-/tmp/libscaly.a}
SCALYC=${SCALYC:-$REPO/scalyc/build/scalyc}

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  echo "The w-rows compare against the reference dumps that run produced."
  exit 2
fi

export TSCALY_BASELINE=$(mktemp -t tscaly-baseline)
WORK=$(mktemp -d -t tscaly-ctl47)
cleanup() { rm -f "$TSCALY_BASELINE" "$TSCALY_BASELINE.fp"; rm -rf "$WORK"; }
trap cleanup EXIT

echo "################################################################"
if ! "$CTL" --establish-baseline </dev/null; then
  exit 2
fi

run() { echo; echo "################################################################"; "$CTL" "$1"; }

# ── the ctl family: what the nine matched units actually gate ────────────────

# ★ c1 is the row that says the inventory is load-bearing rather than decorative.
# getTypeOfNode's chain has ten predicates this slice cannot evaluate, so a kind
# that is not PROVEN to reach the errorType fallthrough must report — and the one
# kind that is proven is the end-of-file token, which is the whole of every matched
# unit's T section.
run "c1 the kind inventory is what admits the end-of-file token" <<SPEC
FILE $CHECKER
<<<OLD
        if k = KindEndOfFile
            return true
        false
    }
>>>NEW
        false
    }
SPEC

# The fallthrough's TYPE is compared, not merely its presence. unknownType prints
# `unknown`, so this changes the third field of the one line every matched unit has.
run "c2 the fallthrough answers errorType, and the type is compared" <<SPEC
FILE $CHECKER
<<<OLD
        ; The chain's own end: "if we get here, the node is not something we have
        ; a type for". Reached by exactly the kinds the inventory admits.
        error_type
>>>NEW
        unknown_type
SPEC

# ★★★ c3 IS EXPECTED TO BE UNGATED, and the row exists to record WHY rather than
# to gate anything: errorType and anyType are two different types with two
# different intrinsic NAMES ("error", "any") and the same flag, and the reference's
# printer branches on the FLAG — it reads the name only to recognise
# intrinsicMarkerType. So no dump this yardstick compares can tell them apart, and
# a port that confused them would look right here. What DOES tell them apart is
# isErrorType, which several checker arms test; the first of those to be ported is
# the slice that can gate this line.
run "c3 errorType against anyType — invisible to the dump by construction" <<SPEC
FILE $CHECKER
<<<OLD
        ; The chain's own end: "if we get here, the node is not something we have
        ; a type for". Reached by exactly the kinds the inventory admits.
        error_type
>>>NEW
        any_type
SPEC

# The printer's keyword arm. The keyword arms of typeToTypeNodeHelper are transcribed
# and exactly one of them is reachable in this slice; this row is the proof that it
# is reached.
run "c4 the printer's Any arm answers the keyword the reference prints" <<SPEC
FILE $CHECKER
<<<OLD
            if t = intrinsic_marker_type
                return "intrinsic"
            return "any"
>>>NEW
            if t = intrinsic_marker_type
                return "intrinsic"
            return "unknown"
SPEC

# The oracle skips the unit node itself (`node == unit.AsNode()`), so our side must
# too — otherwise every dump gains a leading line for the source file, which the
# reference never emits.
run "c5 the unit node itself is excluded from the T section" <<SPEC
FILE $DUMP
<<<OLD
        if node = file
            return
>>>NEW
        if node = null
            return
SPEC

# ★ c6 gates the new fixture, and the placement of a REPORT rather than a
# behaviour: check_grammar_source_file cannot port
# checkGrammarTopLevelElementsForRequiredDeclareModifier (it needs
# ast.IsDeclarationNode), so it reports — and the zero-statement guard is what keeps
# an ambient file that cannot reach the loop BODY comparable. Expect RED 1:
# checker_ambient_empty.d.ts is the only such unit in the corpus.
run "c6 the ambient guard keeps a statement-less .d.ts comparable" <<SPEC
FILE $CHECKER
<<<OLD
        if AstNode.list_count(AstNode.statements_of(file)) = 0
            return false
        this.record_unported("grammar-source-file-declare", 0)
>>>NEW
        this.record_unported("grammar-source-file-declare", 0)
SPEC

# ── the walk family: measured by the instrument, not by the yardstick ────────

build_walk_bin() {
  "$SCALYC" -c --no-prelude -o "$WORK/pkg.o" "$PKG/0.1.0/tscaly.scaly" > "$WORK/build.log" 2>&1 || return 1
  "$SCALYC" -c -o "$WORK/types.o" "$PKG/0.1.0/tscaly_types.scaly" >> "$WORK/build.log" 2>&1 || return 1
  clang -o "$WORK/tscaly_types" "$WORK/types.o" "$WORK/pkg.o" "$LIBSCALY" -lm >> "$WORK/build.log" 2>&1
}

WALK_BASE=""

walk_baseline() {
  echo
  echo "################################################################"
  bold "WALK BASELINE"
  if ! build_walk_bin; then
    red "the unpatched tree did not build — every w-row below would be measuring that."
    sed 's/^/    /' "$WORK/build.log"
    exit 2
  fi
  BIN=$WORK/tscaly_types "$WALKCHECK" > "$WORK/base.walk" 2>&1
  local rc=$?
  WALK_BASE=$(sed -n 's/^  matched  *\([0-9]*\)$/\1/p' "$WORK/base.walk")
  sed -n '/^walkcheck/,$p' "$WORK/base.walk" | sed 's/^/  /'
  if [ "$rc" != 0 ]; then
    red "the walk instrument is already red on the unpatched tree — fix that first."
    exit 2
  fi
  echo "  BASELINE   $WALK_BASE units agree with the reference's node list"
}

walk_control() {   # $1 = label, $2 = file, $3 = python patch file
  echo
  echo "################################################################"
  bold "CONTROL (walk): $1"
  cp "$2" "$WORK/orig"
  if ! python3 "$3" "$2"; then
    red "the patch did not apply — the anchor moved. The row measures nothing."
    cp "$WORK/orig" "$2"
    return 1
  fi
  echo "  patched $2"
  if ! build_walk_bin; then
    red "the patched tree did not build — the row measures nothing:"
    tail -5 "$WORK/build.log" | sed 's/^/    /'
    cp "$WORK/orig" "$2"
    return 1
  fi
  BIN=$WORK/tscaly_types "$WALKCHECK" > "$WORK/ctl.walk" 2>&1
  local rc=$?
  local matched
  matched=$(sed -n 's/^  matched  *\([0-9]*\)$/\1/p' "$WORK/ctl.walk")
  local diff
  diff=$(sed -n 's/^  differing  *\([0-9]*\)$/\1/p' "$WORK/ctl.walk")
  cp "$WORK/orig" "$2"
  if ! cmp -s "$WORK/orig" "$2"; then
    red "the source did NOT come back — every number below is suspect."
    return 1
  fi
  echo "  RESTORE VERIFIED   $2 byte-identical"
  echo
  if [ "$rc" != 0 ]; then
    green "RED $diff   (matched $matched, was $WALK_BASE)"
  else
    red "UNGATED: the node list is unchanged. Decide which of §3.5v's four kinds that is."
  fi
  return 0
}

walk_baseline

cat > "$WORK/w1.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# The walk's CHILD ORDER. The reference pushes the children reversed onto a stack
# precisely so that popping yields ForEachChild's order; visiting them backwards is
# the same set of nodes in the wrong sequence, which is what a T section compares.
old = """        var i 0
        let count AstNode.child_count(elem)
        while i < count
        {
            this.walk(AstNode.child_at(elem, i))
            if c.is_unported()
                return
            set i: i + 1
        }"""
new = """        var i AstNode.child_count(elem) - 1
        while i >= 0
        {
            this.walk(AstNode.child_at(elem, i))
            if c.is_unported()
                return
            set i: i - 1
        }"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
walk_control "w1 the walk's child order is the reference's own" "$DUMP" "$WORK/w1.py"

cat > "$WORK/w2.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# skipForType's first exclusion, and the one the whole yardstick rests on: a node
# that is already a type may not be asked for its type.
old = """        if AstNode.is_part_of_type_node(node)
            return true
"""
new = """        if false
            return true
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
walk_control "w2 skipForType excludes what is already a type" "$DUMP" "$WORK/w2.py"

cat > "$WORK/w3.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★ The NullKeyword arm of IsPartOfTypeNode, which is the arm that explains a dump
# rather than a crash: the reference emits NO type line for the `null` in `null;`,
# because in a LiteralType position the keyword IS a type and the predicate does not
# distinguish. Measured against the oracle, so the row says how often the corpus
# contains one.
old = """        if k = KindNullKeyword
            return true
"""
new = """        if false
            return true
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
walk_control "w3 IsPartOfTypeNode's NullKeyword arm" "$AST" "$WORK/w3.py"

cat > "$WORK/w4.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# skipForType's identifier exclusion: a declaration name that declares nothing into
# the VALUE space is not asked about.
old = """            if (c.get_meaning_from_declaration(p) & SemanticMeaningValue) = 0
            {"""
new = """            if false
            {"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
walk_control "w4 skipForType's value-meaning exclusion for an identifier" "$DUMP" "$WORK/w4.py"

cat > "$WORK/w5.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# The one EXCEPTION to w4: a type alias's own name IS asked about. Removing the
# exception excludes it, which is a node fewer rather than a node more — the
# direction a weakened exclusion cannot produce, so the two rows are not the same
# claim seen twice.
old = """                if AstNode.is_type_or_js_type_alias_declaration(p)
                {"""
new = """                if false
                {"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
walk_control "w5 the type-alias NAME is the exception to w4" "$DUMP" "$WORK/w5.py"

cat > "$WORK/w6.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# GetMeaningFromDeclaration's ModuleDeclaration arm: an INSTANTIATED namespace
# declares a value as well as a namespace, so its name is asked about. Dropping the
# instance-state test leaves a namespace declaring only a namespace, i.e. no value —
# which excludes its name.
old = """            if b.get_module_instance_state(node) = ModuleInstanceStateInstantiated
                return SemanticMeaningNamespace | SemanticMeaningValue
"""
new = """            if false
                return SemanticMeaningNamespace | SemanticMeaningValue
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
walk_control "w6 an instantiated module declares a VALUE too" "$CHECKER" "$WORK/w6.py"

cat > "$WORK/w7.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# The ORACLE's own exclusion, mirrored: a nameless type-only import clause is a nil
# dereference inside the reference, so a node the oracle cannot ask about must not
# appear on this side either.
old = """        if TypeDump.is_nameless_type_only_import_clause(node)
            return
"""
new = """        if false
            return
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
walk_control "w7 the nameless type-only import clause is excluded" "$DUMP" "$WORK/w7.py"

cat > "$WORK/w8.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ THE FIELD'S FIRST READER, measured. ImportTypeData.is_type_of has been stored
# since the type-node slice with a note saying no yardstick could see it and the
# reader would be the checker; this row asks the corpus whether that reader is
# reached — `typeof import("m")` against `import("m")` decides whether the node
# under the ImportType is part of a type node.
old = """        if pk = KindImportType
            return import_type_is_type_of(p) = false
"""
new = """        if pk = KindImportType
            return true
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
walk_control "w8 ImportTypeData.is_type_of's first reader" "$AST" "$WORK/w8.py"

cat > "$WORK/w9.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# forEachASTNode's OUTER condition — whether to descend at all. A reparsed subtree
# is JSDoc-derived syntax that is not in the source; descending into it adds nodes
# the reference never walks.
old = """        if descend = false
            return
"""
new = """        set descend: true
        if descend = false
            return
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
walk_control "w9 forEachASTNode's Reparsed DESCEND condition" "$DUMP" "$WORK/w9.py"

cat > "$WORK/w10.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# forEachASTNode's INNER condition — whether to ASK about this node. It is not the
# same condition as w9's: a reparsed node under an `as`/`satisfies` is asked about,
# and a reparsed node that merely contains one is descended into without being
# asked. Two conditions, two rows.
old = """        if ask
            this.visit(elem)
"""
new = """        set ask: true
        if ask
            this.visit(elem)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
walk_control "w10 forEachASTNode's Reparsed ASK condition" "$DUMP" "$WORK/w10.py"

cat > "$WORK/w11.py" <<'XPY'
import sys
p = sys.argv[1]
s = open(p).read()
# THIS ROW EXISTS BECAUSE w10 CAME BACK UNGATED, and it is what turned that
# investigation into a gate. skipForType's SECOND exclusion drops an `as` /
# `satisfies` whose TYPE is reparsed, i.e. a JSDoc-derived assertion — and it
# guards the same door w10's condition does: over stage 1 every reparsed assertion
# node the walk descends into ALSO has an assertion parent, so w10's `ask` is
# already true for it and THIS arm is what removes it. Disabling this one alone is
# therefore the measurement w10 could not make, and the lines it adds name the two
# shapes: kind 235 (as) and kind 239 (satisfies).
old = """        if assertion
        {
            let ty AstNode.type_of(node)"""
new = """        if false
        {
            let ty AstNode.type_of(node)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
XPY
walk_control "w11 skipForType's arm for a REPARSED as/satisfies — w10's missing half" "$DUMP" "$WORK/w11.py"

echo
echo "################################################################"
green "battery 47 complete — 6 ctl rows, 11 walk rows"
echo "Read every UNGATED row against §3.5v's four kinds before writing it down."
