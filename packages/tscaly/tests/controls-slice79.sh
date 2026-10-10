#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice79.sh — the slice-79 battery: THE NAME RESOLVER, and the price of
# the one caller it is safe to wire.
#
# ★★★ THE SLICE'S PRODUCT IS A DIAGNOSTIC AND A REACHABILITY CLAIM, so the battery
# has to answer two questions with two instruments. The report half is DIAGCHECK's
# in both directions: breaking a guard of the caller INVENTS a TS2481 (which a
# subsequence catches) and breaking the WALK loses one (which it does not) — so the
# DIAGPIN over the nine shadow fixtures is what sees the losing kind.
#
# ★★★ THE SECOND QUESTION IS THE ONE WORTH THE BATTERY: HOW MUCH OF A 350-LINE WALK
# CAN ONE CALLER SEE? checkVarDeclaredNamesNotShadowed resolves the var's OWN name,
# and the var's own function/module/source-file container holds it — so the walk
# stops at or before that container and EVERY switch arm, the whole function-like
# useResult block, the conditional-type arm and the const-assertion exit are
# unreachable from here. g15 through g19 are that claim built rather than asserted:
# each one breaks a mechanism that a reader would expect to matter, and each comes
# back with nothing moving. ★A battery that only broke the reachable sixty lines
# would have called the other three hundred tested.
#
# ★★ AND THE UNREACHABILITY IS A PROPERTY OF THE CALLER, NOT OF THE PORT, which is
# why the arms are ported whole: a scope chain cannot be ported as a prefix — a
# missing arm is a WRONG answer for the next caller, not a missing one, and it is
# silent. See resolve_name's header.
#
# ★★ READING THE STOPGATE ON A ROW THAT CHANGES A TAG: its counts are then
# contaminated, because stops.sh compares against the UNPORTED line the artifact
# tree recorded with the BASELINE binary. Read `matched` first — below the unit
# total the row moved a tag. The clean before/after came from two full run.sh +
# stops.sh passes.
#
# ★★★ ITERATE AT STAGE 1 AND CONFIRM AT STAGE 2 ONCE — slice 64's rule. The
# recorded verdicts are stage 1's.
#
# Usage (nothing may edit the tree while this runs — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # stage 1, ~25 s
#   packages/tscaly/tests/controls-slice79.sh 2>&1 | tee /tmp/battery79.log

set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.2/tscaly/checker.scaly
FIX=$PKG/tests/fixtures

. packages/tscaly/tests/toolchain.sh || exit 2

# ★ ONE MECHANISM PER FILE (slice 72's rule): the tagpin is first-wins, so a fixture
# naming two mechanisms is a fixture nobody can read a red row off.
#
# The first two REPORT — one through the container-kind arms and one through the
# path that finds no container at all. The next four are silent for four different
# reasons, one per namesShareScope arm plus the catch clause. The last three are
# slice 76's, whose TAGS this slice moved and which therefore price the premise.
PINFILES="
$FIX/checker_resolve_name_shadow_block.ts
$FIX/checker_resolve_name_shadow_for_of.ts
$FIX/checker_resolve_name_shares_scope.ts
$FIX/checker_resolve_name_module_block.ts
$FIX/checker_resolve_name_module_file.ts
$FIX/checker_resolve_name_catch_shadow.ts
$FIX/checker_var_shadow_var.ts
$FIX/checker_var_shadow_let_inert.ts
$FIX/checker_var_shadow_catch_inert.ts
"
red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl79)

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
  clang -o "$WORK/tscaly_types" "$WORK/types.o" "$WORK/pkg.o" "$LIBSCALY" -lm >> "$WORK/build.log" 2>&1
}

# The DIAGPIN: the C section of each pin file, one line each. `--diags` rather than
# the dump, because most of these units stop somewhere and the dump prints nothing
# for such a unit (TypeDump.emit's own note).
#
# ★ Every line was checked against the reference's own C section before this battery
# ran: all nine are EQUAL to it — the two reporting fixtures at one TS2481 apiece
# and the seven silent ones at empty. That is stronger than a subsequence and it is
# what makes a LOST report visible here.
diags_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$("$WORK/tscaly_types" --diags "$f" 2>/dev/null | tr '\n' '|')"
  done
}

# The TAGPIN: the first unported tag of each fixture, read off the DUMP the way the
# artifact tree records it.
tags_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$("$WORK/tscaly_types" "$f" 2>/dev/null | grep '^UNPORTED ' | head -1 | cut -d' ' -f3-)"
  done
}

# The STOPGATE: stops.sh's internal agreement plus the two counts it prints. The
# EVENT count is the sensitive column for the premise row — the slice took the
# corpus from 8 177 stop events to 8 007, all of it the emptied `resolve-name` row.
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

DIAG_BASE=""; DIAG_LINES=""; DIAG_DIAGS=""; STOP_BASE=""

baseline() {
  echo "################################################################"
  bold "BASELINE — three instruments"
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
  STOP_BASE=$(stopgate)
  echo
  echo "  the DIAGPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.diags"
  echo
  echo "  the TAGPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.tags"
  echo
  echo "  BASELINE   diagcheck $DIAG_BASE consistent, $DIAG_LINES speaking, $DIAG_DIAGS diagnostics"
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
  local consistent differing speaking diags stop
  consistent=$(sed -n 's/^  consistent  *\([0-9]*\)$/\1/p' "$WORK/ctl.diag")
  differing=$(sed -n 's/^  differing  *\([0-9]*\)$/\1/p' "$WORK/ctl.diag")
  speaking=$(sed -n 's/^  units we speak on  *\([0-9]*\).*$/\1/p' "$WORK/ctl.diag")
  diags=$(sed -n 's/^.*(\([0-9]*\) diagnostics.*$/\1/p' "$WORK/ctl.diag")
  tags_of > "$WORK/ctl.tags"
  diags_of > "$WORK/ctl.diags"
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
  if [ "$rc" != 0 ]; then
    green "diagcheck RED $differing   (consistent $consistent, was $DIAG_BASE; speaking on $speaking/$diags, was $DIAG_LINES/$DIAG_DIAGS)"
    moved=1
  else
    echo "  diagcheck ungated — speaking on $speaking units with $diags diagnostics, was $DIAG_LINES/$DIAG_DIAGS."
  fi
  if cmp -s "$WORK/base.diags" "$WORK/ctl.diags"; then
    echo "  diagpin   unmoved — all nine pin files answer the same C section."
  else
    green "diagpin   RED"
    diff "$WORK/base.diags" "$WORK/ctl.diags" | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.tags" "$WORK/ctl.tags"; then
    echo "  tagpin    unmoved — all nine fixtures answer the same tag."
  else
    green "tagpin    RED"
    diff "$WORK/base.tags" "$WORK/ctl.tags" | sed 's/^/    /'
    moved=1
  fi
  if [ "$stop" = "$STOP_BASE" ]; then
    echo "  stopgate  unmoved — $stop"
  else
    green "stopgate  MOVED   $STOP_BASE -> $stop   (matched units speaking events other)"
    moved=1
  fi
  if [ "$moved" = 0 ]; then
    if [ "$speaking" != "$DIAG_LINES" ] || [ "$diags" != "$DIAG_DIAGS" ]; then
      echo "  ungated on all three, WITH A NUMBER: $DIAG_LINES/$DIAG_DIAGS -> $speaking/$diags."
    else
      red "UNGATED ON ALL THREE AND NOTHING MOVED AT ALL."
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
# copy of the tree before a single build is spent (slice 57).

cat > "$PATCHDIR/g01.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE PREMISE ROW: the slice reverted at its call site — the `resolve-name` stop
# back where slice 76 left it. PREDICTION: diagpin RED on the two reporting fixtures
# (they lose their TS2481), tagpin RED on those two and on the three slice-76 files
# whose tag this slice moved, diagcheck ungated at a LOSS, stopgate moved by the
# whole slice.
old = """        let name AstNode.name_of(node)
        if Checker.kind_or_unknown(name) <> KindIdentifier
            return"""
new = """        this.record_unported("resolve-name", AstNode.kind_of(node))
        let name AstNode.name_of(node)
        if Checker.kind_or_unknown(name) <> KindIdentifier
            return
        return"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g02.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The IDENTITY test `localDeclarationSymbol != symbol`. PREDICTION: ungated, and the
# number is the row's content — a var resolving to its own symbol is
# FunctionScopedVariable, so the BlockScopedVariable test one line down finishes
# what this one would have. Slice 76's g02/g04 finding, one function on.
old = """        if lds = sym
            return
"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, "", 1))
PY

cat > "$PATCHDIR/g03.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The BlockScopedVariable test on the resolved symbol. PREDICTION: ungated — the
# node-flags test below it is the second spelling of the same question and catches
# everything this lets through EXCEPT a catch clause, which g04 measures.
old = """        if (Symbol.flags_of(lds) & SymbolFlagsBlockScopedVariable) = 0
            return
"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, "", 1))
PY

cat > "$PATCHDIR/g04.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ getDeclarationNodeFlagsFromSymbol, the test that keeps a CATCH VARIABLE out.
# PREDICTION: diagcheck RED on checker_resolve_name_catch_shadow.ts — a catch
# variable is BlockScopedVariable and is NOT in a VariableDeclarationList, so
# `container` stays null, namesShareScope is false and a TS2481 is INVENTED.
old = """        if (Checker.declaration_node_flags_from_symbol(lds) & NodeFlagsBlockScoped) = 0
            return
"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, "", 1))
PY

cat > "$PATCHDIR/g05.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# namesShareScope's BLOCK arm — a block whose parent is function-like. PREDICTION:
# diagcheck RED on checker_resolve_name_shares_scope.ts alone.
old = """            if ck = KindBlock
            {
                if AstNode.is_function_like(AstNode.parent_node_of(c))
                    set names_share_scope: true
            }
"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, "", 1))
PY

cat > "$PATCHDIR/g06.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# namesShareScope's MODULE BLOCK arm. PREDICTION: diagcheck RED on
# checker_resolve_name_module_block.ts alone.
old = """            if ck = KindModuleBlock
                set names_share_scope: true
"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, "", 1))
PY

cat > "$PATCHDIR/g07.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# namesShareScope's SOURCE FILE arm. PREDICTION: diagcheck RED on
# checker_resolve_name_module_file.ts alone — and only a MODULE can reach it, since
# a script file's own locals are skipped by the walk.
old = """            if ck = KindSourceFile
                set names_share_scope: true
"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, "", 1))
PY

cat > "$PATCHDIR/g08.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# namesShareScope's MODULE DECLARATION arm. PREDICTION: UNGATED, and the argument is
# structural rather than about the corpus — `container` is a VariableStatement's
# parent, which is a Block, a ModuleBlock, a SourceFile or a CaseBlock and never a
# ModuleDeclaration. The arm is the reference's and is transcribed for that reason.
old = """            if ck = KindModuleDeclaration
                set names_share_scope: true
"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, "", 1))
PY

cat > "$PATCHDIR/g09.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The whole CONTAINER computation, forced to null — the `IsVariableStatement` test
# and the grandparent read together. PREDICTION: diagcheck RED on all four silent
# shadow fixtures at once, which is the row that shows the container walk and the
# kind arms are one mechanism seen from two sides (g05-g08 break the arms, this
# breaks their input).
old = """        if var_decl_list <> null
        {
            let p AstNode.parent_node_of(var_decl_list)
            if Checker.kind_or_unknown(p) = KindVariableStatement
            {
                let pp AstNode.parent_node_of(p)
                if pp <> null
                    set container: pp
            }
        }
"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, "", 1))
PY

cat > "$PATCHDIR/g10.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE is_global_source_file SKIP DROPPED — the walk searches a SCRIPT file's own
# locals, which upstream has merged into the globals table. PREDICTION: UNGATED, and
# the argument is the sharp one of this battery: the only thing those locals can
# contribute is a TOP-LEVEL declaration, and a top-level container is exactly what
# makes namesShareScope true. So the skip cannot change this caller's answer either
# way — which is half of why the missing globals table is not a stop.
old = "                if Checker.is_global_source_file(this.b, l) = false"
new = "                if true"
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g11.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE WALK DOES NOT ASCEND: one container only. PREDICTION: diagpin RED on both
# reporting fixtures (their `let` is two containers up), diagcheck ungated at a LOSS.
# It is the row that prices the SCOPE CHAIN as opposed to the lookup.
old = """            set last_location: l
            set loc: AstNode.parent_node_of(l)
        }"""
new = """            set last_location: l
            set loc: null
        }"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g12.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# lookup_symbol's MEANING test — getSymbol answering any symbol under the name.
# PREDICTION: ungated with a number at most. A hit of the wrong meaning is a
# function, class or alias, and the two block-scoped tests in the caller finish it.
old = """        if (Symbol.flags_of(symbol) & meaning) <> 0
            return symbol
"""
new = """        return symbol
"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g13.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# getMergedSymbol bypassed inside the lookup. PREDICTION: UNGATED, and it is a
# re-measurement of that function's own claim — `c.mergedSymbols` has no writer in
# this port, so the call is the identity (see get_merged_symbol's header).
old = "        let found this.get_merged_symbol(SymbolTable.get(symbols, name_data, name_len))"
new = "        let found SymbolTable.get(symbols, name_data, name_len)"
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g14.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE ALIAS STOP REMOVED — the one stop inside the walk answers null silently
# instead. PREDICTION: ungated with NOTHING moving, and that is a MEASUREMENT of an
# empty population: `get-symbol-flags` does not appear anywhere in the stage-1 stop
# log, because reaching it needs an import and a variable that share a name. The
# stop is kept for the direction it protects, not for a corpus unit.
old = """        if (Symbol.flags_of(symbol) & SymbolFlagsAlias) <> 0
            this.record_unported("get-symbol-flags", Symbol.flags_of(symbol))
"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, "", 1))
PY

cat > "$PATCHDIR/g15.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE FUNCTION-LIKE useResult BLOCK FORCED ON: every hit inside a function-like
# container is REJECTED. PREDICTION: UNGATED WITH NOTHING MOVING, and it is the
# reachability claim built rather than asserted — this caller resolves the var's own
# name and the var's own container holds it, so `lastLocation` is that container's
# BODY whenever the walk reaches a function at all, and the block's guard is false.
old = "                        var in_function_like false"
new = "                        var in_function_like true"
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g16.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE WHOLE CONTAINER SWITCH SHORT-CIRCUITED — the module, enum, class,
# heritage, computed-name, `arguments`, decorator, infer-type and export-specifier
# arms all skipped, in one row. PREDICTION: UNGATED WITH NOTHING MOVING, for g15's
# reason: the walk never reaches a container the switch has an arm for, because the
# locals lookup one level up has already answered. ★Nineteen arms priced by one row
# rather than nineteen, because a row per arm would spend fifteen minutes proving
# one fact nineteen times.
old = """            let k AstNode.kind_of(l)
            var module_like false"""
new = """            let k 0 - 1
            var module_like false"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g17.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# use_outer_variable_scope_in_parameter forced TRUE at its own first line — i.e. the
# reduction's answer without its guard. PREDICTION: UNGATED, because its only caller
# is inside the block g15 proves unreachable. ★It is a separate row from g15 so that
# the reduced form and the block that calls it are not one verdict: the day a second
# caller arrives, this row is the one that starts to bite.
old = """        if AstNode.kind_of(last_location) <> KindParameter
            return false"""
new = """        if AstNode.kind_of(last_location) <> KindParameter
            return true"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g18.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The `const` in an `as const` early exit. PREDICTION: UNGATED — a var named `const`
# cannot be written, so the only way in is a caller resolving the literal name
# `const`, which is checkAssertionWorker's and not this one's.
old = """            if name_is_const
            {
                ; `const` in an `as const` has no symbol and issues no error,
                ; because there is no actual lookup of the type.
                if Checker.is_const_assertion(l)
                    return null
            }
"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, "", 1))
PY

cat > "$PATCHDIR/g19.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The module/enum NAME skip. PREDICTION: UNGATED — reaching it needs lastLocation to
# BE a namespace's or an enum's name node, i.e. a caller that starts inside one, and
# a `var` is never a name.
old = """            if Checker.is_module_or_enum_declaration(l)
            {
                if last_location <> null
                {
                    if AstNode.name_of(l) = last_location
                    {"""
new = """            if false
            {
                if last_location <> null
                {
                    if AstNode.name_of(l) = last_location
                    {"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

# ── the dry run ─────────────────────────────────────────────────────────────
bold "DRY RUN — every patch against a copy of the tree"
DRY=$WORK/dry
for g in g01 g02 g03 g04 g05 g06 g07 g08 g09 g10 g11 g12 g13 g14 g15 g16 g17 g18 g19; do
  rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
  if python3 "$PATCHDIR/$g.py" "$DRY/f.scaly" >/dev/null 2>&1; then
    echo "  $g applies"
  else
    red "  $g DOES NOT APPLY — its anchor has moved."; exit 2
  fi
done
rm -rf "$DRY"

baseline

control "g01 the resolve-name stop back (the premise)"                    "$CHECKER" "$PATCHDIR/g01.py"
control "g02 the identity test localDeclarationSymbol != symbol dropped"  "$CHECKER" "$PATCHDIR/g02.py"
control "g03 the BlockScopedVariable test dropped"                        "$CHECKER" "$PATCHDIR/g03.py"
control "g04 getDeclarationNodeFlagsFromSymbol dropped (the catch clause)" "$CHECKER" "$PATCHDIR/g04.py"
control "g05 namesShareScope: the Block arm dropped"                      "$CHECKER" "$PATCHDIR/g05.py"
control "g06 namesShareScope: the ModuleBlock arm dropped"                "$CHECKER" "$PATCHDIR/g06.py"
control "g07 namesShareScope: the SourceFile arm dropped"                 "$CHECKER" "$PATCHDIR/g07.py"
control "g08 namesShareScope: the ModuleDeclaration arm dropped"          "$CHECKER" "$PATCHDIR/g08.py"
control "g09 the container computation forced to null"                    "$CHECKER" "$PATCHDIR/g09.py"
control "g10 the is_global_source_file skip dropped"                      "$CHECKER" "$PATCHDIR/g10.py"
control "g11 the walk does not ascend (one container only)"               "$CHECKER" "$PATCHDIR/g11.py"
control "g12 lookup_symbol: the meaning test dropped"                     "$CHECKER" "$PATCHDIR/g12.py"
control "g13 lookup_symbol: getMergedSymbol bypassed"                     "$CHECKER" "$PATCHDIR/g13.py"
control "g14 lookup_symbol: the alias stop removed"                       "$CHECKER" "$PATCHDIR/g14.py"
control "g15 the function-like useResult block forced ON"                 "$CHECKER" "$PATCHDIR/g15.py"
control "g16 the whole container switch short-circuited"                  "$CHECKER" "$PATCHDIR/g16.py"
control "g17 use_outer_variable_scope_in_parameter forced true"           "$CHECKER" "$PATCHDIR/g17.py"
control "g18 the as-const early exit dropped"                             "$CHECKER" "$PATCHDIR/g18.py"
control "g19 the module/enum NAME skip dropped"                           "$CHECKER" "$PATCHDIR/g19.py"

echo
echo "################################################################"
bold "DONE — read every row against its PREDICTION, not against its colour."
