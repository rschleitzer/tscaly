#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice96.sh — the slice-96 battery: THE PROPERTY ACCESS.
#
# ★★★ THE ROW THIS SLICE CLOSES IS THE LARGEST ONE THAT IS NOT THE GLOBALS TABLE.
# `check-property-access-expression 212` was 366 events over 150 units at stage 1
# and 3 515 units at stage 2, and it had THREE producers rather than one: the
# dispatcher's PropertyAccessExpression arm, its QualifiedName arm, and the
# compound assignment's getter/setter re-read in check_binary_expression. h01 and
# h02 are the two premises that carry the corpus.
#
# ★★★ THE NINTH INSTRUMENT, AND THE ARGUMENT IS SLICE 95'S ONE PRODUCT ON. The T
# section is all-or-nothing per unit, so this chapter's product — *which member a
# name picked out of a members table, and what type that access then answers* — is
# invisible on every unit that still has any other wall, which at stage 1 is 1 480
# of 1 494. `tscaly_types --props` prints `P <pos> <end> <symbolflags>
# <apparentid> <typeid> <name>` per RESOLVED property access, and the three middle
# columns are the three things that can go wrong SEPARATELY: which member, on what
# receiver, answering what. A pin with only the last of the three cannot tell a
# wrong receiver from a wrong narrowing.
#
# ★★★ AND THE FINDING THE INSTRUMENT MADE BEFORE A SINGLE CONTROL RAN: over the
# 1 403 units of the tree the PROPGATE reads **13, ALL THIRTEEN FROM THE SEVEN
# FIXTURES THIS SLICE ADDS.** The real corpus contributes ZERO. Every one of the
# 366 arrivals stops at its own RECEIVER — 135 at `resolve-name-not-found` (§3.11's
# globals table) and 95 at `check-this-expression` — so the chapter answers and the
# corpus cannot feed it. **Those are two different states and only a pin tells them
# apart**: the stop log says the row closed, and without this gate that would read
# as coverage.
#
# ★★★ AND THE GATE'S OWN FIRST VERSION MEASURED THE WRONG THING FOR FIFTEEN ROWS.
# It was written by copying slice 95's battery and renaming; the rename applied to
# the PIN and silently did not apply to the GATE, so `propgate` ran `--typerefs`,
# grepped `^X ` and reported **666 1 <cksum>** — a plausible number, stable across
# rows, moving on h01 exactly as a working gate would. **A relabelled instrument is
# indistinguishable from a working one unless its value is checked against a hand
# count**, and the hand count is what caught it: 13 against 666. The rule this
# costs: after copying a battery, run each gate once by hand and compare.
#
# ★★★ ITERATE AT STAGE 1 AND CONFIRM AT STAGE 2 ONCE — slice 64's rule. The
# recorded verdicts are stage 1's.
#
# Usage (nothing may edit the tree while this runs, and no second harness may own
# tests/out — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # stage 1
#   packages/tscaly/tests/controls-slice96.sh 2>&1 | tee /tmp/battery96.log
#
set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.0/tscaly/checker.scaly
FIX=$PKG/tests/fixtures

LIBSCALY=${LIBSCALY:-/tmp/libscaly.a}
SCALYC=${SCALYC:-$REPO/scalyc/build/scalyc}

# ★ ONE MECHANISM PER FILE (slice 72's rule). Eight files, all this slice's: the
# named half, the accessibility half, the readonly assignment, the three walls,
# the flow fork, the deprecation branch, the second head that has no input, and
# the GENERIC receiver — the eighth added after stage 2 found an exit 21 that the
# other seven could not reach.
PINFILES="
$FIX/propaccess_member.ts
$FIX/propaccess_accessibility.ts
$FIX/propaccess_readonly.ts
$FIX/propaccess_stops.ts
$FIX/propaccess_flow.ts
$FIX/propaccess_deprecated.ts
$FIX/propaccess_qualified.ts
$FIX/propaccess_generic.ts
"
# ★★★ EVERY DUMPER CALL BELOW RUNS UNDER A TIME LIMIT, for slice 95's reason:
# breaking one bit of a printer can remove the BASE CASE of its own recursion, and
# a process that grows until the machine does is a verdict a battery cannot produce
# without one. `perl -e 'alarm N; exec @ARGV'` is on every box this repo builds on
# and kills at N seconds with rc 142; timeout(1) is not on macOS.
#
# ★★ THE LIMIT IS PART OF THE MEASUREMENT: a killed call writes nothing, so the pin
# and the gate both MOVE, which is the honest verdict for a patch that makes the
# port not terminate.
LIMIT=${LIMIT:-3}
run_limited() { perl -e 'alarm shift; exec @ARGV' "$LIMIT" "$@"; }

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl96)

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

# ★★★ THE PROPPIN — slice 96's NINTH instrument; the argument is in PropEvent's
# own header. `P <pos> <end> <symbolflags> <apparentid> <typeid> <name>` per
# RESOLVED property access, in the order the check reached them.
proppin_of() {
  local f
  for f in $PINFILES; do
    printf '%s	%s
' "$(basename "$f")" \
      "$(run_limited "$WORK/tscaly_types" --props "$f" 2>/dev/null | tr '
' '|')"
  done
}

# ★★★ THE WHOLE-CORPUS PROPGATE, and it is here beside the pin for slice 92's
# h08/h11/h25 reason: a fixture is written around the arm its author is thinking
# of, and the shape that distinguishes an arm is usually not that shape. ★★It
# reads ZERO on the real corpus and that is not a defect in the gate — it is this
# slice's largest finding, recorded at the top of this file. What it therefore
# gates is the SEVEN fixtures plus every unit of the corpus staying at zero, which
# a patch that invents an answer would move.
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
propgate() {
  local i=0 u
  rm -rf "$WORK/tout" "$WORK/tpairs"; mkdir -p "$WORK/tout"
  while IFS= read -r u; do
    printf '%s\0%s\0' "$u" "$(printf '%s/tout/%06d' "$WORK" "$i")"
    i=$((i+1))
  done < "$WORK/units.txt" > "$WORK/tpairs"
  LIMIT=$LIMIT xargs -0 -P 8 -n 2 sh -c 'perl -e "alarm $LIMIT; exec @ARGV" "$0" --props "$1" > "$2" 2>/dev/null' "$WORK/tscaly_types" < "$WORK/tpairs"
  find "$WORK/tout" -type f -print0 | xargs -0 cat > "$WORK/props.all"
  local n q
  n=$(grep -c '^P ' "$WORK/props.all")
  q=$(grep -c ' ?$' "$WORK/props.all")
  echo "$n $q $(cksum < "$WORK/props.all" | cut -d' ' -f1)"
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

DIAG_BASE=""; DIAG_LINES=""; DIAG_DIAGS=""; STOP_BASE=""; PROP_BASE=""

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
  proppin_of > "$WORK/base.props"
  find "$PKG/tests/out/cases" -path '*/units/*' -type f \
       \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.mjs' -o -name '*.cjs' \) \
       | sort > "$WORK/units.txt"
  STOP_BASE=$(stopgate)
  PROP_BASE=$(propgate)
  echo
  echo "  the STOPPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.stops"
  echo
  echo "  the TAGPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.tags"
  echo
  echo "  the PROPPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.props"
  echo
  echo "  BASELINE   diagcheck $DIAG_BASE consistent, $DIAG_LINES speaking, $DIAG_DIAGS diagnostics"
  echo "             stopgate  (matched units speaking events other) = $STOP_BASE"
  echo "             propgate  (properties unnamed checksum) over $(wc -l < "$WORK/units.txt" | tr -d ' ') units = $PROP_BASE"
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
  proppin_of > "$WORK/ctl.props"
  stop=$(stopgate)
  local prop
  prop=$(propgate)
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
  if cmp -s "$WORK/base.props" "$WORK/ctl.props"; then
    echo "  proppin   unmoved — all eight fixtures resolve the same members to the same types."
  else
    green "proppin   RED"
    diff "$WORK/base.props" "$WORK/ctl.props" | cut -c1-240 | sed 's/^/    /'
    moved=1
  fi
  if [ "$stop" = "$STOP_BASE" ]; then
    echo "  stopgate  unmoved — $stop"
  else
    green "stopgate  MOVED   $STOP_BASE -> $stop   (matched units speaking events other)"
    moved=1
  fi
  if [ "$prop" = "$PROP_BASE" ]; then
    echo "  propgate  unmoved — $prop"
  else
    green "propgate  MOVED   $PROP_BASE -> $prop   (properties unnamed checksum)"
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

python3 - "$PATCHDIR" <<'MKPATCHES'
import os, sys
D = sys.argv[1]
os.makedirs(D, exist_ok=True)

P = {}

P['h01'] = ('''# THE PREMISE (the dispatcher's PropertyAccessExpression arm) reverted to the stop
# it was until this slice. PREDICTION: TAGPIN + STOPPIN + PROPPIN RED on every
# fixture and the PROPGATE's count to ZERO. One of TWO premises, because the row
# this slice closes had more than one producer.''',
'''old = """        if k = KindPropertyAccessExpression
            return this.check_property_access_expression(node, check_mode, false)"""
new = """        if k = KindPropertyAccessExpression
        {
            this.record_unported("check-property-access-expression", k)
            return null
        }"""''')

P['h02'] = ('''# THE PREMISE (the dispatcher's QualifiedName arm) reverted to its stop.
# PREDICTION: UNGATED ON ALL SEVEN, PREDICTED — `check-qualified-name` was 0
# events over 0 units before this slice and propaccess_qualified.ts is the fixture
# that says why: a QualifiedName reaches checkExpression only from shapes whose own
# chapter stops first. A row that CANNOT go red, with the containment proof at its
# own line.''',
'''old = """        if k = KindQualifiedName
            return this.check_qualified_name(node, check_mode)"""
new = """        if k = KindQualifiedName
        {
            this.record_unported("check-qualified-name", k)
            return null
        }"""''')

P['h03'] = ('''# THE OPTIONAL-CHAIN GUARD removed, so `s?.a` falls into the plain path instead of
# the row. PREDICTION: STOPPIN RED on propaccess_stops.ts with the stop count
# DROPPING and the PROPPIN moving — an optional chain answered as a plain access is
# a well-formed WRONG answer, which is the shape only a pin can see.''',
'''old = """        if (AstNode.flags_of(node) & NodeFlagsOptionalChain) <> 0
        {
            this.record_unported("check-property-access-chain", AstNode.kind_of(node))
            return null
        }"""
new = """        if false
        {
            this.record_unported("check-property-access-chain", AstNode.kind_of(node))
            return null
        }"""''')

P['h04'] = ('''# checkNonNullExpression replaced by checkExpression — the non-null check off.
# PREDICTION: the STOPGATE moves, because the facts walk is what reports
# TS18047/TS18048 and stops at get-non-nullable-type; the PROPPIN should NOT move,
# since none of these fixtures has a nullable receiver. The row separates the
# receiver CHECK from the receiver TYPE.''',
'''old = """        let lt this.check_non_null_expression(e)
        if lt = null
            return null
        this.check_property_access_expression_or_qualified_name(node, e, lt as ref[Type], AstNode.name_of(node), check_mode, write_only)"""
new = """        let lt this.check_expression(e)
        if lt = null
            return null
        this.check_property_access_expression_or_qualified_name(node, e, lt as ref[Type], AstNode.name_of(node), check_mode, write_only)"""''')

P['h05'] = ('''# THE WIDENING never happens. PREDICTION: ungated with an argument — every
# receiver in these fixtures is already a widened object type, so getWidenedType is
# the identity for all of them. The row prices the step rather than closing it, and
# a corpus that moves it is a corpus with a fresh literal receiver.''',
'''old = """        if widen = false
            set widen: Checker.is_method_access_for_call(node)"""
new = """        if false
            set widen: Checker.is_method_access_for_call(node)
        set widen: false"""''')

P['h06'] = ('''# THE WIDENING always happens. PREDICTION: the other direction of h05, and it is
# the one that can INVENT — widening a fresh literal type answers the base type,
# so a fixture whose property has a literal type would move the PROPPIN's NAME
# column at an unchanged count.''',
'''old = """        var widen false
        if assignment_kind <> AssignmentKindNone
            set widen: true"""
new = """        var widen true
        if assignment_kind <> AssignmentKindNone
            set widen: true"""''')

P['h07'] = ('''# isMethodAccessForCall never climbs the parentheses. PREDICTION: ungated with an
# argument — `(p.m)()` is the only shape the loop is for, and no fixture writes
# one. The row is the containment proof for a loop that would otherwise be
# untested code.''',
'''old = """        var n node
        var climbing true
        while climbing
        {
            set climbing: false
            let p AstNode.parent_node_of(n)
            if p <> null
            {
                if AstNode.kind_of(p as ref[AstNode]) = KindParenthesizedExpression
                {
                    set n: p as ref[AstNode]
                    set climbing: true
                }
            }
        }"""
new = """        var n node"""''')

P['h08'] = ('''# getApparentType SKIPPED — the lookup runs on the widened type directly.
# PREDICTION: PROPPIN RED in the APPARENT-ID column with the names unchanged
# wherever the two types coincide, which is exactly the column slice 96 added for.
# A three-column pin is what makes this row distinguishable from h05.''',
'''old = """        let ap this.get_apparent_type(widened)
        if ap = null
            return null
        let apparent ap as ref[Type]"""
new = """        let ap widened
        let apparent ap as ref[Type]"""''')

P['h09'] = ('''# The is_any_like EARLY RETURN removed, so an `any` receiver falls through to the
# members lookup. PREDICTION: STOPPIN RED — `any` has no members table, so the
# lookup reaches getReducedApparentType's own arms and stops there instead of
# answering. The row says the early return is an ANSWER and not an optimisation.''',
'''old = """        if is_any_like
        {
            if this.is_error_type(apparent)
                return error_type
            return apparent
        }"""
new = """        if false
        {
            if this.is_error_type(apparent)
                return error_type
            return apparent
        }"""''')

P['h10'] = ('''# The PRIVATE-identifier stop removed, so `other.#hidden` falls into the ordinary
# lookup. PREDICTION: STOPPIN RED on propaccess_stops.ts and the PROPPIN moving —
# a private name IS in the members table under its 0xFE-prefixed spelling (slice
# 41), so the ordinary lookup answers something, and answering something is worse
# than stopping when the four reports behind the row have not been written.''',
'''old = """            this.record_unported("check-private-identifier-property-access", KindPrivateIdentifier)
            return null"""
new = """            if false
                return null"""''')

P['h11'] = ('''# getPropertyOfTypeEx never consults the members table. PREDICTION: PROPPIN to
# ZERO and STOPPIN RED with `global-object-property-augment` on every fixture —
# the second premise of this chapter, and the row that says the whole product is
# one table lookup.''',
'''old = """            let sym SymbolTable.get((sm as ref[StructuredMembers]).members, d, n)
            if sym <> null
            {
                if include_type_only_members = false"""
new = """            var sym: ref[Symbol]? null
            if false
            {
                if include_type_only_members = false"""''')

P['h12'] = ('''# getPropertyOfTypeEx ignores symbolIsValue, so a TYPE-only member answers as a
# value. PREDICTION: ungated with an argument — every member in these fixtures is
# a value, and the alias walk behind symbolIsValue is a stop either way
# (`get-symbol-flags-alias`). The row prices the guard.''',
'''old = """                if this.symbol_is_value(sym as ref[Symbol])
                    return sym
            }
            if skip_object_function_property_augment"""
new = """                if true
                    return sym
            }
            if skip_object_function_property_augment"""''')

P['h13'] = ('''# The typeOnlyExportStarMap guard removed. PREDICTION: ungated with an argument —
# it fires only for a name found in the members of a VALUE MODULE's type, i.e.
# `export type * from` seen through `import * as ns`, and no fixture writes one.
# The row is the containment proof §3.5bk asks of an arm that reports.''',
'''old = """                        if (Symbol.flags_of(owner as ref[Symbol]) & SymbolFlagsValueModule) <> 0
                        {
                            this.record_unported("type-only-export-star-map", Symbol.flags_of(owner as ref[Symbol]))
                            return null
                        }"""
new = """                        if false
                        {
                            this.record_unported("type-only-export-star-map", Symbol.flags_of(owner as ref[Symbol]))
                            return null
                        }"""''')

P['h14'] = ('''# The skipObjectFunctionPropertyAugment argument forced TRUE, so a missing name
# answers nil instead of reaching the lib wall. PREDICTION: STOPPIN RED on
# propaccess_stops.ts with `global-object-property-augment` GONE and
# `report-nonexistent-property` still there — the pair is a chain, and this row is
# what proves the first is the wall and the second the consequence.''',
'''old = """        let prop this.get_property_of_type_ex(apparent, AstNode.identifier_text_of(r), AstNode.identifier_text_length_of(r), Checker.is_const_enum_object_type(apparent), AstNode.kind_of(node) = KindQualifiedName)"""
new = """        let prop this.get_property_of_type_ex(apparent, AstNode.identifier_text_of(r), AstNode.identifier_text_length_of(r), true, AstNode.kind_of(node) = KindQualifiedName)"""''')

P['h15'] = ('''# checkPropertyNotUsedBeforeDeclaration never runs. PREDICTION: STOPPIN RED —
# both of its branches end at isBlockScopedNameDeclaredBeforeUse, so the row
# measures how many property accesses reach that walk, which is the number the work
# list needs to price the successor.''',
'''old = """        this.check_property_not_used_before_declaration(p, node, r)"""
new = """        if false
            this.check_property_not_used_before_declaration(p, node, r)"""''')

P['h16'] = ('''# The resolvedSymbol slot is not written. PREDICTION: PROPPIN RED on
# propaccess_member.ts alone, at the CHAIN — `o.inner.x` reads what `o.inner`
# wrote, and nothing else in these fixtures asks. The row is the reader §3.5be
# demands of a slot, made visible.''',
'''old = """        let links this.symbol_node_link_of(node)
        set links.resolved_symbol: p"""
new = """        let links this.symbol_node_link_of(node)
        if false
            set links.resolved_symbol: p"""''')

P['h17'] = ('''# checkPropertyAccessibility always answers true — the whole family off.
# PREDICTION: DIAGPIN RED and diagcheck ungated at a LOSS, since TS2341 is a line
# the reference has and we would stop printing. The row that shows which half of
# this battery a subsequence relation can see.''',
'''old = """        this.check_property_accessibility(node, is_super, Checker.is_write_access(node), apparent, p)"""
new = """        if false
            this.check_property_accessibility(node, is_super, Checker.is_write_access(node), apparent, p)"""''')

P['h18'] = ('''# The NonPublicAccessibilityModifier EXIT removed, so a public member walks into
# the private and protected arms. PREDICTION: STOPPIN RED with
# `is-class-derived-from-declaring-classes` arriving on every fixture that has a
# class — the exit is what keeps the unported protected walk off the path of every
# public access, and this row is the number behind that sentence.''',
'''old = """        if (flags & ModifierFlagsNonPublicAccessibilityModifier) = 0
            return true"""
new = """        if false
            return true"""''')

P['h19'] = ('''# isNodeWithinClass always answers TRUE, so a private member is accessible
# everywhere. PREDICTION: DIAGPIN RED at a LOSS on propaccess_accessibility.ts —
# TS2341 disappears and nothing else moves, which is the narrowest possible reading
# of what that report is about.''',
'''old = """        var containing Checker.get_containing_class(node)
        while containing <> null
        {
            if containing = class_declaration
                return true"""
new = """        var containing Checker.get_containing_class(node)
        if true
            return true
        while containing <> null
        {
            if containing = class_declaration
                return true"""''')

P['h20'] = ('''# getDeclarationModifierFlagsFromSymbolEx ignores isWrite. PREDICTION: ungated
# with an argument — an accessor PAIR whose two halves carry different modifiers is
# the only input, and propaccess_flow.ts has a get-only accessor whose own type is
# a wall one call earlier. The row prices the parameter this slice added.''',
'''old = """        if is_write
        {
            let n Symbol.declaration_count(s)
            var i 0
            while i < n
            {
                let d Symbol.declaration_at(s, i)
                if d <> null
                {
                    if AstNode.kind_of(d as ref[AstNode]) = KindSetAccessor"""
new = """        if false
        {
            let n Symbol.declaration_count(s)
            var i 0
            while i < n
            {
                let d Symbol.declaration_at(s, i)
                if d <> null
                {
                    if AstNode.kind_of(d as ref[AstNode]) = KindSetAccessor"""''')

P['h21'] = ('''# isAssignmentToReadonlyEntity always answers false. PREDICTION: DIAGPIN RED at a
# LOSS on propaccess_readonly.ts — TS2540 goes, and the PROPPIN gains a row,
# because the readonly branch RETURNS errorType and therefore writes no pin entry.
# Two instruments moving in opposite directions on one patch.''',
'''old = """        if assignment_kind = AssignmentKindNone
            return false
        if Parser.is_access_expression(expr)"""
new = """        if true
            return false
        if Parser.is_access_expression(expr)"""''')

P['h22'] = ('''# The isThisPropertyAccessInConstructor autoType arm removed. PREDICTION: ungated
# with an argument — it needs an auto-typed property, which is a `.js` shape or a
# `noImplicitAny` class field with neither annotation nor initializer, and the
# constructor walk in front of it is a stop for the CommonJS form. The row is the
# containment proof for a fork this slice guards down to its input.''',
'''old = """        if this.is_this_property_access_in_constructor(node, p)
            set prop_type: auto_type"""
new = """        if false
            set prop_type: auto_type"""''')

P['h23'] = ('''# getWriteTypeOfSymbol replaced by getTypeOfSymbol at the write fork. PREDICTION:
# ungated with an argument on these fixtures — the two answers differ only for a
# SYNTHETIC property or an accessor, and both stop one call in. It prices the fork
# rather than closing it, and names the shape that would move it.''',
'''old = """            if write
                set prop_type: this.get_write_type_of_symbol(p)"""
new = """            if write
                set prop_type: this.get_type_of_symbol(p)"""''')

P['h24'] = ('''# getFlowTypeOfAccessExpression's NON-NARROWABLE early-out removed, so a method
# access walks the flow graph. PREDICTION: PROPPIN RED on propaccess_member.ts's
# method row and probably a STOPPIN move — the early-out is where most answers
# leave, and the row is the number behind that sentence.''',
'''old = """                if method_union = false
                    return prop_type"""
new = """                if false
                    return prop_type"""''')

P['h25'] = ('''# The assumeUninitialized block never fires. PREDICTION: ungated with an argument
# at stage 1 — TS2565 needs `this.x` in a constructor of the declaring class, and
# every `this.` access in this corpus stops at checkThisExpression, which is this
# slice's named successor. The row prices the successor from this chapter's side.''',
'''old = """        let assume_uninitialized this.assume_property_uninitialized(node, prop)"""
new = """        let assume_uninitialized false"""''')

P['h26'] = ('''# The assignment-kind getBaseTypeOfLiteralType tail removed. PREDICTION: PROPPIN
# RED on propaccess_readonly.ts's compound assignment — an assignment target
# answers the BASE type, not the literal one, and the pin's NAME column is the only
# place in this tree that shows the difference.''',
'''old = """        if assignment_kind <> AssignmentKindNone
            return this.get_base_type_of_literal_type(flow_type)
        flow_type"""
new = """        if false
            return this.get_base_type_of_literal_type(flow_type)
        flow_type"""''')

P['h27'] = ('''# accessKind's PropertyAccessExpression arm answers Read instead of recursing.
# PREDICTION: DIAGPIN RED on propaccess_readonly.ts — `f.r = 1` asks accessKind
# about the NAME `r`, whose parent is the access itself, so without the recursion
# every write reads as a read and TS2540 goes. The arm that looks like a detail is
# the one the whole write side stands on.''',
'''old = """        if k = KindPropertyAccessExpression
        {
            if AstNode.name_of(parent) <> node
                return AccessKindRead
            return Checker.access_kind(parent)
        }"""
new = """        if k = KindPropertyAccessExpression
            return AccessKindRead"""''')

P['h28'] = ('''# The deprecation branch never fires. PREDICTION: UNGATED ON ALL SEVEN, PREDICTED
# — `suggestion_count` is read by no artifact this suite compares, exactly as slice
# 95's h31 recorded for the type reference. A row that CANNOT go red, and the
# containment proof written at its own line.''',
'''old = """        this.check_deprecated_property(p, node, r)"""
new = """        if false
            this.check_deprecated_property(p, node, r)"""''')

P['h29'] = ('''# isDeprecatedSymbol's every/some fork INVERTED. PREDICTION: ungated for h28's
# reason — the counter has no reader here — and the row is in the table because a
# reader who sees h28 green must be told that the fork BELOW it is untested for the
# same reason, not for a different one.''',
'''old = """                if (Symbol.flags_of(parent_symbol as ref[Symbol]) & SymbolFlagsInterface) <> 0
                    return this.some_declaration_is_deprecated(symbol)
                return this.every_declaration_is_deprecated(symbol)"""
new = """                if (Symbol.flags_of(parent_symbol as ref[Symbol]) & SymbolFlagsInterface) <> 0
                    return this.every_declaration_is_deprecated(symbol)
                return this.some_declaration_is_deprecated(symbol)"""''')

for k, (doc, body) in P.items():
    with open(os.path.join(D, k + '.py'), 'w') as f:
        f.write(doc + '\n')
        f.write('''import sys
''')
        f.write(body + '\n')
        f.write('''
path = sys.argv[1]
s = open(path).read()
if s.count(old) != 1:
    sys.stderr.write("anchor count %d for %s\\n" % (s.count(old), path))
    sys.exit(1)
open(path, 'w').write(s.replace(old, new))
''')
MKPATCHES

baseline

control "h01 THE PREMISE (the dispatcher's PropertyAccess arm) reverted to its stop" $CHECKER "$PATCHDIR/h01.py"
control "h02 THE PREMISE (the dispatcher's QualifiedName arm) reverted to its stop" $CHECKER "$PATCHDIR/h02.py"
control "h03 the OPTIONAL-CHAIN guard removed" $CHECKER "$PATCHDIR/h03.py"
control "h04 checkNonNullExpression replaced by checkExpression" $CHECKER "$PATCHDIR/h04.py"
control "h05 the WIDENING never happens" $CHECKER "$PATCHDIR/h05.py"
control "h06 the WIDENING always happens" $CHECKER "$PATCHDIR/h06.py"
control "h07 isMethodAccessForCall never climbs the parentheses" $CHECKER "$PATCHDIR/h07.py"
control "h08 getApparentType SKIPPED" $CHECKER "$PATCHDIR/h08.py"
control "h09 the is_any_like EARLY RETURN removed" $CHECKER "$PATCHDIR/h09.py"
control "h10 the PRIVATE-identifier stop removed" $CHECKER "$PATCHDIR/h10.py"
control "h11 getPropertyOfTypeEx never consults the members table" $CHECKER "$PATCHDIR/h11.py"
control "h12 getPropertyOfTypeEx ignores symbolIsValue" $CHECKER "$PATCHDIR/h12.py"
control "h13 the typeOnlyExportStarMap guard removed" $CHECKER "$PATCHDIR/h13.py"
control "h14 skipObjectFunctionPropertyAugment forced TRUE" $CHECKER "$PATCHDIR/h14.py"
control "h15 checkPropertyNotUsedBeforeDeclaration never runs" $CHECKER "$PATCHDIR/h15.py"
control "h16 the resolvedSymbol slot is not written" $CHECKER "$PATCHDIR/h16.py"
control "h17 checkPropertyAccessibility always answers true" $CHECKER "$PATCHDIR/h17.py"
control "h18 the NonPublicAccessibilityModifier EXIT removed" $CHECKER "$PATCHDIR/h18.py"
control "h19 isNodeWithinClass always answers TRUE" $CHECKER "$PATCHDIR/h19.py"
control "h20 getDeclarationModifierFlagsFromSymbolEx ignores isWrite" $CHECKER "$PATCHDIR/h20.py"
control "h21 isAssignmentToReadonlyEntity always answers false" $CHECKER "$PATCHDIR/h21.py"
control "h22 the isThisPropertyAccessInConstructor autoType arm removed" $CHECKER "$PATCHDIR/h22.py"
control "h23 getWriteTypeOfSymbol replaced by getTypeOfSymbol" $CHECKER "$PATCHDIR/h23.py"
control "h24 getFlowTypeOfAccessExpression NON-NARROWABLE early-out removed" $CHECKER "$PATCHDIR/h24.py"
control "h25 the assumeUninitialized block never fires" $CHECKER "$PATCHDIR/h25.py"
control "h26 the assignment-kind getBaseTypeOfLiteralType tail removed" $CHECKER "$PATCHDIR/h26.py"
control "h27 accessKind's PropertyAccess arm answers Read" $CHECKER "$PATCHDIR/h27.py"
control "h28 the deprecation branch never fires" $CHECKER "$PATCHDIR/h28.py"
control "h29 isDeprecatedSymbol every/some fork INVERTED" $CHECKER "$PATCHDIR/h29.py"

echo
echo "################################################################"
bold "DONE - read every row against its PREDICTION, not against its colour."
