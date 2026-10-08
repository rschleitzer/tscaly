#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice91.sh — the slice-91 battery: THE IDENTIFIER, and the three walls
# behind it.
#
# ★★★ THE ROW THIS SLICE OPENS WAS HELD BY ONE ARGUMENT AND THE ARGUMENT WAS TRUE.
# Slice 79 wired resolveName's one safe caller and wrote that checkIdentifier could
# not be the second, because `getResolvedSymbol` passes a nameNotFoundMessage and a
# MISS would report TS2304 once per lib name. What this slice changes is not the
# argument but the CONSEQUENCE: the miss is a STOP. h02 and h04 are the two halves
# of that — h02 removes the message, h04 restores slice 79's stop — and between
# them they price both readings.
#
# ★★★ HALF THIS BATTERY MEASURES THINGS THAT ARE NOT THERE, AND THAT IS THE POINT.
# Three of resolveName's four in-loop reports are UNREACHABLE from a value caller
# (the meaning mask), block 2 of onSuccessfullyResolvedSymbol is decidable with no
# INPUT (its symbol lives in the globals table), and checkIdentifier's first line
# redirects a node kind that never arrives. Each of those has a row, each row is
# predicted UNGATED, and the prediction is the measurement — §3.5be's answer to a
# chapter ported past what the corpus can see.
#
# ★★★ ITERATE AT STAGE 1 AND CONFIRM AT STAGE 2 ONCE — slice 64's rule. The
# recorded verdicts are stage 1's.
#
# Usage (nothing may edit the tree while this runs, and no second harness may own
# tests/out — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # stage 1
#   packages/tscaly/tests/controls-slice91.sh 2>&1 | tee /tmp/battery91.log
#
set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.1/tscaly/checker.scaly
AST=$PKG/0.1.1/tscaly/ast.scaly
PARSER=$PKG/0.1.1/tscaly/parser.scaly
FIX=$PKG/tests/fixtures

. packages/tscaly/tests/toolchain.sh || exit 2

# ★ ONE MECHANISM PER FILE (slice 72's rule). Nine files, and the set is the set
# that can ANSWER the claims rather than the set this slice wrote: eight are its own
# and the eighth is slice 90's `checker_binary_null_operand.ts`, kept because it is
# the only pin file whose identifiers are all in a SCRIPT file's top level — i.e.
# the only one that witnesses the globals wall rather than stepping over it.
PINFILES="
$FIX/checker_identifier_assign_to_nonvariable.ts
$FIX/checker_identifier_assign_to_readonly.ts
$FIX/checker_identifier_assign_compound.ts
$FIX/checker_identifier_arguments.ts
$FIX/checker_identifier_block_scoped_use.ts
$FIX/checker_identifier_parameter_self_reference.ts
$FIX/checker_identifier_resolver_reports.ts
$FIX/checker_identifier_umd_global.ts
$FIX/checker_binary_null_operand.ts
"
red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl91)

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
  "$SCALYC" -c --no-prelude -o "$WORK/pkg.o" "$PKG/0.1.1/tscaly.scaly" > "$WORK/build.log" 2>&1 || return 1
  "$SCALYC" -c -o "$WORK/types.o" "$PKG/0.1.1/tscaly_types.scaly" >> "$WORK/build.log" 2>&1 || return 1
  clang -o "$WORK/tscaly_types" "$WORK/types.o" "$WORK/pkg.o" "$LIBSCALY" -lm >> "$WORK/build.log" 2>&1
}

diags_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$("$WORK/tscaly_types" --diags "$f" 2>/dev/null | tr '\n' '|')"
  done
}

tags_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$("$WORK/tscaly_types" "$f" 2>/dev/null | grep '^UNPORTED ' | head -1 | cut -d' ' -f3-)"
  done
}

stops_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$("$WORK/tscaly_types" --stops "$f" 2>/dev/null | tr '\n' '|')"
  done
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

DIAG_BASE=""; DIAG_LINES=""; DIAG_DIAGS=""; STOP_BASE=""

baseline() {
  echo "################################################################"
  bold "BASELINE — five instruments"
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
  stops_of > "$WORK/base.stops"
  STOP_BASE=$(stopgate)
  echo
  echo "  the STOPPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.stops"
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
  stops_of > "$WORK/ctl.stops"
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
  if cmp -s "$WORK/base.stops" "$WORK/ctl.stops"; then
    echo "  stoppin   unmoved — all nine fixtures log the same stops, in order."
  else
    green "stoppin   RED"
    diff "$WORK/base.stops" "$WORK/ctl.stops" | sed 's/^/    /'
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
      echo "  ungated on all five, WITH A NUMBER: $DIAG_LINES/$DIAG_DIAGS -> $speaking/$diags."
    else
      red "UNGATED ON ALL FIVE AND NOTHING MOVED AT ALL."
      echo "  Decide which of §3.5v's four kinds this is. A row that predicted"
      echo "  this is a measurement; a row that did not is a hole in the battery."
    fi
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

P['h01'] = ('''# THE PREMISE — checkIdentifier reverted to the row it was until this slice, which
# is what every identifier in the corpus met. PREDICTION: DIAGPIN RED on every
# reporting pin file, TAGPIN + STOPPIN RED, STOPGATE moved by the whole chapter.''',
'''old = """        if k = KindIdentifier
            return this.check_identifier(node, check_mode)"""
new = """        if k = KindIdentifier
        {
            this.record_unported("check-identifier", k)
            return null
        }"""''')

P['h02'] = ('''# getResolvedSymbol passes NO message — the whole reporting half of resolveName
# switched off, callbacks included. PREDICTION: diagcheck UNGATED (every difference
# is a LOSS, which a subsequence cannot see) and DIAGPIN RED on
# parameter_self_reference, whose two codes come out of onSuccessfullyResolvedSymbol
# — plus STOPPIN RED everywhere, because resolve-name-not-found stops firing. The
# row that says the message is what the slice actually turned on.''',
'''old = """                set sym: this.resolve_name(node, AstNode.identifier_text_of(node), AstNode.identifier_text_length_of(node), SymbolFlagsValue | SymbolFlagsExportValue, DiagCannot_find_name_0, true, false)"""
new = """                set sym: this.resolve_name(node, AstNode.identifier_text_of(node), AstNode.identifier_text_length_of(node), SymbolFlagsValue | SymbolFlagsExportValue, 0, true, false)"""''')

P['h03'] = ('''# THE MEMO REMOVED — getResolvedSymbol resolves on every ask. PREDICTION: STOPPIN
# RED, because a second ask about the same identifier logs a second
# resolve-name-not-found; the memo is load-bearing rather than a saving, which is
# the claim SymbolNodeLink's own header makes and this row is what proves it.''',
'''old = """        let links this.symbol_node_link_of(node)
        if links.resolved_symbol = null
        {"""
new = """        let links this.symbol_node_link_of(node)
        if true
        {"""''')

P['h04'] = ('''# SLICE 79's LINE RESTORED — the isUse branch stops again. PREDICTION: everything
# RED. getResolvedSymbol passes isUse TRUE, so the stop fires once per RESOLVED
# identifier and the chapter dies at its second line. The row that prices the
# enumeration resolve_name skips that write with.''',
'''old = """        if result = null
        {
            if exclude_globals = false"""
new = """        if is_use
        {
            if result <> null
                this.record_unported("ctl-symbol-referenced", meaning)
        }
        if result = null
        {
            if exclude_globals = false"""''')

P['h05'] = ('''# The unknownSymbol sentinel never matches — a miss falls through into the rest of
# checkIdentifier. PREDICTION: diagcheck RED by INVENTION. The unknown symbol has
# Property flags and no value declaration, so the assignment block reads it as
# *not a variable* and reports TS2539 on names the reference cannot even find.''',
'''old = """        if symbol = unknown_symbol
            return error_type"""
new = """        if false
            return error_type"""''')

P['h06'] = ('''# The arguments arm's container test forced FALSE. PREDICTION: DIAGPIN RED on
# checker_identifier_arguments — TS2815 lost.''',
'''old = """            if Checker.is_in_property_initializer_or_class_static_block(node, true)
            {
                this.error_on_node(node, DiagX_arguments_cannot_be_referenced_in_property_initializers_or_class_static_initialization_blocks)"""
new = """            if false
            {
                this.error_on_node(node, DiagX_arguments_cannot_be_referenced_in_property_initializers_or_class_static_initialization_blocks)"""''')

P['h07'] = ('''# The same test forced TRUE. PREDICTION: DIAGPIN RED by INVENTION — the plain
# `function ok() { return arguments; }` in the same fixture would report TS2815,
# which the reference does not. h06's complement, and the pair is what makes the
# predicate a claim rather than a guard.''',
'''old = """            if Checker.is_in_property_initializer_or_class_static_block(node, true)
            {
                this.error_on_node(node, DiagX_arguments_cannot_be_referenced_in_property_initializers_or_class_static_initialization_blocks)"""
new = """            if true
            {
                this.error_on_node(node, DiagX_arguments_cannot_be_referenced_in_property_initializers_or_class_static_initialization_blocks)"""''')

P['h08'] = ('''# ignoreArrowFunctions passed FALSE instead of TRUE. PREDICTION: UNGATED. The
# fixture's property initializer holds no arrow function — the shape that needed one
# resolves to nothing at all (see the fixture's own header) — so the flag has no
# input, and saying so is what the row is for.''',
'''old = """            if Checker.is_in_property_initializer_or_class_static_block(node, true)"""
new = """            if Checker.is_in_property_initializer_or_class_static_block(node, false)"""''')

P['h09'] = ('''# The six-code chain REVERSED — Enum tested first, Alias last. PREDICTION: DIAGPIN
# RED on assign_to_nonvariable. The chain is an ordered switch and the order is the
# answer; a symbol that is both an enum and a namespace must answer *enum*.''',
'''old = """                var code: int DiagCannot_assign_to_0_because_it_is_not_a_variable
                if (lf & SymbolFlagsAlias) <> 0
                    set code: DiagCannot_assign_to_0_because_it_is_an_import
                if (lf & SymbolFlagsFunction) <> 0
                    set code: DiagCannot_assign_to_0_because_it_is_a_function
                if (lf & SymbolFlagsModule) <> 0
                    set code: DiagCannot_assign_to_0_because_it_is_a_namespace
                if (lf & SymbolFlagsClass) <> 0
                    set code: DiagCannot_assign_to_0_because_it_is_a_class
                if (lf & SymbolFlagsEnum) <> 0
                    set code: DiagCannot_assign_to_0_because_it_is_an_enum"""
new = """                var code: int DiagCannot_assign_to_0_because_it_is_not_a_variable
                if (lf & SymbolFlagsEnum) <> 0
                    set code: DiagCannot_assign_to_0_because_it_is_an_enum
                if (lf & SymbolFlagsClass) <> 0
                    set code: DiagCannot_assign_to_0_because_it_is_a_class
                if (lf & SymbolFlagsModule) <> 0
                    set code: DiagCannot_assign_to_0_because_it_is_a_namespace
                if (lf & SymbolFlagsFunction) <> 0
                    set code: DiagCannot_assign_to_0_because_it_is_a_function
                if (lf & SymbolFlagsAlias) <> 0
                    set code: DiagCannot_assign_to_0_because_it_is_an_import"""''')

P['h10'] = ('''# The JavaScript value-module exception removed. PREDICTION: UNGATED. Every pin
# file is TypeScript, so the exception has no input here; it is ported because the
# reference has it and 155 of stage 1's units are JavaScript, which is where a
# stage-2 confirmation would find it.''',
'''old = """                if Parser.is_in_js_file(node)
                {
                    if (lf & SymbolFlagsValueModule) <> 0
                        set not_a_variable: false
                }"""
new = """                if false
                {
                    if (lf & SymbolFlagsValueModule) <> 0
                        set not_a_variable: false
                }"""''')

P['h11'] = ('''# isReadonlySymbol's const arm forced FALSE. PREDICTION: DIAGPIN RED on
# assign_to_readonly, assign_compound and block_scoped_use — three TS2588 lost.''',
'''old = """        if (f & SymbolFlagsVariable) <> 0
        {
            if (Checker.get_declaration_node_flags_from_symbol(symbol) & NodeFlagsConstant) <> 0
                return true
        }"""
new = """        if false
        {
            if (Checker.get_declaration_node_flags_from_symbol(symbol) & NodeFlagsConstant) <> 0
                return true
        }"""''')

P['h12'] = ('''# The readonly report's two-code fork inverted. PREDICTION: DIAGPIN RED — TS2540
# where the reference says TS2588. The fork is on SymbolFlagsVariable and it is the
# only thing that separates *constant* from *read-only property*.''',
'''old = """                var code: int DiagCannot_assign_to_0_because_it_is_a_read_only_property
                if (lf & SymbolFlagsVariable) <> 0
                    set code: DiagCannot_assign_to_0_because_it_is_a_constant"""
new = """                var code: int DiagCannot_assign_to_0_because_it_is_a_constant
                if (lf & SymbolFlagsVariable) <> 0
                    set code: DiagCannot_assign_to_0_because_it_is_a_read_only_property"""''')

P['h13'] = ('''# checkResolvedBlockScopedVariable ABORTS its caller — the stop returns out of the
# callback, which is the shape its own header warns about. PREDICTION: nothing on
# the diagnostics, because the callback's later blocks are what it skips, not
# checkIdentifier's reports. The row is here to say which of the two readings the
# header's warning is about — and if it goes RED, the warning was about this one.''',
'''old = """                    if (Symbol.flags_of(e) & (SymbolFlagsBlockScopedVariable | SymbolFlagsClass | SymbolFlagsEnum)) <> 0
                        this.check_resolved_block_scoped_variable(e, error_location as ref[AstNode])"""
new = """                    if (Symbol.flags_of(e) & (SymbolFlagsBlockScopedVariable | SymbolFlagsClass | SymbolFlagsEnum)) <> 0
                    {
                        this.check_resolved_block_scoped_variable(e, error_location as ref[AstNode])
                        return
                    }"""''')

P['h14'] = ('''# The constructor-function early-out in checkResolvedBlockScopedVariable removed —
# every entering symbol reaches the stop. PREDICTION: UNGATED WITH A NUMBER on the
# stop instruments, or unmoved: the shape it excludes is
# Function|FunctionScopedVariable|Assignment together with Class, i.e. a CommonJS
# constructor function, and no pin file has one. It is written to keep the stop's
# COUNT honest, which is the only thing the work list reads.''',
'''old = """        if (f & (SymbolFlagsFunction | SymbolFlagsFunctionScopedVariable | SymbolFlagsAssignment)) <> 0
        {
            if (f & SymbolFlagsClass) <> 0
                return
        }"""
new = """        if false
        {
            if (f & SymbolFlagsClass) <> 0
                return
        }"""''')

P['h15'] = ('''# Block 2's declaration test forced TRUE — every resolved symbol in a module reads
# as a UMD global. PREDICTION: diagcheck RED by INVENTION on the module fixtures.
# The row that says block 2 is LIVE CODE and not a comment, even though h16 shows
# it has no input.''',
'''old = """                                    if ok = false
                                        set every: false"""
new = """                                    if false
                                        set every: false"""''')

P['h16'] = ('''# Block 2 removed outright. PREDICTION: UNGATED, NOTHING MOVING — and that is the
# measurement the umd_global fixture exists for. The block is decidable here; what
# it lacks is a SYMBOL, because `export as namespace Lib` declares into
# GlobalExports and the walk reaches that only through the globals table (§3.11).
# h15 and h16 are the pair: live code, no input.''',
'''old = """                        let merged this.get_merged_symbol(result)
                        if merged <> null"""
new = """                        let merged this.get_merged_symbol(result)
                        if false"""''')

P['h17'] = ('''# Block 3's withinDeferredContext forced TRUE. PREDICTION: DIAGPIN RED on
# parameter_self_reference — both TS2372 and TS2373 lost. The row that says the
# loop output §3.5ao deferred is load-bearing and not bookkeeping.''',
'''old = """            if within_deferred_context = false
            {
                if value_meaning
                {
                    let ad associated_declaration as ref[AstNode]"""
new = """            if false
            {
                if value_meaning
                {
                    let ad associated_declaration as ref[AstNode]"""''')

P['h18'] = ('''# The resolver's KindParameter arm never records the associated declaration —
# §3.5ao's omission put back for one run. PREDICTION: DIAGPIN RED on
# parameter_self_reference, and only there: both of the fixture's lines go through
# that arm, so BOTH codes go.''',
'''old = """                    if carries
                    {
                        if associated_declaration = null
                            set associated_declaration: l
                    }
                }
            }
            if k = KindBindingElement"""
new = """                    if false
                    {
                        if associated_declaration = null
                            set associated_declaration: l
                    }
                }
            }
            if k = KindBindingElement"""''')

P['h19'] = ('''# The computed-property-name step's meaning mask widened from Type to ALL — the
# mask that makes three of resolveName's four in-loop reports unreachable from a
# value caller. PREDICTION: diagcheck RED by INVENTION — TS2467 appears on
# resolver_reports, where the reference answers TS2304. The row that PROVES the
# unreachability claim rather than asserting it.''',
'''old = """                        set result: this.lookup_symbol(Symbol.members_of(owner as ref[Symbol]), name_data, name_len, meaning & SymbolFlagsType)
                        if result <> null
                        {
                            ; TS2467."""
new = """                        set result: this.lookup_symbol(Symbol.members_of(owner as ref[Symbol]), name_data, name_len, meaning)
                        if result <> null
                        {
                            ; TS2467."""''')

P['h20'] = ('''# isThisInTypeQuery forced TRUE — every identifier redirects to
# check-this-expression. PREDICTION: everything RED. Its complement is the useful
# half: the branch has no input (h21), so this row is what shows it is reachable
# CODE and not a dead line.''',
'''old = """        if Checker.is_this_in_type_query(node)
        {
            this.record_unported("check-this-expression", KindThisKeyword)"""
new = """        if true
        {
            this.record_unported("check-this-expression", KindThisKeyword)"""''')

P['h21'] = ('''# isThisInTypeQuery forced FALSE — the redirect removed. PREDICTION: UNGATED,
# NOTHING MOVING. A `this` KEYWORD never reaches checkIdentifier (check_expression
# dispatches it one level up) and the IDENTIFIER spelling occurs only inside a type
# query, which this port walks through get_type_from_type_node — a row. The branch
# is the reference's first line and it has no input here; h20 is the other half.''',
'''old = """        if Checker.is_this_in_type_query(node)
        {
            this.record_unported("check-this-expression", KindThisKeyword)"""
new = """        if false
        {
            this.record_unported("check-this-expression", KindThisKeyword)"""''')

P['h22'] = ('''# The DEFINITE early-out removed — a definite assignment falls through like a
# compound one. PREDICTION: STOPPIN RED on assign_to_readonly and block_scoped_use:
# the identifier stops at flow-graph where it answered `t`. The row that says
# AssignmentKind is not a boolean.''',
'''old = """            if assignment_kind = AssignmentKindDefinite
            {
                if Checker.is_in_compound_like_assignment(node)"""
new = """            if false
            {
                if Checker.is_in_compound_like_assignment(node)"""''')

P['h23'] = ('''# isInCompoundLikeAssignment forced FALSE. PREDICTION: STOPPIN RED on
# assign_compound — `b = b << 1` stops at get-base-type-of-literal-type today and
# would answer `t` instead. The one row that reads the shift-operator ladder.''',
'''old = """                if Checker.is_in_compound_like_assignment(node)
                {"""
new = """                if false
                {"""''')

P['h24'] = ('''# getNarrowedTypeOfSymbol's binding-element GUARD widened — the sibling count
# `>= 2` becomes `>= 0`, so the row fires for every binding element instead of only
# for a destructuring with two or more names. PREDICTION: STOPGATE moved on the
# event count. ★★★The first draft of this row RENAMED the tag instead, and it came
# back UNGATED ON ALL FIVE — correctly, because not one of the five instruments
# reads a tag NAME outside the pin files: the stopgate counts events, the stoppin
# compares eight files that have no binding pattern, and the work-list histogram is
# not part of this battery. **A control that cannot fire is worse than none**, and
# a control that moves only a tag is one.''',
'''old = """                            if sibling_count >= 2"""
new = """                            if sibling_count >= 0"""''')

P['h25'] = ('''# The non-variable, non-alias EARLY ANSWER removed — a function or class name
# falls through to the alias/flow tail. PREDICTION: STOPPIN RED and the STOPGATE
# moved. This is the branch that carries the whole TYPE product of the slice: the
# arms the reference answers ABOVE the flow graph.''',
'''old = """        if (Symbol.flags_of(les) & SymbolFlagsVariable) = 0
        {
            if is_alias = false
                return t
        }"""
new = """        if false
        {
            if is_alias = false
                return t
        }"""''')

for k, (pred, body) in sorted(P.items()):
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

control "h01 THE PREMISE — checkIdentifier reverted to a row" $CHECKER "$PATCHDIR/h01.py"
control "h02 getResolvedSymbol passes NO message" $CHECKER "$PATCHDIR/h02.py"
control "h03 THE MEMO removed from getResolvedSymbol" $CHECKER "$PATCHDIR/h03.py"
control "h04 slice 79's symbol-referenced STOP restored" $CHECKER "$PATCHDIR/h04.py"
control "h05 the unknownSymbol sentinel never matches" $CHECKER "$PATCHDIR/h05.py"
control "h06 the arguments container test forced FALSE" $CHECKER "$PATCHDIR/h06.py"
control "h07 the arguments container test forced TRUE" $CHECKER "$PATCHDIR/h07.py"
control "h08 ignoreArrowFunctions passed FALSE" $CHECKER "$PATCHDIR/h08.py"
control "h09 the six-code chain REVERSED" $CHECKER "$PATCHDIR/h09.py"
control "h10 the JS value-module exception removed" $CHECKER "$PATCHDIR/h10.py"
control "h11 isReadonlySymbol's const arm forced FALSE" $CHECKER "$PATCHDIR/h11.py"
control "h12 the readonly two-code fork inverted" $CHECKER "$PATCHDIR/h12.py"
control "h13 checkResolvedBlockScopedVariable ABORTS the callback" $CHECKER "$PATCHDIR/h13.py"
control "h14 the constructor-function early-out removed" $CHECKER "$PATCHDIR/h14.py"
control "h15 block 2's declaration test forced TRUE" $CHECKER "$PATCHDIR/h15.py"
control "h16 block 2 removed outright" $CHECKER "$PATCHDIR/h16.py"
control "h17 block 3's withinDeferredContext forced TRUE" $CHECKER "$PATCHDIR/h17.py"
control "h18 the resolver's KindParameter arm neutered" $CHECKER "$PATCHDIR/h18.py"
control "h19 the computed-property step's meaning mask widened" $CHECKER "$PATCHDIR/h19.py"
control "h20 isThisInTypeQuery forced TRUE" $CHECKER "$PATCHDIR/h20.py"
control "h21 isThisInTypeQuery forced FALSE" $CHECKER "$PATCHDIR/h21.py"
control "h22 the DEFINITE early-out removed" $CHECKER "$PATCHDIR/h22.py"
control "h23 isInCompoundLikeAssignment forced FALSE" $CHECKER "$PATCHDIR/h23.py"
control "h24 getNarrowedTypeOfSymbol's binding-element guard widened" $CHECKER "$PATCHDIR/h24.py"
control "h25 the non-variable EARLY ANSWER removed" $CHECKER "$PATCHDIR/h25.py"

echo
echo "################################################################"
bold "DONE — read every row against its PREDICTION, not against its colour."
