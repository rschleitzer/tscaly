#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice59.sh — the slice-59 battery: checkCollisionsForDeclarationName,
# the first head of the checker chapter that four independent arms stop at, and the
# five sub-checks it fans out into.
#
# ★★★ TWO INSTRUMENTS AGAIN, AND HERE THE SPLIT IS NOT A CHOICE. Two of the five
# sub-checks can report and three cannot: the emit format and the language version
# close them, so what those three leave behind is an unported TAG and no yardstick
# compares a tag. diagcheck therefore gates the two live checks and the two new
# reserved-name reports, and the PIN gates the three inert ones, the class-like
# arm's new checkTypeParameters call, and the three import continuations.
#
# ★★★ THE TWO CONSTANTS ARE THE SLICE, AND TWO ROWS ARE NOTHING BUT THEM.
# Checker.emit_module_format is the STUB PROGRAM's answer (ModuleKindNone) and
# Checker.module_kind is the OPTION's (ES2022); they disagree, and every live
# report of this family hangs off the first. g01 substitutes the second — the
# mistake of reading a program question off an option — and prices it; g02
# substitutes CommonJS and makes a check that is otherwise measured-and-silent
# speak.
#
# ★★ ROWS THAT ONLY REMOVE A DIAGNOSTIC ARE UNGATED ON diagcheck BY CONSTRUCTION,
# because its relation is a SUBSEQUENCE — its own header says so. Such a row is
# still a measurement when the falling count is printed, and g01, g08 and g09 are
# exactly that.
#
# ★★ THE ROWS DO NOT GO THROUGH ctl.sh, for slice 48's reason: the instruments read
# the reference dumps run.sh produced, and a filtered run would rewrite part of that
# tree. Each row builds the package and the dumper into a scratch directory, points
# the instruments at it, leaves tests/out alone, restores the source and PROVES the
# restore with `cmp`.
#
# ★ ONE FILE IS PATCHED — checker.scaly — which is what a slice inside one function
# family looks like; slice 58 needed three because its cost was spread over the ast
# and the path modules.
#
# ★ Every patch is dry-run against a COPY of the tree before the battery is spent,
# which is slice 57's lesson: an anchor that matches twice costs the whole run.
#
# Usage (nothing may edit the tree while this runs — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # the artifact tree, first
#   packages/tscaly/tests/controls-slice59.sh 2>&1 | tee /tmp/battery59.log

set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.0/tscaly/checker.scaly
AST=$PKG/0.1.0/tscaly/ast.scaly
TSPATH=$PKG/0.1.0/tscaly/tspath.scaly
FIX=$PKG/tests/fixtures

LIBSCALY=${LIBSCALY:-/tmp/libscaly.a}
SCALYC=${SCALYC:-$REPO/scalyc/build/scalyc}

# The fixtures the PIN reads. EIGHT, and five of them exist for no other purpose:
# three of the five sub-checks of checkCollisionsForDeclarationName are inert under
# this harness and produce a TAG rather than a diagnostic, and the class-like arm's
# new checkTypeParameters call is a tag as well. One shape per file, because
# record_unported keeps the FIRST report (slice 56's *a fixture that cannot be first
# is not a witness*) — which is why Promise, WeakMap and Reflect are three files.
TAGFILES="
$FIX/checker_collision_promise.ts
$FIX/checker_collision_weak_map.ts
$FIX/checker_collision_reflect.ts
$FIX/checker_class_type_parameters.ts
$FIX/checker_import_clause_only.ts
$FIX/checker_import_namespace_binding.ts
$FIX/checker_import_named_binding.ts
$FIX/checker_collision_require_exports.ts
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
  "$SCALYC" -c --no-prelude -o "$WORK/pkg.o" "$PKG/0.1.0/tscaly.scaly" > "$WORK/build.log" 2>&1 || return 1
  "$SCALYC" -c -o "$WORK/types.o" "$PKG/0.1.0/tscaly_types.scaly" >> "$WORK/build.log" 2>&1 || return 1
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
  echo "  the PIN — the fixtures' unported tags on the unpatched tree:"
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
    echo "  pin       unmoved — all eight fixtures answer the same tag."
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
# copy of the tree before a single build is spent.

cat > "$PATCHDIR/g01.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE NAIVE READING OF A PROGRAM QUESTION: take the emit format from the
# OPTION (ES2022) instead of from the stub program (None). Both live checks of the
# family then fall silent — the require/exports check returns at `>= ES2015` and
# checkClassNameCollisionWithObject at `< ES2015` — so this row is ungated on
# diagcheck by construction and its whole content is the falling count.
old = "        set c.emit_module_format: ModuleKindNone"
new = "        set c.emit_module_format: ModuleKindES2022"
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g02.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE OTHER SUBSTITUTION, and it makes the measured-and-silent check SPEAK:
# checkCollisionWithGlobalObjectInGeneratedCode's last term is `format ==
# ModuleKindCommonJS`. Every step in front of it is ported and taken, so this row
# is what proves those five steps rather than the last one.
old = "        set c.emit_module_format: ModuleKindNone"
new = "        set c.emit_module_format: ModuleKindCommonJS"
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g03.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE TARGET LOWERED BELOW ES2017, which opens ALL THREE inert checks at once:
# the Promise guard (`>= ES2017`) stops returning and the two record… guards
# (`<= ES2021`) start registering. Three fixtures change their tag and no
# diagnostic moves — the reports behind those guards are record_unported, which
# produces no C line — so this row is PIN-ONLY by construction.
old = "        set c.language_version: ScriptTargetES2025"
new = "        set c.language_version: ScriptTargetES2017 - 1"
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g04.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE SAME LEVER ONE STEP HIGHER, and the pair is the measurement: at ES2021 the
# Promise guard is still closed (`>= ES2017` holds) while the two `<= ES2021` ones
# open. So checker_collision_promise.ts must stay UNMOVED here and move in g03 —
# which is the only thing that separates the three guards from one guard.
old = "        set c.language_version: ScriptTargetES2025"
new = "        set c.language_version: ScriptTargetES2021"
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g05.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ needCollisionCheckForIdentifier's AMBIENT arm dropped. An ambient declaration
# emits nothing, so it cannot collide with an emitted name; without the arm
# `declare class require {}` in a module reports TS2441.
old = """        if (AstNode.flags_of(node) & NodeFlagsAmbient) <> 0
            return false
        var is_import_form false"""
new = """        var is_import_form false"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g06.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE HEAD'S OWN AMBIENT TEST, one function away from g05's and about a
# different thing: checkClassNameCollisionWithObject has no ambient test of its
# own, so this `if` is the only reason `declare class Object {}` is silent.
old = """            if (AstNode.flags_of(node) & NodeFlagsAmbient) = 0
                this.check_class_name_collision_with_object(name)"""
new = """            this.check_class_name_collision_with_object(name)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g07.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★ The two reserved-name CODES swapped. Same spans, same order, same count — the
# cheapest demonstration that the head's two branches were not written the other
# way round.
old = """            this.check_type_name_is_reserved(name, DiagClass_name_cannot_be_0)"""
new = """            this.check_type_name_is_reserved(name, DiagEnum_name_cannot_be_0)"""
assert s.count(old) == 1, s.count(old)
s = s.replace(old, new)
old2 = """            this.check_type_name_is_reserved(name, DiagEnum_name_cannot_be_0)
    }"""
new2 = """            this.check_type_name_is_reserved(name, DiagClass_name_cannot_be_0)
    }"""
assert s.count(old2) == 1, s.count(old2)
open(p, "w").write(s.replace(old2, new2))
PY

cat > "$PATCHDIR/g08.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★ HALF OF THE DISJUNCTION: the check is asked of `require` AND of `exports`, and
# dropping the second loses exactly the declarations named after it. Ungated on
# diagcheck (a removal) and the count is the row.
old = """        if Checker.need_collision_check_for_identifier(node, name, "exports", 7)
            set wanted: true
"""
new = ""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g09.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ GetDeclarationContainer's ImportClause arm. Without it the container of a
# default import binding is the import DECLARATION rather than the SourceFile, and
# the collision report for `import require from "m"` disappears — which is what
# says the six transparent kinds are a list and not decoration.
old = """            if k = KindImportClause
                set transparent: true"""
new = """            if k = KindSourceFile
                set transparent: false"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g10.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE MODULE-INSTANCE-STATE TEST INVERTED, which is a row in both directions at
# once: an empty `namespace exports {}` invents TS2441 and the instantiated
# `namespace require { … }` loses its own.
old = """        if wanted = false
            return
        if AstNode.kind_of(node) = KindModuleDeclaration
        {
            if b.get_module_instance_state(node) <> ModuleInstanceStateInstantiated"""
new = """        if wanted = false
            return
        if AstNode.kind_of(node) = KindModuleDeclaration
        {
            if b.get_module_instance_state(node) = ModuleInstanceStateInstantiated"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g11.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE CONTAINER TEST DROPPED. A class inside a namespace then reports as though
# it were at the top level of the file — the third declaration of
# checker_collision_require_exports.ts is the only witness this suite has for that
# term.
old = """        if Checker.kind_or_unknown(parent) <> KindSourceFile
            return
        if b.is_external_or_common_js_module() = false
            return
        this.error_on_node(name, DiagDuplicate_identifier_0_Compiler_reserves_name_1_in_top_level_scope_of_a_module)"""
new = """        if 1 = 0
            return
        if b.is_external_or_common_js_module() = false
            return
        this.error_on_node(name, DiagDuplicate_identifier_0_Compiler_reserves_name_1_in_top_level_scope_of_a_module)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g12.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE MODULE-NESS TEST DROPPED — the same five-line anchor as g11 with the other
# term broken (four lines matched TWICE, because the global-object check repeats
# them; the error line is what makes the anchor the require check's): a SCRIPT emits no require/exports of its own, so
# checker_collision_require_script.ts is silent today and speaks twice without this
# term.
old = """        if Checker.kind_or_unknown(parent) <> KindSourceFile
            return
        if b.is_external_or_common_js_module() = false
            return
        this.error_on_node(name, DiagDuplicate_identifier_0_Compiler_reserves_name_1_in_top_level_scope_of_a_module)"""
new = """        if Checker.kind_or_unknown(parent) <> KindSourceFile
            return
        if 1 = 0
            return
        this.error_on_node(name, DiagDuplicate_identifier_0_Compiler_reserves_name_1_in_top_level_scope_of_a_module)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g13.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE TYPE-ONLY ARM DROPPED. `import type exports from "m"` erases and cannot
# collide; without this arm it reports. The three kinds the arm asks about are
# exactly the three checkImportBinding is handed, so this is the only shape that
# can measure it.
old = """        if is_import_form
        {
            if Checker.is_type_only_import_or_export_declaration(node)
                return false
        }
"""
new = ""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g14.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE NAMESPACE ARM OF THE CLAUSE BRANCH REMOVED, so `import * as ns from "m"`
# takes the NAMED path and asks the resolver instead of binding. No diagnostic
# moves — both continuations stop — and the tag is the whole witness.
old = """                        if AstNode.kind_of(named_bindings) = KindNamespaceImport
                            this.check_import_binding(named_bindings)
                        if AstNode.kind_of(named_bindings) <> KindNamespaceImport
                            this.record_unported("resolve-external-module-name", AstNode.kind_of(node))"""
new = """                        this.record_unported("resolve-external-module-name", AstNode.kind_of(node))"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g15.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE DEFAULT-IMPORT TEST DROPPED: `importClause.Name() != nil` is what keeps a
# clause with no default name out of checkImportBinding, so without it `import { a }
# from "m"` binds the CLAUSE and its tag stops naming the resolver.
old = """                    if AstNode.name_of(import_clause) <> null
                        this.check_import_binding(import_clause)"""
new = """                    this.check_import_binding(import_clause)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g16.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE KEYWORD TEST INVERTED. TS1540 is the report this slice unblocked, and the
# inversion says it about every `namespace N {}` in the corpus instead of about
# every `module N {}` — the loudest row of the battery.
old = "            if AstNode.module_keyword_of(node) = KindModuleKeyword"
new = "            if AstNode.module_keyword_of(node) <> KindModuleKeyword"
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g17.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE CLASS-LIKE ARM'S SECOND NEW CALL REMOVED. checkTypeParameters reports from
# inside its loop, so only a GENERIC class can see this: its tag falls back to
# checkExportsOnMergedDeclarations and a plain class is unaffected.
old = """        this.check_collisions_for_declaration_name(node, AstNode.name_of(node))
        this.check_type_parameters(AstNode.type_parameters_of(node))
        this.record_unported("check-exports-on-merged-declarations", AstNode.kind_of(node))"""
new = """        this.check_collisions_for_declaration_name(node, AstNode.name_of(node))
        this.record_unported("check-exports-on-merged-declarations", AstNode.kind_of(node))"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

# ── the dry run ─────────────────────────────────────────────────────────────

bold "DRY RUN — every patch against a COPY of the tree"
DRY=$WORK/dry
mkdir -p "$DRY"
dry_ok=1
for id in g01 g02 g03 g04 g05 g06 g07 g08 g09 g10 g11 g12 g13 g14 g15 g16 g17; do
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

control "g01 emit_module_format := ES2022  (the option's value, not the program's)" "$CHECKER" "$PATCHDIR/g01.py"
control "g02 emit_module_format := CommonJS"                          "$CHECKER" "$PATCHDIR/g02.py"
control "g03 language_version := ES2016  (all three inert guards open)" "$CHECKER" "$PATCHDIR/g03.py"
control "g04 language_version := ES2021  (only the two record… guards)" "$CHECKER" "$PATCHDIR/g04.py"
control "g05 needCollisionCheckForIdentifier's ambient arm dropped"    "$CHECKER" "$PATCHDIR/g05.py"
control "g06 the head's ambient test around class-Object dropped"      "$CHECKER" "$PATCHDIR/g06.py"
control "g07 the two reserved-name CODES swapped"                      "$CHECKER" "$PATCHDIR/g07.py"
control "g08 the 'exports' half of the disjunction dropped"            "$CHECKER" "$PATCHDIR/g08.py"
control "g09 GetDeclarationContainer loses its ImportClause arm"        "$CHECKER" "$PATCHDIR/g09.py"
control "g10 the module-instance-state test INVERTED"                  "$CHECKER" "$PATCHDIR/g10.py"
control "g11 the SourceFile-container test dropped"                    "$CHECKER" "$PATCHDIR/g11.py"
control "g12 the module-ness test dropped"                             "$CHECKER" "$PATCHDIR/g12.py"
control "g13 the type-only arm dropped"                                "$CHECKER" "$PATCHDIR/g13.py"
control "g14 the namespace arm of the clause branch removed"           "$CHECKER" "$PATCHDIR/g14.py"
control "g15 the default-import name test dropped"                     "$CHECKER" "$PATCHDIR/g15.py"
control "g16 TS1540's keyword test INVERTED"                           "$CHECKER" "$PATCHDIR/g16.py"
control "g17 the class-like arm's checkTypeParameters call removed"    "$CHECKER" "$PATCHDIR/g17.py"

echo
echo "################################################################"
bold "RESTORED — checker.scaly, byte-identical"
git -C "$REPO" diff --stat -- "$CHECKER" | tail -3
