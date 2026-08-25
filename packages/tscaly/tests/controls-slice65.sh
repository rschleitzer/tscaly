#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice65.sh — the slice-65 battery: the two 5 500-unit heads, i.e.
# checkExportsOnMergedDeclarations and getSymbolOfDeclaration, everything they
# needed (getMergedSymbol, getLateBoundSymbol, node.LocalSymbol,
# GetCombinedModifierFlags as a VALUE, getEnclosingContainer,
# getEffectiveDeclarationFlags, getDeclarationSpaces, GetDeclarationOfKind), and the
# five arms that were waiting behind them — the interface, the class, the type
# ALIAS (which completes), the ENUM with its member arm, and the module declaration
# with its whole tail.
#
# ★★★ THE BATTERY'S SHAPE FOLLOWS THE SLICE'S: two heads and a fan-out. Rows g01–g06
# are about the SYMBOL — is it really asked for, is the merged/late-bound pair on the
# path, is the LOCAL symbol load-bearing, does the once-guard guard once — and rows
# g07–g30 about what the five arms do with it. The reason that split matters is that
# the symbol half is almost invisible: getSymbolOfDeclaration is four lines and
# 5 593 units were waiting on it, so a row that breaks it goes red by the thousand
# while a row that breaks an arm moves a handful.
#
# ★★★ THE MOST INFORMATIVE ROWS ARE THE ONES WHERE THE REFERENCE'S ANSWER IS
# NOTHING. checker_merged_declaration_silent.ts holds three merges the check must be
# quiet about, each for a different reason, and three rows here (g12, g19, g20) are
# ungated without it: a port that reported on every merge passes every positive
# fixture in this slice. **A check whose job is to find an intersection is measured
# by the pairs that do not intersect.**
#
# ★★ TWO INSTRUMENTS, as in slices 56–64. diagcheck gates the reports; a PIN over the
# eight fixtures' unported TAGS gates the arms and the wirings that produce no
# diagnostic at all — and in this slice the pin carries more than usual, because
# four of the eleven fixtures are pin-only by construction (the enum walk, and the
# two silent files).
#
# ★ THREE FILES ARE PATCHED — checker.scaly for most rows, binder.scaly for the
# LocalSymbol write and the combined-modifier refactor, ast.scaly for the slot
# itself. Every patch is dry-run against a copy of the tree before a single build is
# spent (slice 57), and the restore is proven with `cmp` and survives a kill
# (slice 58).
#
# ★★★ ITERATE AT STAGE 1 AND CONFIRM AT STAGE 2 ONCE — slice 64's rule, and it holds
# for the same reason: diagcheck is the per-row cost and it scales with the corpus
# (1 200 units against 17 969), so a row goes from ~2 s to ~50 s.
#
# Usage (nothing may edit the tree while this runs — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # stage 1, ~13 s
#   packages/tscaly/tests/controls-slice65.sh 2>&1 | tee /tmp/battery65.log
#   ...iterate the fixtures here until no row is silent without an argument...
#   TSCALY_STAGE=2 packages/tscaly/tests/run.sh       # ~9 min, ONCE
#   packages/tscaly/tests/controls-slice65.sh 2>&1 | tee /tmp/battery65-s2.log

set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.0/tscaly/checker.scaly
AST=$PKG/0.1.0/tscaly/ast.scaly
BINDER=$PKG/0.1.0/tscaly/binder.scaly
FIX=$PKG/tests/fixtures

LIBSCALY=${LIBSCALY:-/tmp/libscaly.a}
SCALYC=${SCALYC:-$REPO/scalyc/build/scalyc}

# The fixtures the PIN reads — all eleven of this slice's.
TAGFILES="
$FIX/checker_merged_declaration_export_mix.ts
$FIX/checker_merged_declaration_default_export.ts
$FIX/checker_merged_declaration_default_and_local.ts
$FIX/checker_merged_declaration_silent.ts
$FIX/checker_merged_declaration_ambient.d.ts
$FIX/checker_merged_declaration_alias.ts
$FIX/checker_namespace_merged_before_class.ts
$FIX/checker_type_alias_intrinsic.ts
$FIX/checker_enum_member_walk.ts
$FIX/checker_property_bigint_name.ts
$FIX/checker_ambient_module_nested_in_namespace.d.ts
"

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  echo "Both instruments compare against the reference dumps that run produced."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl65)

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

control() {   # $1 = label, $2 = space-separated files, $3 = python patch file, $4 = optional tag file
  echo
  echo "################################################################"
  bold "CONTROL: $1"
  local files="$2" f i=0
  for f in $files; do cp "$f" "$WORK/orig.$i"; i=$((i+1)); done
  PATCHED_ORIG=$WORK/orig.0
  PATCHED_FILE=$(echo "$files" | awk '{print $1}')
  if ! python3 "$3" $files; then
    red "the patch did not apply — the anchor moved. The row measures nothing."
    i=0; for f in $files; do cp "$WORK/orig.$i" "$f"; i=$((i+1)); done
    PATCHED_FILE=""
    return 1
  fi
  echo "  patched $files"
  if ! build_diag_bin; then
    red "the patched tree did not build — the row measures nothing:"
    tail -5 "$WORK/build.log" | sed 's/^/    /'
    i=0; for f in $files; do cp "$WORK/orig.$i" "$f"; i=$((i+1)); done
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
  PATCHED_FILE=""
  echo "  RESTORE VERIFIED   $files byte-identical"
  echo
  if [ "$rc" != 0 ]; then
    green "diagcheck RED $differing   (consistent $consistent, was $DIAG_BASE; speaking on $speaking/$diags, was $DIAG_LINES/$DIAG_DIAGS)"
  else
    echo "  diagcheck ungated — speaking on $speaking units with $diags diagnostics, was $DIAG_LINES/$DIAG_DIAGS."
  fi
  local against=${4:-$WORK/base.tags}
  local againstname="the baseline"
  [ "$against" = "$WORK/base.tags" ] || againstname="$(basename "$against" .tags)"
  if cmp -s "$against" "$WORK/ctl.tags"; then
    echo "  pin       unmoved against $againstname — all eleven fixtures answer the same tag."
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
# ★★★ getLateBoundSymbol MADE TO REPORT FOR EVERY SYMBOL. This is the only row that
# answers *is getSymbolOfDeclaration on the path at all*, and the answer is a count
# rather than an argument: everything that asks for a symbol stops. It is the
# cheapest possible statement of why a four-line function was 5 593 units deep.
old = """        if (Symbol.flags_of(symbol) & SymbolFlagsClassMember) = 0
            return symbol"""
new = """        this.record_unported("get-late-bound-symbol", 0)
        if (Symbol.flags_of(symbol) & SymbolFlagsClassMember) = 0
            return symbol"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g02.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ getMergedSymbol ANSWERING NULL. The identity is the whole of that function
# under this harness, so a row that breaks it has to break it into something else —
# and null is the shape the empty table would produce if it were consulted wrongly.
# Every caller then sees no symbol and returns: the reports vanish rather than
# changing, which is the falling-number class.
old = """    function get_merged_symbol(this, symbol: ref[Symbol]?) returns ref[Symbol]?
        symbol"""
new = """    function get_merged_symbol(this, symbol: ref[Symbol]?) returns ref[Symbol]?
        null"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g03.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE LOCAL SYMBOL WRITE REMOVED — the row that measures the slot the binder
# refused for two slices. Without it checkExportsOnMergedDeclarations falls through
# to the node's own symbol, which for an exported declaration is the EXPORT, whose
# ExportSymbol is null — so the head returns and says nothing. It patches the
# BINDER, because that is where the slot is filled.
old = """            set n.local_symbol: local
            return local"""
new = """            return local"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g04.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE PURE-LOCAL EARLY RETURN REMOVED, AND IT IS A CONDITION. `symbol.ExportSymbol
# == nil` means every declaration of this name is local, and the reference's comment
# (*a pure local symbol — no need to check anything*) invites reading it as a shortcut.
# The row asked which it was and the two corpora answered differently: SILENT over
# 1 202 units, **RED 1 over 17 972**. An ambient container makes
# effective_declaration_flags answer Export for some of a purely local symbol's
# declarations and not for others, so the intersection is not empty.
# ★★★ It is the row that justifies the stage-2 pass on its own: an ungated verdict
# carrying an ARGUMENT is worse than one carrying nothing, because the argument reads
# as evidence — and only a corpus wide enough to hold the counter-example separates
# them.
old = """            if Symbol.export_symbol_of(symbol) = null
                return
"""
new = ""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g05.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE ONCE-GUARD REMOVED. `GetDeclarationOfKind(symbol, node.Kind) != node`
# lets only the FIRST declaration of its kind run the check, and the reporting loop
# then walks every declaration — so the guard decides how many times a merge is
# reported ON, not whether. Two interfaces of one name go from two reports to four.
old = """        if Checker.declaration_of_kind(symbol, AstNode.kind_of(node)) <> node
            return
"""
new = ""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g06.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ declaration_of_kind's KIND TEST DROPPED — it answers the first declaration
# whatever its kind. That is the tempting reading of *run the check only for the
# first declaration in the list*, and it is wrong in a direction no positive fixture
# shows: `export default class C {} / namespace C {}` reports FOUR times in the
# reference, twice from the class's run and twice from the namespace's, because the
# two are different KINDS and each is the first of its own.
old = """                if AstNode.kind_of(d) = kind
                    return d"""
new = """                return d"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g07.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ getEffectiveDeclarationFlags' AMBIENT-EXPORT TERM REMOVED. Inside an ambient
# export context every declaration is exported without an `export` keyword, so the
# term is what keeps a `.d.ts` merge from looking like one export and one local.
# Take it away and the check INVENTS TS2395 wherever a declare-module body holds a
# merge — the direction that matters, because a report we make and the reference
# does not is the only thing diagcheck can see.
old = """                            if global_augmentation_body = false
                                set flags: flags | ModifierFlagsExport"""
new = """                            if global_augmentation_body = false
                                set flags: flags"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g08.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE AMBIENT BIT REMOVED FROM THE SAME FUNCTION, and it is predicted UNGATED
# with a proof: this slice's only caller asks with flagsToCheck = Export|Default, and
# the function's last line masks the result with it — so the Ambient bit cannot
# survive the return. A faithful port carries a distinction it is incapable of
# getting wrong here, and the honest thing is to say so at a row rather than to leave
# the line looking measured.
old = """                set flags: flags | ModifierFlagsAmbient
            }
        }
        flags & flags_to_check"""
new = """                set flags: flags
            }
        }
        flags & flags_to_check"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g09.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE CLASS-LIKE PARENT EXEMPTION DROPPED. The reference's comment is the claim:
# *children of classes (even ambient classes) should not be marked as ambient or
# export because those flags have no useful semantics there*. This slice reaches
# checkExportsOnMergedDeclarations only from five container arms, none of which is a
# class MEMBER, so the row is expected to move nothing — and that is a statement
# about which callers exist, not about the term.
old = """            if member_of_class_like = false
            {
                let container Checker.enclosing_container(n)"""
new = """            if true
            {
                let container Checker.enclosing_container(n)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g10.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ getEnclosingContainer STARTING AT THE NODE INSTEAD OF AT ITS PARENT. The
# reference's FindAncestor is given `node.Parent`, and the difference shows on
# exactly one kind: a ModuleDeclaration IS a container, so the walk would answer
# ITSELF and read its own ExportContext flag instead of its enclosing scope's.
old = """        var p AstNode.parent_node_of(node)
        while p <> null
        {
            if (Binder.get_container_flags(p) & ContainerFlagsIsContainer) <> 0"""
new = """        var p node
        while p <> null
        {
            if (Binder.get_container_flags(p) & ContainerFlagsIsContainer) <> 0"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g11.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE GLOBAL-AUGMENTATION-BODY EXEMPTION DROPPED. `!(IsModuleBlock(n.Parent) &&
# IsGlobalScopeAugmentation(n.Parent.Parent))` is the fourth conjunct, and it says a
# declaration in a `declare global { … }` body is NOT automatically exported even
# though the body is an ambient export context. The row measures whether this corpus
# holds such a body with a merge in it.
old = """                    if pk = KindModuleBlock
                    {
                        let grandparent AstNode.parent_node_of(parent)
                        if grandparent <> null
                        {
                            if Binder.is_global_scope_augmentation(grandparent)
                                set global_augmentation_body: true
                        }
                    }"""
new = """                    if false
                        set global_augmentation_body: true"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g12.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ getDeclarationSpaces' MODULE ARM WITHOUT ITS INSTANCE-STATE TEST — every
# namespace claims Namespace|Value. This is the row checker_merged_declaration_silent.ts
# exists for: `export class C {} / namespace C {}` is silent in the reference because
# an uninstantiated namespace occupies no value space, and with this patch the class's
# ExportValue meets the namespace's and TS2395 is invented.
old = """            if b.get_module_instance_state(node) <> ModuleInstanceStateNonInstantiated
                return DeclarationSpacesExportNamespace | DeclarationSpacesExportValue
            return DeclarationSpacesExportNamespace"""
new = """            return DeclarationSpacesExportNamespace | DeclarationSpacesExportValue"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g13.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE SAME ARM IN THE OTHER DIRECTION — a namespace never claims a value space.
# The two rows together are what makes the instance-state test a measurement: g12
# invents a report where the spaces must not meet, g13 removes one where they must.
# `export default class C {} / namespace C { export var x = 1 }` goes quiet.
old = """            if Binder.is_ambient_module(node)
                return DeclarationSpacesExportNamespace | DeclarationSpacesExportValue
            if b.get_module_instance_state(node) <> ModuleInstanceStateNonInstantiated
                return DeclarationSpacesExportNamespace | DeclarationSpacesExportValue
            return DeclarationSpacesExportNamespace"""
new = """            return DeclarationSpacesExportNamespace"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g14.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE ALIAS ARM ANSWERING SILENTLY INSTEAD OF REPORTING. resolveAlias is the one
# hole inside getDeclarationSpaces, and DeclarationSpacesNone is the answer that
# looks harmless: no space means no intersection means no report. §3.5bk's shape
# exactly — the row asks how many units of the corpus reach it.
#
# ★★★ ITS FIRST DRAFT WAS AIMED AT THE WRONG ONE OF FOUR IDENTICAL STOPS AND CAME
# BACK UNGATED. The arm has four `record_unported("resolve-alias", k)` calls — the
# export-assignment fallthrough plus the three import kinds — and the first patch
# pinned itself to the FALLTHROUGH by including `if k = KindImportEqualsDeclaration`
# as trailing context. The anchor was unique, applied cleanly, and measured a site no
# fixture reaches: checker_merged_declaration_alias.ts arrives at kind 272, the
# import-equals. **ctl.sh's slice-10 rule is that an anchor must occur once; this row
# is the reminder that occurring once is not the same as being the right one.** All
# four are removed now, so the row is about the arm rather than about one of its
# spellings.
old = """            this.record_unported("resolve-alias", k)
"""
assert s.count(old) == 4, s.count(old)
open(p, "w").write(s.replace(old, ""))
PY

cat > "$PATCHDIR/g15.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE TWO REPORTS' ORDER SWAPPED. The reporting loop asks the DEFAULT
# intersection first and the exports-and-locals one second, so a declaration in both
# gets TS2652 and not TS2395. The order is the only thing that decides which, and no
# MATCH counter can see it — only a code-comparing instrument.
old = """                    if (spaces & common_default_and_non_default) <> 0
                        this.error_on_node(name, DiagMerged_declaration_0_cannot_include_a_default_export_declaration_Consider_adding_a_separate_export_default_0_declaration_instead)
                    else
                    {
                        if (spaces & common_exports_and_locals) <> 0
                            this.error_on_node(name, DiagIndividual_declarations_in_merged_declaration_0_must_be_all_exported_or_all_local)
                    }"""
new = """                    if (spaces & common_exports_and_locals) <> 0
                        this.error_on_node(name, DiagIndividual_declarations_in_merged_declaration_0_must_be_all_exported_or_all_local)
                    else
                    {
                        if (spaces & common_default_and_non_default) <> 0
                            this.error_on_node(name, DiagMerged_declaration_0_cannot_include_a_default_export_declaration_Consider_adding_a_separate_export_default_0_declaration_instead)
                    }"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g16.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE THIRD ACCUMULATOR FED FROM THE WRONG BRANCH — a default export counted as a
# plain export. `nonDefaultExportedDeclarationSpaces` then swallows it, the default
# intersection is empty and the exports-and-locals one fires instead: same site,
# different code.
old = """                    if (effective & ModifierFlagsDefault) <> 0
                        set default_exported_spaces: default_exported_spaces | spaces
                    else
                        set exported_spaces: exported_spaces | spaces"""
new = """                    set exported_spaces: exported_spaces | spaces"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g17.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ name_of_declaration REPLACED BY THE NARROWED ACCESSOR — `AstNode.name_of`, the
# slot read, where the reference asks GetNameOfDeclaration. Slice 29 paid for this
# exact substitution once, on `export = x` twice, and the difference needs a
# declaration kind with no name SLOT among a reporting merge's declarations. The row
# says whether the corpus holds one; the substitution was refused up front either
# way (§3.5br).
old = """                let name this.name_of_declaration(d)"""
new = """                let name AstNode.name_of(d)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g18.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE TWO NAMESPACE-MERGE MESSAGES SWAPPED — TS2433 (a different FILE) for
# TS2434 (located PRIOR to). One unit is one file here, so the first can never fire
# and the second always does; the swap therefore turns every report of this pair into
# the code that is unreachable, which is the sharpest statement of what the
# unreachable branch costs if it is wired to the wrong arm.
old = """                            this.error_on_node(AstNode.name_of(node), DiagA_namespace_declaration_cannot_be_in_a_different_file_from_a_class_or_function_with_which_it_is_merged)
                        else
                        {
                            if AstNode.pos_of(node) < AstNode.pos_of(first)
                                this.error_on_node(AstNode.name_of(node), DiagA_namespace_declaration_cannot_be_located_prior_to_a_class_or_function_with_which_it_is_merged)"""
new = """                            this.error_on_node(AstNode.name_of(node), DiagA_namespace_declaration_cannot_be_located_prior_to_a_class_or_function_with_which_it_is_merged)
                        else
                        {
                            if AstNode.pos_of(node) < AstNode.pos_of(first)
                                this.error_on_node(AstNode.name_of(node), DiagA_namespace_declaration_cannot_be_in_a_different_file_from_a_class_or_function_with_which_it_is_merged)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g19.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE POSITION COMPARISON REVERSED. `node.Pos() < first.Pos()` is what makes
# TS2434 a rule about ORDER, and checker_merged_declaration_silent.ts holds the merge
# in the legal order for exactly this row: reversed, the fixture that reports goes
# quiet and the one that is silent starts reporting. A comparison is the one kind of
# term that needs a fixture on BOTH sides of it.
old = """                            if AstNode.pos_of(node) < AstNode.pos_of(first)"""
new = """                            if AstNode.pos_of(node) > AstNode.pos_of(first)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g20.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE INSTANTIATED GATE OPENED — the whole ValueModule/ambient/isInstantiatedModule
# conjunction forced true. Everything inside it then runs for a namespace that emits
# no object, and `class D {} / namespace D { … }`'s silent twin in
# checker_merged_declaration_silent.ts is joined by `export class C {} / namespace C
# {}`, whose namespace is not instantiated at all.
old = """        var instantiated false
        if value_module"""
new = """        var instantiated true
        if value_module"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g21.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ getFirstNonAmbientClassOrFunctionDeclaration ACCEPTING A BODY-LESS SIGNATURE.
# The reference wants a class, or a function declaration WITH A BODY — an overload
# signature is not something a namespace can be merged after. The row asks whether
# this corpus separates the two readings: it does so only where a namespace sits
# BETWEEN a signature and its implementation.
old = """                if k = KindFunctionDeclaration
                {
                    if Binder.node_is_missing(AstNode.body_of(d)) = false
                        set eligible: true
                }"""
new = """                if k = KindFunctionDeclaration
                    set eligible: true"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g22.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ is_global_source_file FORCED TRUE — the ambient-external-module branch then
# always takes its middle arm. `declare module "nested"` inside a namespace stops
# being *cannot be nested* and becomes the relative-name question instead, which for
# a non-relative name is silence: one report turns into another and one disappears.
old = """        if Checker.is_global_source_file(b, AstNode.parent_node_of(node))"""
new = """        if true"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g23.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE AUGMENTATION ARM TAKEN ALWAYS. `IsExternalModuleAugmentation` separates a
# module declaration that has a TARGET from one that is merely misplaced, and forcing
# it true routes every ambient module into the body check — so both reports of the
# other two arms disappear at once.
old = """        if b.is_module_augmentation_external(node)
        {
            var check_body is_global_augmentation"""
new = """        if true
        {
            var check_body is_global_augmentation"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g24.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE INTRINSIC ARITY-0 NAME TEST DROPPED — any nullary alias may be `intrinsic`.
# `type Uppercase0 = intrinsic` stops reporting while the three other illegal shapes
# still do, so the row separates the name half of the licence from the arity half.
old = """        if arity = 0
            return Checker.identifier_text_equals(name, "BuiltinIteratorReturn", 21)"""
new = """        if arity = 0
            return true"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g25.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE TWO LEGAL SHAPES SWAPPED — `BuiltinIteratorReturn` licensed at arity ONE
# and the five mapping names at arity ZERO. Every one of the six lines in
# checker_type_alias_intrinsic.ts changes its answer, in both directions at once,
# which is what makes that fixture's two LEGAL lines load-bearing: without them the
# swap would only remove reports.
old = """        if arity = 0
            return Checker.identifier_text_equals(name, "BuiltinIteratorReturn", 21)
        if arity <> 1
            return false"""
new = """        if arity = 1
            return Checker.identifier_text_equals(name, "BuiltinIteratorReturn", 21)
        if arity <> 0
            return false"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g26.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE TYPE ALIAS'S TYPE-NODE WALK REMOVED. It is the line that completes the arm,
# and everything the alias's own type says is behind it — including TS1539 in
# checker_property_bigint_name.ts, whose container had to be a type LITERAL for
# exactly this reason. The pin moves too, because the unit's tag comes from that walk.
old = """        this.check_source_element(type_node)
    }

    ; The negated condition of checkTypeAliasDeclaration's `intrinsic` report"""
new = """    }

    ; The negated condition of checkTypeAliasDeclaration's `intrinsic` report"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g27.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE ENUM'S MEMBERS WALK REMOVED — the line that forced checkEnumMember into
# this slice. Without it no enum member is ever handed to checkSourceElement, and
# checker_enum_member_walk.ts is the only instrument that can see it: the reference
# reports nothing there, so the row is a PIN row by construction.
old = """        this.check_source_elements(AstNode.member_list_of(node))
        if this.should_check_erasable_syntax(node)"""
new = """        if this.should_check_erasable_syntax(node)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g28.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ checkEnumMember's PRIVATE-IDENTIFIER REPORT MOVED TO THE NAME. The reference
# reports on the NODE under a test about its name, which reads as a mistake at the
# call site and is the specification. The row says whether the corpus holds an enum
# member with a private name at all.
old = """        if Checker.kind_or_unknown(AstNode.name_of(node)) = KindPrivateIdentifier
            this.error_on_node(node, DiagAn_enum_member_cannot_be_named_with_a_private_identifier)"""
new = """        if Checker.kind_or_unknown(AstNode.name_of(node)) = KindPrivateIdentifier
            this.error_on_node(AstNode.name_of(node), DiagAn_enum_member_cannot_be_named_with_a_private_identifier)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g29.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE VARIABLE-LIKE ALIAS BRANCH TAKEN FOR EVERY ALIAS SYMBOL — the
# `IsVariableDeclarationInitializedToRequire` term dropped. The branch RETURNS, so
# every aliased variable stops at check-alias-symbol instead of walking on to its
# type: the pin moves and the bigint report disappears with it if the property is one.
old = """            if b.is_variable_declaration_initialized_to_require(node)
            {
                this.record_unported("check-alias-symbol", AstNode.kind_of(node))
                return
            }"""
new = """            if true
            {
                this.record_unported("check-alias-symbol", AstNode.kind_of(node))
                return
            }"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g30.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE BIGINT PROPERTY-NAME REPORT REMOVED. TS1539 is the only diagnostic
# checkVariableLikeDeclaration adds below the symbol, and it is reached only through
# the alias arm's walk — so this row and g26 report the same number from two
# different distances, which is what tells a missing REPORT from a missing WALK.
old = """        if Checker.kind_or_unknown(name) = KindBigIntLiteral
            this.error_on_node(name, DiagA_bigint_literal_cannot_be_used_as_a_property_name)
"""
new = ""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

# ── the dry run ─────────────────────────────────────────────────────────────

bold "DRY RUN — every patch against a COPY of the tree"
DRY=$WORK/dry
mkdir -p "$DRY"
dry_ok=1
dry_one() {   # $1 = id, rest = files
  local id=$1; shift
  local copies="" f i=0
  for f in "$@"; do cp "$f" "$DRY/copy.$i"; copies="$copies $DRY/copy.$i"; i=$((i+1)); done
  if python3 "$PATCHDIR/$id.py" $copies 2> "$DRY/err"; then
    printf '  %s  ok\n' "$id"
  else
    red "  $id  DID NOT APPLY — $(tail -1 "$DRY/err")"
    dry_ok=0
  fi
}
for id in g01 g02 g04 g05 g06 g07 g08 g09 g10 g11 g12 g13 g14 g15 g16 g17 g18 g19 g20 g21 g22 g23 g24 g25 g26 g27 g28 g29 g30; do
  dry_one "$id" "$CHECKER"
done
dry_one g03 "$BINDER"
if [ "$dry_ok" != 1 ]; then
  red "at least one anchor is wrong. Fix them before spending the battery."
  exit 2
fi

baseline

control "g01 getLateBoundSymbol made to report for EVERY symbol"          "$CHECKER" "$PATCHDIR/g01.py"
control "g02 getMergedSymbol answering NULL"                             "$CHECKER" "$PATCHDIR/g02.py"
control "g03 the binder's LOCAL SYMBOL write removed"                    "$BINDER"  "$PATCHDIR/g03.py"
control "g04 the pure-local early return removed"                        "$CHECKER" "$PATCHDIR/g04.py"
control "g05 the once-guard removed"                                     "$CHECKER" "$PATCHDIR/g05.py"
control "g06 declaration_of_kind's KIND test dropped"                    "$CHECKER" "$PATCHDIR/g06.py"
control "g07 the ambient-EXPORT term removed"                            "$CHECKER" "$PATCHDIR/g07.py"
control "g08 the ambient BIT removed (masked out by flags_to_check)"     "$CHECKER" "$PATCHDIR/g08.py"
control "g09 the class-like parent exemption dropped"                    "$CHECKER" "$PATCHDIR/g09.py"
control "g10 enclosing_container starting AT the node"                   "$CHECKER" "$PATCHDIR/g10.py"
control "g11 the global-augmentation-body exemption dropped"             "$CHECKER" "$PATCHDIR/g11.py"
control "g12 the module arm without its instance-state test"             "$CHECKER" "$PATCHDIR/g12.py"
control "g13 the module arm never claiming a value space"                "$CHECKER" "$PATCHDIR/g13.py"
control "g14 the alias arm answering silently instead of reporting"      "$CHECKER" "$PATCHDIR/g14.py"
control "g15 the two reports' ORDER swapped"                             "$CHECKER" "$PATCHDIR/g15.py"
control "g16 a default export counted as a plain export"                 "$CHECKER" "$PATCHDIR/g16.py"
control "g17 name_of_declaration replaced by the NAME SLOT"              "$CHECKER" "$PATCHDIR/g17.py"
control "g18 the two namespace-merge messages SWAPPED"                   "$CHECKER" "$PATCHDIR/g18.py"
control "g19 the position comparison REVERSED"                           "$CHECKER" "$PATCHDIR/g19.py"
control "g20 the instantiated gate forced OPEN"                          "$CHECKER" "$PATCHDIR/g20.py"
control "g21 a body-less signature accepted as the merge target"         "$CHECKER" "$PATCHDIR/g21.py"
control "g22 is_global_source_file forced TRUE"                          "$CHECKER" "$PATCHDIR/g22.py"
control "g23 the augmentation arm taken ALWAYS"                          "$CHECKER" "$PATCHDIR/g23.py"
control "g24 the intrinsic arity-0 NAME test dropped"                    "$CHECKER" "$PATCHDIR/g24.py"
control "g25 the two legal intrinsic shapes SWAPPED"                     "$CHECKER" "$PATCHDIR/g25.py"
control "g26 the type alias's TYPE-NODE WALK removed"                    "$CHECKER" "$PATCHDIR/g26.py"
control "g27 the enum's MEMBERS WALK removed"                            "$CHECKER" "$PATCHDIR/g27.py"
control "g28 the enum member's report moved to the NAME"                 "$CHECKER" "$PATCHDIR/g28.py"
control "g29 the variable-like alias branch taken for every alias"       "$CHECKER" "$PATCHDIR/g29.py"
control "g30 the bigint property-name report removed"                    "$CHECKER" "$PATCHDIR/g30.py"

echo
echo "################################################################"
bold "RESTORED — checker.scaly and binder.scaly, byte-identical"
git -C "$REPO" diff --stat -- "$CHECKER" "$BINDER" | tail -4
