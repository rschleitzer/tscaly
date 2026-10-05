#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice95.sh — the slice-95 battery: THE TYPE REFERENCE.
#
# ★★★ THE ROW THIS SLICE CLOSES HAD TWO PRODUCERS, AND THE BATTERY IS BUILT ON
# THAT. `get-type-from-type-node 184` was 1 773 events over 190 units at stage 1
# and it is not one arm: 1 253 of those events are `check_type_reference_or_import`
# — the CHECK of a type-reference node — and 520 are the dispatcher's own
# TypeReference arm. h01 and h02 are the two premises, and h02 is the row that
# shows why closing one without the other moves a number and unblocks nothing.
#
# ★★★ THE EIGHTH INSTRUMENT AGAIN, AND FOR A REASON THE SEVENTH DID NOT HAVE.
# Slice 94 built the UNIONPIN because *this chapter's product is a type no
# artifact in this directory prints*. The type reference is the same again, and
# worse in one way that decides it: a union is INTERNED, so a table of every union
# the checker made is a complete record of that chapter, while a type reference is
# an ANSWER GIVEN AT A NODE. `tscaly_types --typerefs` prints
# `X <pos> <end> <symbolflags> <typeid> <name>` per RESOLVED type reference — the
# SYMBOLFLAGS column sees which symbol a name resolved to and the NAME column sees
# what the printer composes back out of the type, and those are the two halves
# this chapter can get wrong.
#
# ★★★ AND THE STRUCTURAL FACT THAT MAKES IT NECESSARY RATHER THAN NICE: THE T
# SECTION IS ALL-OR-NOTHING PER UNIT. A stop anywhere makes the whole unit
# UNPORTED and the dump prints one line, so the printer arms this slice adds are
# invisible on every unit that still has any other wall — 1 472 of 1 486 at stage
# 1. **Eleven of the rows below move the TREFPIN or the TREFGATE and nothing
# else**, and on the seven instruments slice 94 had, all eleven would have read
# *ungated with nothing moving*.
#
# ★★★ ITERATE AT STAGE 1 AND CONFIRM AT STAGE 2 ONCE — slice 64's rule. The
# recorded verdicts are stage 1's.
#
# Usage (nothing may edit the tree while this runs, and no second harness may own
# tests/out — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # stage 1
#   packages/tscaly/tests/controls-slice95.sh 2>&1 | tee /tmp/battery95.log
#
set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.0/tscaly/checker.scaly
FIX=$PKG/tests/fixtures

. packages/tscaly/tests/toolchain.sh || exit 2

# ★ ONE MECHANISM PER FILE (slice 72's rule). Eight files, all this slice's:
# the named half, the generic half, the three arity reports, the four stops, the
# deferred fork, the deprecation counter, and the one shape in which the printer's
# SOURCE text and the identifier's scanned text differ.
PINFILES="
$FIX/typeref_named.ts
$FIX/typeref_generic.ts
$FIX/typeref_arity.ts
$FIX/typeref_stops.ts
$FIX/typeref_deferred.ts
$FIX/typeref_deprecated.ts
$FIX/typeref_escaped_name.ts
$FIX/union_optional.ts
"
# ★★★ EVERY DUMPER CALL BELOW RUNS UNDER A TIME LIMIT, AND THE REASON IS SLICE
# 94's h06 rather than anything here: breaking one bit of a printer can remove the
# BASE CASE of its own recursion, and a process that grows until the machine does
# is a verdict a battery cannot produce without a limit. This chapter's printer
# recurses too — type_reference_to_type_node calls type_to_string on every type
# ARGUMENT — so the same hazard is one control away. `perl -e 'alarm N; exec @ARGV'`
# is on every box this repo builds on, costs ~10 ms and kills at N seconds with
# rc 142; timeout(1) is not on macOS.
#
# ★★ THE LIMIT IS PART OF THE MEASUREMENT AND NOT A CONVENIENCE. A killed call
# writes nothing, so the pin and the gate both MOVE — which is the honest verdict
# for a patch that makes the port not terminate.
LIMIT=${LIMIT:-3}
run_limited() { perl -e 'alarm shift; exec @ARGV' "$LIMIT" "$@"; }

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl94)

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
  "$SCALYC" -c --no-prelude -o "$WORK/pkg.o" "$PKG/0.1.0/tscaly.scaly" > "$WORK/build.log" 2>&1 || return 1
  "$SCALYC" -c -o "$WORK/types.o" "$PKG/0.1.0/tscaly_types.scaly" >> "$WORK/build.log" 2>&1 || return 1
  clang -o "$WORK/tscaly_types" "$WORK/types.o" "$WORK/pkg.o" "$LIBSCALY" -lm >> "$WORK/build.log" 2>&1
}

diags_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$(run_limited "$WORK/tscaly_types" --diags "$f" 2>/dev/null | tr '\n' '|')"
  done
}

tags_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$(run_limited "$WORK/tscaly_types" "$f" 2>/dev/null | grep '^UNPORTED ' | head -1 | cut -d' ' -f3-)"
  done
}

stops_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$(run_limited "$WORK/tscaly_types" --stops "$f" 2>/dev/null | tr '\n' '|')"
  done
}

# ★★★ THE TYPEREF PIN — slice 95's EIGHTH instrument, and the argument for it is
# in TypeRefEvent's own header. `X <pos> <end> <symbolflags> <typeid> <name>` per
# RESOLVED type reference, in the order the check reached them. The SYMBOLFLAGS
# column sees WHICH SYMBOL a name resolved to; the NAME column is the only thing
# in this tree that can see the printer's class/interface, type-parameter and
# type-argument arms at all.
trefpin_of() {
  local f
  for f in $PINFILES; do
    printf '%s	%s
' "$(basename "$f")" \
      "$(run_limited "$WORK/tscaly_types" --typerefs "$f" 2>/dev/null | tr '
' '|')"
  done
}

# ★★★ THE WHOLE-CORPUS TREFGATE, and slice 92's h08/h11/h25 are why it is here
# beside a pin rather than instead of it: eleven fixtures aimed at eleven
# mechanisms still missed three of them, because the shape that distinguishes an
# arm is not the shape a fixture author writes around. The eight pin files here
# carry about thirty X lines between them; the corpus carries 644.
#
# ★ The units are dispatched in PARALLEL and each writes its own file, then the
# files are concatenated in a fixed order. A shared pipe would interleave and the
# checksum would move on its own — an instrument that disagrees with itself is
# worse than none.
#
# ★★ IT IS A COUNT, AN UNNAMED COUNT AND A CHECKSUM, so two breakages are told
# apart without a diff: a chapter that stops answering moves the COUNT, a printer
# that cannot name what the chapter built moves the UNNAMED column, and a WRONG
# name or a wrong symbol moves the CHECKSUM at both counts unchanged.
#
# ★ NUL-DELIMITED SINCE SLICE 101, AND THE FIX IS NOT COSMETIC: `xargs` splits on
# WHITESPACE, the stage-2 corpus holds one unit whose name contains a space, and
# from it onward the `-n 2` pairing shifts by one — which redirects the dumper's
# stdout INTO A CORPUS FILE. Invisible at stage 1, where no unit path has a space.
# See §3.5eu finding nine.
trefgate() {
  local i=0 u
  rm -rf "$WORK/tout" "$WORK/tpairs"; mkdir -p "$WORK/tout"
  while IFS= read -r u; do
    printf '%s\0%s\0' "$u" "$(printf '%s/tout/%06d' "$WORK" "$i")"
    i=$((i+1))
  done < "$WORK/units.txt" > "$WORK/tpairs"
  LIMIT=$LIMIT xargs -0 -P 8 -n 2 sh -c 'perl -e "alarm $LIMIT; exec @ARGV" "$0" --typerefs "$1" > "$2" 2>/dev/null' "$WORK/tscaly_types" < "$WORK/tpairs"
  find "$WORK/tout" -type f -print0 | xargs -0 cat > "$WORK/trefs.all"
  local n q
  n=$(grep -c '^X ' "$WORK/trefs.all")
  q=$(grep -c ' ?$' "$WORK/trefs.all")
  echo "$n $q $(cksum < "$WORK/trefs.all" | cut -d' ' -f1)"
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

DIAG_BASE=""; DIAG_LINES=""; DIAG_DIAGS=""; STOP_BASE=""; TREF_BASE=""

baseline() {
  echo "################################################################"
  bold "BASELINE — seven instruments"
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
  trefpin_of > "$WORK/base.trefs"
  find "$PKG/tests/out/cases" -path '*/units/*' -type f \
       \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.mjs' -o -name '*.cjs' \) \
       | sort > "$WORK/units.txt"
  STOP_BASE=$(stopgate)
  TREF_BASE=$(trefgate)
  echo
  echo "  the STOPPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.stops"
  echo
  echo "  the TAGPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.tags"
  echo
  echo "  the TREFPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.trefs"
  echo
  echo "  BASELINE   diagcheck $DIAG_BASE consistent, $DIAG_LINES speaking, $DIAG_DIAGS diagnostics"
  echo "             stopgate  (matched units speaking events other) = $STOP_BASE"
  echo "             trefgate  (typerefs unnamed checksum) over $(wc -l < "$WORK/units.txt" | tr -d ' ') units = $TREF_BASE"
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
  trefpin_of > "$WORK/ctl.trefs"
  stop=$(stopgate)
  local tref
  tref=$(trefgate)
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
    echo "  diagpin   unmoved — all eight pin files answer the same C section."
  else
    green "diagpin   RED"
    diff "$WORK/base.diags" "$WORK/ctl.diags" | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.tags" "$WORK/ctl.tags"; then
    echo "  tagpin    unmoved — all eight fixtures answer the same tag."
  else
    green "tagpin    RED"
    diff "$WORK/base.tags" "$WORK/ctl.tags" | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.stops" "$WORK/ctl.stops"; then
    echo "  stoppin   unmoved — all eight fixtures log the same stops, in order."
  else
    green "stoppin   RED"
    diff "$WORK/base.stops" "$WORK/ctl.stops" | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.trefs" "$WORK/ctl.trefs"; then
    echo "  trefpin   unmoved — all eight fixtures resolve the same references to the same names."
  else
    green "trefpin   RED"
    diff "$WORK/base.trefs" "$WORK/ctl.trefs" | cut -c1-240 | sed 's/^/    /'
    moved=1
  fi
  if [ "$stop" = "$STOP_BASE" ]; then
    echo "  stopgate  unmoved — $stop"
  else
    green "stopgate  MOVED   $STOP_BASE -> $stop   (matched units speaking events other)"
    moved=1
  fi
  if [ "$tref" = "$TREF_BASE" ]; then
    echo "  trefgate  unmoved — $tref"
  else
    green "trefgate  MOVED   $TREF_BASE -> $tref   (typerefs unnamed checksum)"
    moved=1
  fi
  if [ "$moved" = 0 ]; then
    if [ "$speaking" != "$DIAG_LINES" ] || [ "$diags" != "$DIAG_DIAGS" ]; then
      echo "  ungated on all seven, WITH A NUMBER: $DIAG_LINES/$DIAG_DIAGS -> $speaking/$diags."
    else
      red "UNGATED ON ALL SEVEN AND NOTHING MOVED AT ALL."
      echo "  Decide which of §3.5v's four kinds this is. A row that predicted"
      echo "  this is a measurement; a row that did not is a hole in the battery."
    fi
  fi
  return 0
}

PATCHDIR=$WORK/patches
mkdir -p "$PATCHDIR"

PATCHDIR=$WORK/patches
mkdir -p "$PATCHDIR"

python3 - "$PATCHDIR" <<'MKPATCHES'
import os, sys
D = sys.argv[1]
os.makedirs(D, exist_ok=True)

P = {}

P['h01'] = ('''# THE PREMISE (the dispatcher half) — getTypeFromTypeNode's KindTypeReference arm
# reverted to the stop it was until this slice. PREDICTION: TAGPIN + STOPPIN +
# TREFPIN RED on every fixture, the TREFGATE's count to ZERO, and the STOPGATE
# moved by the arm's whole 520 events. One of TWO premises, because the row this
# slice closes had two producers.''',
'''old = """        if k = KindTypeReference
            return this.get_type_from_type_reference(node)"""
new = """        if k = KindTypeReference
        {
            this.record_unported("get-type-from-type-node", k)
            return null
        }"""''')

P['h02'] = ('''# THE PREMISE (the check half) — checkTypeReferenceOrImport reverted to its stop.
# PREDICTION: TAGPIN + STOPPIN RED and the STOPGATE moved by the other 1 253
# events, with the TREFGATE moving too — the check is what REACHES most type
# references, so its stop takes the dispatcher's product with it even though the
# dispatcher arm is untouched. The row that says the two producers are one row.''',
'''old = """    procedure check_type_reference_or_import(this, node: ref[AstNode])
    {
        let mark this.unported_mark()
        let t this.get_type_from_type_node(node)"""
new = """    procedure check_type_reference_or_import(this, node: ref[AstNode])
    {
        this.record_unported("get-type-from-type-node", AstNode.kind_of(node))
        if true
            return
        let mark this.unported_mark()
        let t this.get_type_from_type_node(node)"""''')

P['h03'] = ('''# THE MARK — get_type_from_type_reference's per-call mark replaced by the STICKY
# is_unported(). PREDICTION: TREFGATE to (near) ZERO with the STOPGATE barely
# moving, which is the signature this slice was built on: a row that closes while
# nothing takes its place. It is slice 94's finding three met from the far side,
# and it is the defect the first build of this chapter actually had.
#
# ★★★ ITS FIRST DRAFT NAMED THE WRONG SITE AND THAT COST A BATTERY ROW. The same
# mistake exists in `resolve_type_reference_name`, and patching THAT one moves ten
# stop events and nothing else — because the guard there sits AFTER the successful
# return, so it is only ever reached on a miss, which answers null either way. **The
# site that carries a finding is the one on the path every answer takes, and two
# spellings of one defect are not interchangeable as controls.**''',
'''old = """        let mark this.unported_mark()
        let jd this.get_intended_type_from_jsdoc_type_reference(node)
        if this.unported_mark() <> mark
            return null"""
new = """        let mark this.unported_mark()
        let jd this.get_intended_type_from_jsdoc_type_reference(node)
        if this.is_unported()
            return null"""''')

P['h04'] = ('''# resolve_entity_name's identifier arm never calls get_merged_symbol.
# PREDICTION: UNGATED or barely moving — a merged symbol differs from its own
# first declaration's symbol only where two declarations of one name were merged,
# and a type reference in these fixtures names one declaration. The row prices the
# call rather than assuming it.''',
'''old = """            set symbol: this.get_merged_symbol(this.resolve_name(resolve_location, AstNode.identifier_text_of(name), AstNode.identifier_text_length_of(name), meaning, message, true, false))"""
new = """            set symbol: this.resolve_name(resolve_location, AstNode.identifier_text_of(name), AstNode.identifier_text_length_of(name), meaning, message, true, false)"""''')

P['h05'] = ('''# resolve_entity_name is called with NO message, i.e. resolve_name's reporting
# half is switched off. PREDICTION: the STOPGATE moves DOWN by the whole
# resolve-name-not-found row this slice made the corpus head — 720 events — with
# the TREFGATE unmoved, because a miss answers null either way. The row that
# separates *the wall* from *the report at the wall*, and the one that prices
# §3.11 from this chapter's side.''',
'''old = """                if meaning = SymbolFlagsNamespace
                    set message: DiagCannot_find_namespace_0
                else
                    set message: DiagCannot_find_name_0"""
new = """                if meaning = SymbolFlagsNamespace
                    set message: 0
                else
                    set message: 0"""''')

P['h06'] = ('''# The ALIAS guard removed — a symbol carrying SymbolFlagsAlias is answered
# instead of stopping at mark-symbol-of-alias-declaration. PREDICTION: the
# STOPGATE moves and the TREFGATE gains rows, because an imported type name would
# then resolve to the IMPORT's own symbol rather than to what it aliases — a
# well-formed wrong answer, which is why the guard is a stop.''',
'''old = """        if (Symbol.flags_of(s) & SymbolFlagsAlias) <> 0
        {
            this.record_unported("mark-symbol-of-alias-declaration", 0)
            return null
        }"""
new = """        if false
        {
            this.record_unported("mark-symbol-of-alias-declaration", 0)
            return null
        }"""''')

P['h07'] = ('''# resolve_type_reference_name answers null instead of unknownSymbol for a name
# getTypeReferenceName could not produce. PREDICTION: UNGATED with an argument —
# the nil answer needs an ExpressionWithTypeArguments whose expression is not a
# qualified name, and this port routes that kind through a different wall
# entirely (`get-type-from-type-node 234`). The row is the containment proof.''',
'''old = """        let nm Checker.get_type_reference_name(type_reference)
        if nm = null
            return unknown_symbol"""
new = """        let nm Checker.get_type_reference_name(type_reference)
        if nm = null
            return null"""''')

P['h08'] = ('''# get_symbol_from_type_reference's memo always misses — BOTH halves, the answer
# and the stop. PREDICTION: diagcheck RED by INVENTION at stage 2 and UNGATED at
# stage 1, because the memo is what makes `resolveName`'s TS2302 report fire once
# per NODE rather than once per VISIT. It is the row for the finding stage 1 could
# not see, and the reason the recorded verdict names the stage.''',
'''old = """        if links.resolved_symbol <> null
            return links.resolved_symbol"""
new = """        if false
            return links.resolved_symbol"""
s = s.replace(old, new, 1)
old = """        if links.resolution_stopped
        {
            var r 0"""
new = """        if false
        {
            var r 0"""''')

P['h09'] = ('''# get_type_from_type_reference's memo always misses. PREDICTION: the TREFPIN and
# the TREFGATE move by their COUNT alone — the log is appended where the function
# answers, so a second visit to the same node writes a second row with an
# IDENTICAL name and id. The row that shows the pin counts CALLS and not types.''',
'''old = """        let links this.type_node_link_of(node)
        if links.resolved_type <> null
            return links.resolved_type
        if this.is_const_type_reference(node)"""
new = """        let links this.type_node_link_of(node)
        if false
            return links.resolved_type
        if this.is_const_type_reference(node)"""''')

P['h10'] = ('''# The `as const` arm removed — is_const_type_reference forced false in
# get_type_from_type_reference. PREDICTION: UNGATED with an argument: `x as const`
# reaches this function only through an ASSERTION parent, and the assertion
# chapter stops one level up, so the arm has no input at either stage. It is the
# arm §3.5en's finding two says must be a stop rather than an omission.''',
'''old = """        let mark this.unported_mark()
        let jd this.get_intended_type_from_jsdoc_type_reference(node)"""
new = """        if false
        {
            this.record_unported("const-type-reference", 0)
            return null
        }
        let mark this.unported_mark()
        let jd this.get_intended_type_from_jsdoc_type_reference(node)"""''')

P['h11'] = ('''# getIntendedTypeFromJSDocTypeReference never fires — its NodeFlagsJSDoc guard
# forced closed. PREDICTION: it moves something only where a JavaScript file
# writes `@type {String}` and friends; those eight capitalised names are the whole
# arm, and the corpus decides whether it has one. The row turns a guess into a
# number.''',
'''old = """        if (AstNode.flags_of(node) & NodeFlagsJSDoc) = 0
            return null
        if AstNode.kind_of(node) <> KindTypeReference
            return null"""
new = """        if true
            return null
        if AstNode.kind_of(node) <> KindTypeReference
            return null"""''')

P['h12'] = ('''# getTypeReferenceType's unknownSymbol arm removed, so an unresolvable name falls
# into tryGetDeclaredTypeOfSymbol instead of answering errorType. PREDICTION: the
# STOPGATE moves — unknownSymbol carries SymbolFlagsProperty, which the declared-
# type switch falls out of, so the answer becomes nil where errorType belongs and
# the caller reads *this port could not get there*. The row shows the two nils
# getTypeReferenceType has to tell apart.''',
'''old = """        if symbol = unknown_symbol
            return error_type
        let f Symbol.flags_of(symbol)"""
new = """        if false
            return error_type
        let f Symbol.flags_of(symbol)"""''')

P['h13'] = ('''# The Class/Interface arm removed — a class or interface reference falls to
# tryGetDeclaredTypeOfSymbol, which answers the DECLARED type without the type
# arguments. PREDICTION: TREFPIN RED on typeref_generic — `Box<string>` prints as
# `Box`, a well-formed WRONG answer, and nothing else in this directory can see
# it. The clearest row for why the eighth instrument exists.''',
'''old = """        if (f & (SymbolFlagsClass | SymbolFlagsInterface)) <> 0
            return this.get_type_from_class_or_interface_reference(node, symbol)"""
new = """        if false
            return this.get_type_from_class_or_interface_reference(node, symbol)"""''')

P['h14'] = ('''# The TYPE-ALIAS stop removed, so an alias reference falls through to
# tryGetDeclaredTypeOfSymbol — which stops one chapter down at
# get-declared-type-of-type-alias. PREDICTION: the STOPGATE moves with the TAG
# changing rather than the count, which is the difference between a stop that
# names this chapter's wall and one that names the next chapter's.''',
'''old = """        if (f & SymbolFlagsTypeAlias) <> 0
        {
            this.record_unported("get-type-from-type-alias-reference", 0)
            return null
        }
        let mark this.unported_mark()"""
new = """        if false
        {
            this.record_unported("get-type-from-type-alias-reference", 0)
            return null
        }
        let mark this.unported_mark()"""''')

P['h15'] = ('''# THE TWO NILS — getTypeReferenceType's mark ignored, so a STOP inside
# tryGetDeclaredTypeOfSymbol is read as *the reference answers nothing here* and
# turned into errorType. PREDICTION: TREFGATE UP (every stopped lookup becomes an
# `any`) with the STOPGATE unmoved, because the stop is still recorded — an
# INVENTED answer standing on top of an honest wall. The row for the note at that
# function's own line.''',
'''old = """        let res this.try_get_declared_type_of_symbol(symbol)
        if this.unported_mark() <> mark
            return null"""
new = """        let res this.try_get_declared_type_of_symbol(symbol)
        if false
            return null"""''')

P['h16'] = ('''# checkNoTypeArguments always answers true. PREDICTION: diagcheck RED by
# INVENTION is NOT what this does — the report is what goes, so it is a LOSS:
# TS2315 disappears from typeref_arity and diagcheck stays green while the DIAGPIN
# goes red. The row that shows which half of this battery a subsequence can see.''',
'''old = """        this.error_on_node(node, DiagType_0_is_not_generic)
        false
    }"""
new = """        if false
            this.error_on_node(node, DiagType_0_is_not_generic)
        true
    }"""''')

P['h17'] = ('''# hasTypeParameterDefault always answers false, so getMinTypeArgumentCount equals
# the parameter count. PREDICTION: DIAGPIN RED on typeref_arity — `Pair<string>`
# becomes a TS2314 where the reference reports nothing at all, and the TS2707 fork
# can never be chosen. diagcheck RED by INVENTION. The row that prices the default
# scan.''',
'''old = """                if Checker.has_type_parameter_default(tp as ref[Type]) = false
                    set min_count: i + 1"""
new = """                if true
                    set min_count: i + 1"""''')

P['h18'] = ('''# The arity message fork forced to the fixed-arity code. PREDICTION: DIAGPIN RED
# on typeref_arity with the SPANS unchanged and one code changing, 2707 -> 2314,
# and diagcheck RED. The row that shows the two arity diagnostics are one
# comparison and not two reports.''',
'''old = """        if min_count < tp_count
            this.error_on_node(node, DiagGeneric_type_0_requires_between_1_and_2_type_arguments)
        else
            this.error_on_node(node, DiagGeneric_type_0_requires_1_type_argument_s)"""
new = """        if false
            this.error_on_node(node, DiagGeneric_type_0_requires_between_1_and_2_type_arguments)
        else
            this.error_on_node(node, DiagGeneric_type_0_requires_1_type_argument_s)"""''')

P['h19'] = ('''# The TOO-MANY-arguments comparison removed. PREDICTION: DIAGPIN RED — the TS2314
# on `Box<string, number>` disappears and the extra argument is carried into
# fillMissingTypeArguments instead, so the TREFPIN moves as well. The row that
# shows one arity report guards two different failures.''',
'''old = """            if num_type_arguments > tp_count
                return this.report_type_argument_arity(node, min_count, tp_count, is_js)"""
new = """            if false
                return this.report_type_argument_arity(node, min_count, tp_count, is_js)"""''')

P['h20'] = ('''# isDeferredTypeReferenceNode's ALIAS disjunct removed. PREDICTION: STOPPIN RED on
# typeref_deferred — `type A = Box<string>` stops for a different reason or not at
# all, and the TREFGATE gains the references that were deferred. The row that
# separates the predicate's two disjuncts, which that fixture has one of each.''',
'''old = """        if this.get_alias_symbol_for_type_node(node) <> null
            return true
        if Checker.is_resolved_by_type_alias(node) = false
            return false"""
new = """        if false
            return true
        if Checker.is_resolved_by_type_alias(node) = false
            return false"""''')

P['h21'] = ('''# isResolvedByTypeAlias never climbs — the walk answers at the first parent.
# PREDICTION: STOPPIN RED on typeref_deferred's SECOND shape alone, because `B`
# reaches its alias through the reference's own type-argument list. h20 breaks the
# first disjunct and this breaks the second, which is the pair that says which
# half a fixture measures.''',
'''old = """            if climbs = false
                return false
            set n: parent"""
new = """            if true
                return false
            set n: parent"""''')

P['h22'] = ('''# mayResolveTypeAlias' TypeReference arm answers false. PREDICTION: UNGATED or
# small — it is only asked under isResolvedByTypeAlias, i.e. inside a type alias,
# and only about the type ARGUMENTS. The row prices the recursion rather than
# assuming it matters.''',
'''old = """            let sym this.resolve_type_reference_name(node, SymbolFlagsType, false)
            if sym = null
                return false
            return (Symbol.flags_of(sym as ref[Symbol]) & SymbolFlagsTypeAlias) <> 0"""
new = """            return false"""''')

P['h23'] = ('''# fillMissingTypeArguments never fills — the written argument list is used as it
# stands. PREDICTION: TREFPIN RED on typeref_generic: `Pair<string>` prints
# `Pair<string>` where the reference prints `Pair<string, number>`. A well-formed
# WRONG answer that no diagnostic, no stop and no other pin can see.''',
'''old = """        var fill false
        if is_js
            set fill: true
        if num_arguments < num_parameters
            set fill: true"""
new = """        var fill false
        if is_js
            set fill: true
        if false
            set fill: true"""''')

P['h24'] = ('''# fillMissingTypeArguments' DEFAULT is never instantiated — every missing slot
# takes the base default. PREDICTION: TREFPIN RED — `Pair<string>` prints
# `Pair<string, unknown>` instead of `Pair<string, number>`, which is the same
# shape as h23 one step in. The pair says filling and DEFAULTING are two
# mechanisms.''',
'''old = """            if dflt = null
                result.put(i as size_t, base_default)"""
new = """            if true
                result.put(i as size_t, base_default)"""''')

P['h25'] = ('''# The OUTER type parameters are not prepended to the argument list. PREDICTION:
# UNGATED with an argument — a nested generic is what produces a non-empty outer
# list, and the printer stops for one anyway (type-to-string-outer-type-
# parameters). It is the containment proof for the branch and its own row.''',
'''old = """            let outer this.outer_type_parameters_of(t)
            let all this.new_type_list(outer)"""
new = """            let outer this.outer_type_parameters_of(t)
            let all this.new_type_list(null)"""''')

P['h26'] = ('''# The printer's REFERENCE arm removed. PREDICTION: TREFPIN RED with every generic
# name becoming `?`, and NOTHING else moving anywhere — the type is built either
# way. The clearest statement that this battery has an instrument the other seven
# did not.''',
'''old = """        if (t.object_flags & ObjectFlagsReference) <> 0
            return this.type_reference_to_type_node(t, out)"""
new = """        if false
            return this.type_reference_to_type_node(t, out)"""''')

P['h27'] = ('''# The printer's TYPE-PARAMETER / CLASS-OR-INTERFACE arm removed. PREDICTION:
# TREFPIN RED on every fixture — `Foo`, `Bar` and `T` all become `?`, and the
# generic names too, because the reference arm composes ITS name out of this one.
# The row that shows the two printer arms are one mechanism read twice.''',
'''old = """        if names_a_symbol
        {"""
new = """        if false
        {"""''')

P['h28'] = ('''# The printer's TYPE-ARGUMENT list dropped. PREDICTION: TREFPIN RED on
# typeref_generic alone — `Box<string>` prints `Box`. It is h13's symptom reached
# from the printer instead of from the type, and the two rows together say which
# half of a wrong name is which.''',
'''old = """        var count Checker.type_parameter_count_of(tgt)
        if na < count
            set count: na"""
new = """        var count 0
        if na < count
            set count: na"""''')

P['h29'] = ('''# getNameOfSymbolAsWritten takes declaration ZERO instead of the first one WITH a
# name. PREDICTION: UNGATED with an argument — every symbol these fixtures name
# has one declaration and it has a name. The row prices the loop; the reference
# writes it because a merged symbol can lead with a nameless declaration.''',
'''old = """                let name b.get_name_of_declaration(d as ref[AstNode])
                if name <> null
                {"""
new = """                let name b.get_name_of_declaration(d as ref[AstNode])
                if i >= 0
                {"""''')

P['h30'] = ('''# DeclarationNameToString reads the IDENTIFIER'S SCANNED TEXT instead of the
# node's SOURCE. PREDICTION: TREFPIN RED on typeref_escaped_name and on NOTHING
# else — the two differ only where a name is written with a unicode escape, which
# is exactly what that fixture is for. The row that turns *the nearest accessor
# would have worked* into a number.''',
'''old = """        let start b.skip_trivia_at(pos)
        let text b.source_slice(start, stop)
        out.append(text.data, text.length)"""
new = """        out.append(AstNode.identifier_text_of(nm), AstNode.identifier_text_length_of(nm) as size_t)"""''')

P['h31'] = ('''# The DEPRECATION guard forced TRUE — every resolved type reference counts as
# deprecated. PREDICTION: UNGATED on all seven instruments, and that is the row's
# whole point: `suggestion_count` is not read by any artifact this suite compares,
# which is the containment proof written at check_type_reference_or_import's own
# line. A row that CANNOT go red, predicted.''',
'''old = """        if this.symbol_has_a_deprecated_type_declaration(symbol as ref[Symbol])
            set suggestion_count: suggestion_count + 1"""
new = """        if true
            set suggestion_count: suggestion_count + 1"""''')

P['h32'] = ('''# get_type_parameters_for_type_reference_or_import answers null, so the
# type-argument CONSTRAINT check is never reached. PREDICTION: the STOPGATE moves
# DOWN by the check-type-argument-constraints row — the stop this slice OPENED —
# with nothing else moving. The row that prices the wall behind the check half.''',
'''old = """            let type_parameters this.get_type_parameters_for_type_reference_or_import(node)
            if this.unported_mark() <> mark
                return"""
new = """            let type_parameters null as ref[Array[ref[Type]?]]?
            if this.unported_mark() <> mark
                return"""''')

P['h33'] = ('''# The CONSTRAINT guard answers true for every parameter list, i.e. the constraint
# stop fires whenever a generic reference carries arguments. PREDICTION: the
# STOPGATE moves UP and the TREFGATE stays put — the type is already built when
# the stop is recorded. It is h32's other direction, and the pair says the guard
# is what keeps an unconstrained generic out of the largest row on the list.''',
'''old = """                if c <> null
                    return true
            }
            set i: i + 1
        }
        false
    }"""
new = """                if c = null
                    return true
            }
            set i: i + 1
        }
        false
    }"""''')


P['h34'] = ('''# THE HALF-BUILT DECLARED TYPE — the declaration's own type-parameter list is not
# consulted, so a memoised half-built class type is read as complete. PREDICTION:
# diagcheck RED by INVENTION at STAGE 2 and UNGATED at stage 1 — a TS2315 (*Type is
# not generic*) about a generic type, one unit of 18 257. The row for the face of
# this slice's second finding that no MARK can reach, because the incompleteness is
# in a memo.''',
'''old = """        if tp_count = 0
        {
            if Checker.symbol_declares_type_parameters(symbol)
            {
                this.record_unported("incomplete-declared-type", 0)
                return null
            }
        }"""
new = """        if false
        {
            if Checker.symbol_declares_type_parameters(symbol)
            {
                this.record_unported("incomplete-declared-type", 0)
                return null
            }
        }"""''')

P['h35'] = ('''# THE MARK AROUND THE DECLARED TYPE — get_declared_type_of_class_or_interface's
# stop is not seen, so a class type it abandoned mid-build is used. PREDICTION:
# STOPGATE moved and, at stage 2, whatever h34 does not already catch — the two
# rows are the same hazard reached on the FIRST visit and on a LATER one, and only
# the first has a mark to read.''',
'''old = """        let declared_mark this.unported_mark()
        let dt this.get_declared_type_of_class_or_interface(merged as ref[Symbol])
        if this.unported_mark() <> declared_mark
            return null"""
new = """        let declared_mark this.unported_mark()
        let dt this.get_declared_type_of_class_or_interface(merged as ref[Symbol])
        if false
            return null"""''')

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

control "h01 THE PREMISE (the dispatcher half) - the KindTypeReference arm reverted to its stop" $CHECKER "$PATCHDIR/h01.py"
control "h02 THE PREMISE (the check half) - checkTypeReferenceOrImport reverted to its stop" $CHECKER "$PATCHDIR/h02.py"
control "h03 THE MARK - get_type_from_type_reference uses the sticky is_unported()" $CHECKER "$PATCHDIR/h03.py"
control "h04 resolve_entity_name drops get_merged_symbol" $CHECKER "$PATCHDIR/h04.py"
control "h05 resolve_entity_name passes NO message - the reporting half off" $CHECKER "$PATCHDIR/h05.py"
control "h06 the ALIAS guard removed" $CHECKER "$PATCHDIR/h06.py"
control "h07 resolve_type_reference_name answers null instead of unknownSymbol" $CHECKER "$PATCHDIR/h07.py"
control "h08 get_symbol_from_type_reference memo always misses (BOTH halves)" $CHECKER "$PATCHDIR/h08.py"
control "h09 get_type_from_type_reference memo always misses" $CHECKER "$PATCHDIR/h09.py"
control "h10 the `as const` arm removed" $CHECKER "$PATCHDIR/h10.py"
control "h11 getIntendedTypeFromJSDocTypeReference never fires" $CHECKER "$PATCHDIR/h11.py"
control "h12 getTypeReferenceType unknownSymbol arm removed" $CHECKER "$PATCHDIR/h12.py"
control "h13 the Class/Interface arm removed" $CHECKER "$PATCHDIR/h13.py"
control "h14 the TYPE-ALIAS stop removed" $CHECKER "$PATCHDIR/h14.py"
control "h15 THE TWO NILS - getTypeReferenceType ignores the mark" $CHECKER "$PATCHDIR/h15.py"
control "h16 checkNoTypeArguments always answers true" $CHECKER "$PATCHDIR/h16.py"
control "h17 hasTypeParameterDefault always false" $CHECKER "$PATCHDIR/h17.py"
control "h18 the arity message fork forced to the fixed-arity code" $CHECKER "$PATCHDIR/h18.py"
control "h19 the too-many-arguments comparison removed" $CHECKER "$PATCHDIR/h19.py"
control "h20 isDeferredTypeReferenceNode alias disjunct removed" $CHECKER "$PATCHDIR/h20.py"
control "h21 isResolvedByTypeAlias never climbs" $CHECKER "$PATCHDIR/h21.py"
control "h22 mayResolveTypeAlias TypeReference arm answers false" $CHECKER "$PATCHDIR/h22.py"
control "h23 fillMissingTypeArguments never fills" $CHECKER "$PATCHDIR/h23.py"
control "h24 fillMissingTypeArguments default never instantiated" $CHECKER "$PATCHDIR/h24.py"
control "h25 the OUTER type parameters are not prepended" $CHECKER "$PATCHDIR/h25.py"
control "h26 the printer REFERENCE arm removed" $CHECKER "$PATCHDIR/h26.py"
control "h27 the printer TYPE-PARAMETER / CLASS-OR-INTERFACE arm removed" $CHECKER "$PATCHDIR/h27.py"
control "h28 the printer TYPE-ARGUMENT list dropped" $CHECKER "$PATCHDIR/h28.py"
control "h29 getNameOfSymbolAsWritten takes declaration ZERO" $CHECKER "$PATCHDIR/h29.py"
control "h30 DeclarationNameToString reads the identifier TEXT, not the SOURCE" $CHECKER "$PATCHDIR/h30.py"
control "h31 the DEPRECATION guard forced true" $CHECKER "$PATCHDIR/h31.py"
control "h32 the type-argument CONSTRAINT check never reached" $CHECKER "$PATCHDIR/h32.py"
control "h33 the CONSTRAINT guard inverted" $CHECKER "$PATCHDIR/h33.py"
control "h34 THE HALF-BUILT DECLARED TYPE - the declaration is not consulted" $CHECKER "$PATCHDIR/h34.py"
control "h35 the MARK around the declared type removed" $CHECKER "$PATCHDIR/h35.py"

echo
echo "################################################################"
bold "DONE - read every row against its PREDICTION, not against its colour."
