#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice58.sh — the slice-58 battery: checkExternalImportOrExportDeclaration,
# the one function of the import/export family that needs neither the symbol table
# nor a type, and the three arms it unblocks.
#
# ★★★ TWO INSTRUMENTS, AND THE SPLIT BETWEEN THEM IS THE SLICE'S OWN SHAPE. Four
# of the five reports this slice ports are DIAGNOSTICS, so diagcheck is the main
# instrument and most rows are aimed at it. What it cannot see is the CONTINUATION:
# whether each arm goes on to the right next call. That is an unported TAG, no
# yardstick compares a tag, and one of this slice's two option findings
# (NoUncheckedSideEffectImports is TRUE when unset) is visible through nothing else.
# Hence the PIN.
#
# ★★★ AND THREE ROWS ARE UNGATED BY CONSTRUCTION AND SAY SO WITH A NUMBER OR A
# PROOF. diagcheck's relation is a SUBSEQUENCE, so a control that REMOVES a report
# is green by definition — its header says as much. Such a row is still a
# measurement when the falling count is printed, and that is what g8, g9, g12, g14,
# g16, g17 and g19 are. Two rows are ungated with a PROOF instead: g11 patches out
# a term of the reference that is provably inert here, and g15 substitutes the
# naive reading of an unset option and predicts that nothing moves — which is the
# honest statement of what this package can and cannot measure about
# Checker.module_kind.
#
# ★★ THE ROWS DO NOT GO THROUGH ctl.sh, for slice 48's reason: the instruments read
# the reference dumps run.sh produced, and a filtered run would rewrite part of that
# tree. Each row builds the package and the dumper into a scratch directory, points
# the instruments at it, leaves tests/out alone, restores the source and PROVES the
# restore with `cmp`.
#
# ★ THREE FILES ARE PATCHED across the battery — checker.scaly, ast.scaly and
# tspath.scaly — which is why `control` takes the file as an argument. Slice 58 is
# the first of this family whose cost is spread over three modules, and the ast and
# tspath rows are the only thing that measures the two of them.
#
# ★ Every patch is dry-run against a COPY of the tree before the battery is spent,
# which is slice 57's lesson: an anchor that matches twice costs the whole run.
#
# Usage (nothing may edit the tree while this runs — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # the artifact tree, first
#   packages/tscaly/tests/controls-slice58.sh 2>&1 | tee /tmp/battery58.log

set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.1/tscaly/checker.scaly
AST=$PKG/0.1.1/tscaly/ast.scaly
TSPATH=$PKG/0.1.1/tscaly/tspath.scaly
FIX=$PKG/tests/fixtures

. packages/tscaly/tests/toolchain.sh || exit 2

# The fixtures the PIN reads — the CONTINUATION of each arm, one shape per file.
# The first two are the pair that separates the two import continuations, and they
# are one statement each because record_unported keeps the FIRST report (slice 56's
# *a fixture that cannot be first is not a witness*).
TAGFILES="
$FIX/checker_import_side_effect.ts
$FIX/checker_import_clause_only.ts
$FIX/checker_import_string_literal_expected.ts
$FIX/checker_import_defer.ts
$FIX/checker_ambient_module_augmentation_relative.d.ts
$FIX/checker_export_empty_clause.ts
"

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  echo "Both instruments compare against the reference dumps that run produced."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl58)

# ★★★ THE RESTORE MUST SURVIVE A KILL, and this trap is here because it did not.
# `control` restores the patched file and PROVES it with `cmp` — but only if it
# reaches that line. Interrupt the battery (Ctrl-C, `pkill`, a closed terminal)
# and the tree is left carrying whatever the running row put there. Measured the
# expensive way in slice 58: a battery killed inside g11 left *the type arm loses
# its named-bindings test* in checker.scaly, and the next thing built from that
# tree invented a TS1363 — which read exactly like a defect in the code the slice
# had just written, and was diagnosed as one for two rounds. ★The tell was that
# `tests/out/tscaly_types`, built BEFORE the battery, was silent while a fresh
# build was not: **when an old binary and a new one disagree and the source is
# supposed to be unchanged, ask what edited the source, not what is wrong with
# it.**
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
  "$SCALYC" -c --no-prelude -o "$WORK/pkg.o" "$PKG/0.1.1/tscaly.scaly" > "$WORK/build.log" 2>&1 || return 1
  "$SCALYC" -c -o "$WORK/types.o" "$PKG/0.1.1/tscaly_types.scaly" >> "$WORK/build.log" 2>&1 || return 1
  clang -o "$WORK/tscaly_types" "$WORK/types.o" "$WORK/pkg.o" "$LIBSCALY" -lm >> "$WORK/build.log" 2>&1
}

# The PIN: one line per fixture, "<basename> <tag> <detail>".
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
  echo "  the PIN — the six fixtures' unported tags on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.tags"
  if grep -q '	$' "$WORK/base.tags"; then
    red "a fixture answers NO tag — the pin would be comparing two empties."
    exit 2
  fi
  echo
  echo "  BASELINE   $DIAG_BASE units consistent, $DIAG_LINES speaking, $DIAG_DIAGS diagnostics"
}

control() {   # $1 = label, $2 = file, $3 = python patch file
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
  if cmp -s "$WORK/base.tags" "$WORK/ctl.tags"; then
    echo "  pin       unmoved — all six fixtures answer the same tag."
  else
    green "pin       RED"
    diff "$WORK/base.tags" "$WORK/ctl.tags" | sed 's/^/    /'
  fi
  if [ "$rc" = 0 ] && cmp -s "$WORK/base.tags" "$WORK/ctl.tags"; then
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
# copy of the tree before a single build is spent. Slice 57 lost fifteen minutes
# to an anchor that matched twice; this costs two seconds.

cat > "$PATCHDIR/g01.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ The string-literal test INVERTED. Every module specifier in the corpus is a
# string literal, so this INVENTS TS1141 on all of them and silences the three
# real ones — the loudest row of the battery in both directions at once.
old = """        if AstNode.kind_of(module_name) <> KindStringLiteral
        {
            this.error_on_node(module_name, DiagString_literal_expected)"""
new = """        if AstNode.kind_of(module_name) = KindStringLiteral
        {
            this.error_on_node(module_name, DiagString_literal_expected)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g02.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★ A CODE-ONLY row, same span and same order — the cheapest demonstration that
# the dump compares the code and not just the position.
old = "            this.error_on_node(module_name, DiagString_literal_expected)"
new = "            this.error_on_node(module_name, DiagIdentifier_expected)"
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g03.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ The namespace message PAIR swapped. Both codes exist and both are correct
# for the OTHER kind, so nothing about the shape of the output changes — only
# which of two numbers stands on which line. It is the row that says the IfElse
# was read in the right direction.
old = """                var code: int DiagImport_declarations_in_a_namespace_cannot_reference_a_module
                if AstNode.kind_of(node) = KindExportDeclaration
                    set code: DiagExport_declarations_are_not_permitted_in_a_namespace"""
new = """                var code: int DiagExport_declarations_are_not_permitted_in_a_namespace
                if AstNode.kind_of(node) = KindExportDeclaration
                    set code: DiagImport_declarations_in_a_namespace_cannot_reference_a_module"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g04.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ The `parent is SourceFile` test dropped. Every top-level import and export
# in the corpus then reports TS1147 or TS1194 — the whole population of the three
# arms, inverted — and every one of them is a line the reference does not have.
old = """        if Checker.kind_or_unknown(parent) <> KindSourceFile
        {
            if in_ambient_external_module = false"""
new = """        if 1 = 1
        {
            if in_ambient_external_module = false"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g05.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ `in_ambient_external_module` forced false. The permitting half of the
# ambient-module test goes, so every import inside `declare module "m"` reports
# TS1147 instead of being allowed — and the TS2439 block above it, which is
# guarded by the same flag, goes silent at the same time. Two effects, opposite
# signs, and diagcheck sees the invented one.
old = """            if Checker.is_ambient_module_or_null(AstNode.parent_node_of(parent))
                set in_ambient_external_module: true
        }
        if Checker.kind_or_unknown(parent) <> KindSourceFile"""
new = """            if Checker.is_ambient_module_or_null(AstNode.parent_node_of(parent))
                set in_ambient_external_module: false
        }
        if Checker.kind_or_unknown(parent) <> KindSourceFile"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g06.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ The augmentation suppression REMOVED. checker_ambient_module_augmentation_relative.d.ts
# exists for exactly this: three statements whose reference answer is silence,
# which become three invented TS2439s the moment the guard goes. Without that
# fixture the row would be ungated, which is why the pair was written together.
old = "                if Checker.is_top_level_in_external_module_augmentation(this.b, node) = false"
new = "                if 1 = 1"
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g07.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★ The suppression always ON — the other direction of g06, and ungated by
# construction: the three real TS2439s disappear and a shorter list is still a
# subsequence. The falling count IS the row.
old = "                if Checker.is_top_level_in_external_module_augmentation(this.b, node) = false"
new = "                if 1 = 0"
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g08.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ The attribute loop RETURNS at the first bad value. This is the shape a port
# writes when it reads `hasError` as a bail-out rather than as an accumulator, and
# it is invisible to a subsequence test — checker_import_attribute_values.ts puts
# TWO bad values on one line precisely so the COUNT can say it.
old = """                        set has_error: true
                        this.error_on_node(value, DiagImport_attribute_values_must_be_string_literal_expressions)"""
new = """                        set has_error: true
                        this.error_on_node(value, DiagImport_attribute_values_must_be_string_literal_expressions)
                        return false"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g09.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ The export arm's `module_specifier = null` term dropped — and this row is
# UNGATED WITH A PROOF rather than with a number. To reach the line at all the
# guard above must have passed, which means either the parent IS a SourceFile (so
# `pk = KindModuleBlock` is false) or `in_ambient_external_module` is true (so the
# enclosing `if` is false). In both cases the term cannot change the answer. Slice
# 50 omitted it for that reason and the omission EXPIRED when the specifier-bearing
# half became reachable; it is restored because the reference has it, not because
# anything can see it. This row is what turns that from an assertion into a
# measurement.
old = """                if module_specifier = null
                {
                    if (AstNode.flags_of(node) & NodeFlagsAmbient) <> 0
                        set in_ambient_namespace_declaration: true
                }"""
new = """                if (AstNode.flags_of(node) & NodeFlagsAmbient) <> 0
                    set in_ambient_namespace_declaration: true"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g10.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ The specifier-loop tag RETURNS again — slice 50's shape, restored. The
# report BELOW the loop then becomes unreachable exactly as it was, and
# checker_export_clause_in_namespace.ts's TS1194 disappears. Ungated by
# construction; the falling count is the row, and it is the one number that says
# what "mark and continue" bought.
old = """        if AstNode.list_count(els) > 0
            this.record_unported("check-export-specifier", KindExportDeclaration)"""
new = """        if AstNode.list_count(els) > 0
        {
            this.record_unported("check-export-specifier", KindExportDeclaration)
            return
        }"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g11.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ checkGrammarImportClause's type arm loses its `named_bindings <> null` test.
# `import type B from "./y"` — a plain default type import, three of them in
# checker_type_only_import.ts and many more in the corpus — then reports TS1363,
# a diagnostic about a combination it does not have.
old = """                if AstNode.name_of(node) <> null
                {
                    if named_bindings <> null
                        return this.grammar_error_on_node(node, DiagA_type_only_import_can_specify_a_default_import_or_named_bindings_but_not_both)
                }"""
new = """                if AstNode.name_of(node) <> null
                    return this.grammar_error_on_node(node, DiagA_type_only_import_can_specify_a_default_import_or_named_bindings_but_not_both)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g12.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ module_kind := ESNext. TS18060 is the only ported reading of the field, and
# ESNext is one of the two values that switch it off — so this row proves the
# field is READ. Its twin g13 proves that the DERIVATION is, today, unobservable.
old = "        set c.module_kind: ModuleKindES2022"
new = "        set c.module_kind: ModuleKindESNext"
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g13.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ module_kind := None — the NAIVE reading of the unset `module` option, and
# the row predicts that NOTHING MOVES. That is the honest statement of what this
# package can measure: `!= ESNext && != Preserve` is true for None as it is for
# ES2022, so the derived value and the naive one agree at the one reading that is
# ported. The derivation is defended from the reference; the first instrument that
# could separate them is the slice which ports checkModuleExportName.
old = "        set c.module_kind: ModuleKindES2022"
new = "        set c.module_kind: ModuleKindNone"
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g14.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ no_unchecked_side_effect_imports := false — the naive reading of THAT unset
# option, and unlike g13 it is WRONG and the pin says so. `IsTrueOrUnknown()` is
# true for a Tristate's zero value, so the branch is taken; read it as false and
# checker_import_side_effect.ts's arm runs past the hole and the unit's tag
# changes. No diagnostic moves in either direction.
old = "        set c.no_unchecked_side_effect_imports: true"
new = "        set c.no_unchecked_side_effect_imports: false"
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g15.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ The import arm's continuation wired to the WRONG branch: the clause test
# inverted, so a side-effect import is treated as one with a clause and vice
# versa. Both tags swap and no diagnostic moves — the pin is the whole instrument,
# which is what the two one-statement fixtures were written for.
old = """            let import_clause AstNode.import_clause_of(node)
            if import_clause = null"""
new = """            let import_clause AstNode.import_clause_of(node)
            if import_clause <> null"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/a01.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ get_external_module_name loses its ImportEqualsDeclaration arm — §3.5br's
# narrowing, performed deliberately so the cost of it is a number rather than an
# argument. `import c = require(m)` then answers null, the check returns at its
# first line, and both the TS1141 on that line and the TS2439 on the `/rooted`
# one disappear. Ungated by construction; the falling count is the row, and it is
# what says the arm is load-bearing for two different reports in two files.
old = """        if k = KindImportEqualsDeclaration
        {
            let r AstNode.module_reference_of(n)"""
new = """        if k = KindImportEqualsDeclaration
        {
            return null
        }
        if k = KindNotEmittedStatement
        {
            let r AstNode.module_reference_of(n)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/a02.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ import_attribute_value_of answers the attribute's NAME instead of its VALUE.
# `with { type: "json" }` — the well-formed line — then reports TS2858 on an
# identifier, so the row INVENTS a diagnostic in the one place the fixture put a
# correct attribute. A reader-level defect that no test of the bad values could
# catch, which is why the third line of that fixture exists.
old = """    function import_attribute_value_of(n: pointer[AstNode]) returns pointer[AstNode]
    {
        if n = null
            return null
        choose n.data
            when ia: ImportAttribute
                return ia.value
        null
    }"""
new = """    function import_attribute_value_of(n: pointer[AstNode]) returns pointer[AstNode]
    {
        if n = null
            return null
        choose n.data
            when ia: ImportAttribute
                return ia.name
        null
    }"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/a03.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ named_bindings_of answers null. checkGrammarImportClause then sees a clause
# with a default name and nothing else at every site: TS1363 goes (no bindings to
# conflict with), TS2206 goes (no NamedImports to walk) and TS18059 goes. Three
# reports from three fixtures, all falling — ungated, and the number is the row.
old = """    function named_bindings_of(n: pointer[AstNode]) returns pointer[AstNode]
    {
        if n = null
            return null
        choose n.data
            when ic: ImportClause
                return ic.named_bindings
        null
    }"""
new = """    function named_bindings_of(n: pointer[AstNode]) returns pointer[AstNode]
    {
        null
    }"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/p01.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ path_is_relative loses its `../` arm. `../b` in
# checker_ambient_module_relative_import.d.ts stops being relative and its TS2439
# goes — the one line of that fixture that no other arm covers. Ungated; the
# number is the row.
old = """    if n >= 3
    {
        if (*d as int) = ("." as char) as int
        {
            if (*(d + 1) as int) = ("." as char) as int
            {
                if is_any_directory_separator(*(d + 2) as int)
                    return true
            }
        }
    }
    false"""
new = """    false"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/p02.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ is_rooted_disk_path always false. `require("/rooted")` stops being relative
# and its TS2439 goes. It is the arm whose NAME argues against it — an absolute
# path is not "relative" in any ordinary sense, and the reference counts it as one
# because it is not searched for in node_modules. A port that trusted the name
# would write exactly this.
old = """function is_rooted_disk_path(d: pointer[char], n: int) returns bool
{
    get_encoded_root_length(d, n) > 0
}"""
new = """function is_rooted_disk_path(d: pointer[char], n: int) returns bool
{
    false
}"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/p03.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ is_external_module_name_relative always true. The bare specifier `"bare"` in
# checker_ambient_module_relative_import.d.ts then reports TS2439 — a diagnostic
# the reference does not have — which is the row that says the predicate is asked
# and its FALSE answer is used, not merely its true one.
old = """function is_external_module_name_relative(d: pointer[char], n: int) returns bool
{
    if path_is_relative(d, n)
        return true
    is_rooted_disk_path(d, n)
}"""
new = """function is_external_module_name_relative(d: pointer[char], n: int) returns bool
{
    true
}"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

# ── the dry run ─────────────────────────────────────────────────────────────

bold "DRY RUN — every patch against a COPY of the tree"
DRY=$WORK/dry
mkdir -p "$DRY"
dry_ok=1
for spec in g01:$CHECKER g02:$CHECKER g03:$CHECKER g04:$CHECKER g05:$CHECKER \
            g06:$CHECKER g07:$CHECKER g08:$CHECKER g09:$CHECKER g10:$CHECKER \
            g11:$CHECKER g12:$CHECKER g13:$CHECKER g14:$CHECKER g15:$CHECKER \
            a01:$AST a02:$AST a03:$AST p01:$TSPATH p02:$TSPATH p03:$TSPATH; do
  id=${spec%%:*}; f=${spec#*:}
  cp "$f" "$DRY/copy"
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

control "g01 the string-literal test INVERTED"                       "$CHECKER" "$PATCHDIR/g01.py"
control "g02 TS1141's CODE"                                          "$CHECKER" "$PATCHDIR/g02.py"
control "g03 the namespace message pair SWAPPED"                     "$CHECKER" "$PATCHDIR/g03.py"
control "g04 the SourceFile-parent test dropped"                     "$CHECKER" "$PATCHDIR/g04.py"
control "g05 in_ambient_external_module forced false"                "$CHECKER" "$PATCHDIR/g05.py"
control "g06 the augmentation suppression REMOVED"                   "$CHECKER" "$PATCHDIR/g06.py"
control "g07 the augmentation suppression always ON"                 "$CHECKER" "$PATCHDIR/g07.py"
control "g08 the attribute loop returns at the first bad value"      "$CHECKER" "$PATCHDIR/g08.py"
control "g09 the export arm's module_specifier term dropped"         "$CHECKER" "$PATCHDIR/g09.py"
control "g10 the specifier-loop tag RETURNS again"                   "$CHECKER" "$PATCHDIR/g10.py"
control "g11 the type arm loses its named-bindings test"             "$CHECKER" "$PATCHDIR/g11.py"
control "g12 module_kind := ESNext"                                  "$CHECKER" "$PATCHDIR/g12.py"
control "g13 module_kind := None  (the naive unset reading)"         "$CHECKER" "$PATCHDIR/g13.py"
control "g14 no_unchecked_side_effect_imports := false"              "$CHECKER" "$PATCHDIR/g14.py"
control "g15 the import arm's clause test INVERTED"                  "$CHECKER" "$PATCHDIR/g15.py"
control "a01 get_external_module_name loses its ImportEquals arm"    "$AST"     "$PATCHDIR/a01.py"
control "a02 import_attribute_value_of answers the NAME"             "$AST"     "$PATCHDIR/a02.py"
control "a03 named_bindings_of answers null"                         "$AST"     "$PATCHDIR/a03.py"
control "p01 path_is_relative loses its ../ arm"                     "$TSPATH"  "$PATCHDIR/p01.py"
control "p02 is_rooted_disk_path always false"                       "$TSPATH"  "$PATCHDIR/p02.py"
control "p03 is_external_module_name_relative always true"           "$TSPATH"  "$PATCHDIR/p03.py"

echo
echo "################################################################"
bold "RESTORED — the three patched files, byte-identical"
git -C "$REPO" diff --stat -- "$CHECKER" "$AST" "$TSPATH" | tail -5
