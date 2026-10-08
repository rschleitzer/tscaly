#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice94.sh — the slice-94 battery: THE UNION TYPE.
#
# ★★★ THE SLICE HAS TWO PRODUCTS AND THEY NEED DIFFERENT INSTRUMENTS, WHICH IS WHY
# THIS BATTERY CARRIES EIGHT. The union MACHINERY — CompareTypes, the sorted
# insert, the reduction, the interning, formatUnionTypes — answers a TYPE, and no
# artifact in this directory prints one: the T section is emitted only for a unit
# whose check COMPLETES, and 14 of 1 481 do. The union's CALLER —
# checkPropertyInitialization — answers a DIAGNOSTIC, and 836 of them. A battery
# graded on diagnostics would call half these rows indistinguishable, and one
# graded on the stop log would call the other half indistinguishable.
#
# ★★★ SO THE SEVENTH INSTRUMENT IS THE UNIONPIN AND THE EIGHTH IS ITS GATE, and
# that is slice 93's own lesson arriving one product on: *a claim that something is
# unobservable is a claim about an INSTRUMENT*. `tscaly_types --unions` prints
# `U <id> <flags> <objectflags> <name>` per interned union — the ID column sees the
# interning, the FLAGS column sees the one bit that makes booleanType a keyword,
# and the NAME column is the only thing in this tree that can see CompareTypes'
# ORDER and formatUnionTypes at all.
#
# ★★★ ITERATE AT STAGE 1 AND CONFIRM AT STAGE 2 ONCE — slice 64's rule, and this
# slice is the one that pays for it again: `maybe_type_of_kind`'s missing union
# recursion invented three TS2355 in 18 249 stage-2 units and NONE of the 1 481 at
# stage 1. h23 is that finding as a control, and `union_maybe_void.ts` is the
# reduction that brings it back to stage 1.
#
# The recorded verdicts are stage 1's.
#
# Usage (nothing may edit the tree while this runs, and no second harness may own
# tests/out — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # stage 1
#   packages/tscaly/tests/controls-slice94.sh 2>&1 | tee /tmp/battery94.log
#
set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.1/tscaly/checker.scaly
FIX=$PKG/tests/fixtures

. packages/tscaly/tests/toolchain.sh || exit 2

# ★ ONE MECHANISM PER FILE (slice 72's rule). Nine files: the seven this slice
# wrote, plus two of slice 93's — `flowwalk_uninitialized.ts`, which is the NINTH
# DOOR that slice named and this one opens, and `flowwalk_matching.ts`, whose
# assignments are what isMatchingReference's new property-access arm has to agree
# with.
PINFILES="
$FIX/union_boolean.ts
$FIX/union_optional.ts
$FIX/union_reduction.ts
$FIX/union_maybe_void.ts
$FIX/propinit_missing.ts
$FIX/propinit_assigned.ts
$FIX/propinit_computed.ts
$FIX/flowwalk_uninitialized.ts
$FIX/flowwalk_matching.ts
"
# ★★★ EVERY DUMPER CALL BELOW RUNS UNDER A TIME LIMIT, AND THE ROW THAT FORCED IT
# IS h06. Breaking one bit — TypeFlagsBoolean on the two-boolean-literal union —
# does not merely change a printed NAME: it removes the BASE CASE of the printer's
# recursion, so `type_to_string` -> `format_union_types` -> collapse to booleanType
# -> `type_to_string` never terminates and the process grows until the machine
# does. §3.5ec recorded this gap and did not close it (*"run.sh runs both dumpers
# with no time limit, so a control that loops is bounded by RAM rather than by the
# harness ... timeout(1) is not on macOS"*); `perl -e 'alarm N; exec @ARGV'` is on
# every box this repo builds on, costs ~10 ms and kills at N seconds with rc 142.
#
# ★★ THE LIMIT IS PART OF THE MEASUREMENT AND NOT A CONVENIENCE. A killed call
# writes nothing, so the pin and the gate both MOVE — which is the honest verdict
# for a patch that makes the port not terminate, and is a verdict the battery could
# not produce at all before.
#
# ★★★ THREE SECONDS, AND THE NUMBER IS MEASURED RATHER THAN GUESSED — a limit that
# trips on a slow unit turns a measurement into a flake. Over a 250-unit sample of
# the stage-1 corpus the SLOWEST `--unions` call is **44 ms**, so this is 68x the
# worst legitimate case. ★It is also the row's own cost: under h06 every unit with a
# boolean loops, so the UNIONGATE pays the limit 1 480 times eight-wide — about nine
# minutes for that one row, against ninety seconds for every other.
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
  "$SCALYC" -c --no-prelude -o "$WORK/pkg.o" "$PKG/0.1.1/tscaly.scaly" > "$WORK/build.log" 2>&1 || return 1
  "$SCALYC" -c -o "$WORK/types.o" "$PKG/0.1.1/tscaly_types.scaly" >> "$WORK/build.log" 2>&1 || return 1
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

flowpin_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$(run_limited "$WORK/tscaly_types" --flow "$f" 2>/dev/null | tr '\n' '|')"
  done
}

# ★★★ THE UNION PIN — slice 94's SEVENTH instrument, and the argument for it is
# slice 93's one product on. That slice built the FLOWPIN because *this chapter's
# product is a type no artifact in this directory prints*; the FLOWPIN prints a
# type's ID, and the two halves this slice spends most of its lines on — the
# constituent ORDER CompareTypes decides and the NAME formatUnionTypes and
# type_to_string compose out of it — do not move an id. `U <id> <flags>
# <objectflags> <name>` per interned union, in creation order.
unionpin_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$(run_limited "$WORK/tscaly_types" --unions "$f" 2>/dev/null | tr '\n' '|')"
  done
}

# ★★★ THE WHOLE-CORPUS FLOWGATE, and slice 92's h08/h11/h25 are why it is here
# beside a pin rather than instead of it: eleven fixtures aimed at eleven
# mechanisms still missed three of them, because the shape that distinguishes an
# arm is not the shape a fixture author writes around. The eleven pin files here
# carry a few dozen trace lines between them; the corpus carries two thousand.
#
# ★ The units are dispatched in PARALLEL and each writes its own file, then the
# files are concatenated in a fixed order. A shared pipe would interleave and the
# checksum would move on its own — an instrument that disagrees with itself is
# worse than none.
#
# ★ NUL-DELIMITED SINCE SLICE 101, AND THE FIX IS NOT COSMETIC: `xargs` splits on
# WHITESPACE, the stage-2 corpus holds one unit whose name contains a space, and
# from it onward the `-n 2` pairing shifts by one — which redirects the dumper's
# stdout INTO A CORPUS FILE. Invisible at stage 1, where no unit path has a space.
# See §3.5eu finding nine.
flowgate() {
  local i=0 u
  rm -rf "$WORK/flowout" "$WORK/pairs"; mkdir -p "$WORK/flowout"
  while IFS= read -r u; do
    printf '%s\0%s\0' "$u" "$(printf '%s/flowout/%06d' "$WORK" "$i")"
    i=$((i+1))
  done < "$WORK/units.txt" > "$WORK/pairs"
  LIMIT=$LIMIT xargs -0 -P 8 -n 2 sh -c 'perl -e "alarm $LIMIT; exec @ARGV" "$0" --flow "$1" > "$2" 2>/dev/null' "$WORK/tscaly_types" < "$WORK/pairs"
  find "$WORK/flowout" -type f -print0 | xargs -0 cat > "$WORK/flow.all"
  local f v a
  f=$(grep -c '^F ' "$WORK/flow.all"); v=$(grep -c '^V ' "$WORK/flow.all"); a=$(grep -c '^A ' "$WORK/flow.all")
  echo "$f $v $a $(cksum < "$WORK/flow.all" | cut -d' ' -f1)"
}

# The whole-corpus UNIONGATE, beside the pin for the reason slice 92's h08/h11/h25
# gave: eleven fixtures aimed at eleven mechanisms still missed three of them,
# because the shape that distinguishes an arm is not the shape a fixture author
# writes around. It counts the interned unions over the corpus and checksums their
# printed names — so a broken interning moves the COUNT and a broken order or a
# broken printer moves the CHECKSUM, and the two are told apart without a diff.
uniongate() {
  local i=0 u
  rm -rf "$WORK/uout" "$WORK/upairs"; mkdir -p "$WORK/uout"
  while IFS= read -r u; do
    printf '%s\0%s\0' "$u" "$(printf '%s/uout/%06d' "$WORK" "$i")"
    i=$((i+1))
  done < "$WORK/units.txt" > "$WORK/upairs"
  LIMIT=$LIMIT xargs -0 -P 8 -n 2 sh -c 'perl -e "alarm $LIMIT; exec @ARGV" "$0" --unions "$1" > "$2" 2>/dev/null' "$WORK/tscaly_types" < "$WORK/upairs"
  find "$WORK/uout" -type f -print0 | xargs -0 cat > "$WORK/unions.all"
  local n q
  n=$(grep -c '^U ' "$WORK/unions.all")
  q=$(grep -c ' ?$' "$WORK/unions.all")
  echo "$n $q $(cksum < "$WORK/unions.all" | cut -d' ' -f1)"
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

DIAG_BASE=""; DIAG_LINES=""; DIAG_DIAGS=""; STOP_BASE=""; FLOW_BASE=""; UNION_BASE=""

baseline() {
  echo "################################################################"
  bold "BASELINE — eight instruments"
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
  flowpin_of > "$WORK/base.flow"
  unionpin_of > "$WORK/base.unions"
  find "$PKG/tests/out/cases" -path '*/units/*' -type f \
       \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.mjs' -o -name '*.cjs' \) \
       | sort > "$WORK/units.txt"
  STOP_BASE=$(stopgate)
  FLOW_BASE=$(flowgate)
  UNION_BASE=$(uniongate)
  echo
  echo "  the STOPPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.stops"
  echo
  echo "  the TAGPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.tags"
  echo
  echo "  the UNIONPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.unions"
  echo
  echo "  BASELINE   diagcheck $DIAG_BASE consistent, $DIAG_LINES speaking, $DIAG_DIAGS diagnostics"
  echo "             stopgate  (matched units speaking events other) = $STOP_BASE"
  echo "             flowgate  (invocations visits answers checksum) over $(wc -l < "$WORK/units.txt" | tr -d ' ') units = $FLOW_BASE"
  echo "             uniongate (unions unnamed checksum) over the same units = $UNION_BASE"
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
  flowpin_of > "$WORK/ctl.flow"
  unionpin_of > "$WORK/ctl.unions"
  stop=$(stopgate)
  local flow union
  flow=$(flowgate)
  union=$(uniongate)
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
  if cmp -s "$WORK/base.flow" "$WORK/ctl.flow"; then
    echo "  flowpin   unmoved — all nine fixtures trace the same walk."
  else
    green "flowpin   RED"
    diff "$WORK/base.flow" "$WORK/ctl.flow" | cut -c1-200 | sed 's/^/    /'
    moved=1
  fi
  if [ "$stop" = "$STOP_BASE" ]; then
    echo "  stopgate  unmoved — $stop"
  else
    green "stopgate  MOVED   $STOP_BASE -> $stop   (matched units speaking events other)"
    moved=1
  fi
  if cmp -s "$WORK/base.unions" "$WORK/ctl.unions"; then
    echo "  unionpin  unmoved — every pin file interns the same unions with the same names."
  else
    green "unionpin  RED"
    diff "$WORK/base.unions" "$WORK/ctl.unions" | cut -c1-200 | sed 's/^/    /'
    moved=1
  fi
  if [ "$flow" = "$FLOW_BASE" ]; then
    echo "  flowgate  unmoved — $flow"
  else
    green "flowgate  MOVED   $FLOW_BASE -> $flow   (invocations visits answers checksum)"
    moved=1
  fi
  if [ "$union" = "$UNION_BASE" ]; then
    echo "  uniongate unmoved — $union"
  else
    green "uniongate MOVED   $UNION_BASE -> $union   (unions unnamed checksum)"
    moved=1
  fi
  if [ "$moved" = 0 ]; then
    if [ "$speaking" != "$DIAG_LINES" ] || [ "$diags" != "$DIAG_DIAGS" ]; then
      echo "  ungated on all eight, WITH A NUMBER: $DIAG_LINES/$DIAG_DIAGS -> $speaking/$diags."
    else
      red "UNGATED ON ALL EIGHT AND NOTHING MOVED AT ALL."
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
P['h01'] = ('''# THE PREMISE (family one) — getOptionalType reverted to the stop that stood at
# addOptionalityEx until this slice. PREDICTION: TAGPIN + STOPPIN RED on the
# optional fixtures, UNIONPIN RED (the inferred `T | undefined` unions disappear)
# and the STOPGATE moved. The row that prices the INFERRED half of the chapter.''',
'''old = """            if is_optional
                return this.get_optional_type(t, is_property)"""
new = """            if is_optional
            {
                this.record_unported("get-optional-type", t.flags)
                return null
            }"""''')
P['h02'] = ('''# THE PREMISE (family two) — checkPropertyInitialization reverted to the
# `flow-graph` stop that was the head of the work list from slice 77 to slice 94.
# PREDICTION: diagcheck UNGATED at a LOSS (every TS2564 disappears and a
# subsequence cannot see a line we fail to emit), DIAGPIN RED, STOPGATE moved by
# the whole row. The row that carries the slice's entire diagnostic product.''',
'''old = """        this.check_property_initialization(node)"""
new = """        this.record_unported("flow-graph", AstNode.kind_of(node))"""''')
P['h03'] = ('''# THE PREMISE (family three) — getTypeFromUnionTypeNode reverted to a stop, i.e.
# the ANNOTATION half of the chapter. PREDICTION: TAGPIN + STOPPIN + UNIONPIN RED
# on every fixture with a written union, and the UNIONGATE's count collapses to the
# unions that are INFERRED. It is the row that separates the two producers.''',
'''old = """        if k = KindUnionType
            return this.get_type_from_union_type_node(node)"""
new = """        if k = KindUnionType
        {
            this.record_unported("get-type-from-type-node", k)
            return null
        }"""''')
P['h04'] = ('''# booleanType is never minted. PREDICTION: UNIONPIN RED on every fixture (the
# first line of every pin goes), TAGPIN + STOPPIN RED, and the UNIONGATE's count
# drops by one per unit. The row that shows the FIRST union is the one every other
# reader depends on.''',
'''old = """        set boolean_type: this.get_union_type_pair(regular_false_type, regular_true_type)"""
new = """        set boolean_type: null"""''')
P['h05'] = ('''# getTypeFromTypeNode's KindBooleanKeyword arm removed again. PREDICTION: TAGPIN
# + STOPPIN RED on union_boolean and UNIONPIN RED — `boolean | undefined` cannot be
# built at all when the keyword does not resolve. It prices the arm slice 71 left
# out with a note that named this slice.''',
'''old = """        if k = KindBooleanKeyword
            return boolean_type"""
new = """        if k = KindBooleanKeyword
        {
            this.record_unported("get-type-from-type-node", k)
            return null
        }"""''')
P['h06'] = ('''# TypeFlagsBoolean is not set on a two-boolean-literal union. PREDICTION: UNIONPIN
# RED with the NAME column changing rather than the id column — `boolean` becomes
# `false | true` everywhere, on every declaration in the corpus. The one line that
# keeps a keyword a keyword.''',
'''old = """                        if ((e1 as ref[Type]).flags & TypeFlagsBooleanLiteral) <> 0
                            set t.flags: t.flags | TypeFlagsBoolean"""
new = """                        if false
                            set t.flags: t.flags | TypeFlagsBoolean"""''')
P['h07'] = ('''# The intern table always MISSES — every getUnionTypeFromSortedList mints a fresh
# type. PREDICTION: UNIONPIN RED on the id column and the UNIONGATE's count up,
# and — the half that matters — getOptionalType's `Types()[0] == undefined` test
# can still fire, so this row is about IDENTITY and not about the answer. It is
# what the intern table's own note claims and this is the number behind it.''',
'''old = """        let existing this.find_union_type(types)
        if existing <> null
            return existing"""
new = """        let existing this.find_union_type(types)
        if false
            return existing"""''')
P['h08'] = ('''# CompareTypes' first key — the sort-order FLAGS — removed. PREDICTION: UNIONPIN
# RED on the NAME column of every multi-constituent union, because the order falls
# through to the type ids, i.e. to creation order. The row that says the printed
# order is a property of TypeFlags' bit positions and of nothing else.''',
'''old = """        let cf Checker.get_sort_order_flags(t1) - Checker.get_sort_order_flags(t2)
        if cf <> 0
            return cf"""
new = """        let cf 0
        if cf <> 0
            return cf"""''')
P['h09'] = ('''# CompareTypes' id fallback answers 0. PREDICTION: UNIONPIN RED — two types that
# agree on every key above become EQUAL, so the sorted insert treats them as
# already present and drops one. `undefined` and `missing` are exactly such a pair.''',
'''old = """        ; Fall back to type ids, which is creation order for the built-in types.
        t1.id - t2.id"""
new = """        ; Fall back to type ids, which is creation order for the built-in types.
        0"""''')
P['h10'] = ('''# CompareTypes' string-literal value comparison removed. PREDICTION: UNGATED with
# nothing moving — no union in this corpus holds two string literal types, because
# the annotation `"a" | "b"` needs getTypeFromTypeNode's LiteralType arm, which
# reports. It is the containment proof for the whole literal-ordering half.''',
'''old = """        if (t1.flags & TypeFlagsStringLiteral) <> 0
        {
            let cv Checker.compare_names(Checker.literal_text_of(t1), Checker.literal_text_length_of(t1), Checker.literal_text_of(t2), Checker.literal_text_length_of(t2))
            if cv <> 0
                return cv
        }"""
new = """        if false
        {
            let cv Checker.compare_names(Checker.literal_text_of(t1), Checker.literal_text_length_of(t1), Checker.literal_text_of(t2), Checker.literal_text_length_of(t2))
            if cv <> 0
                return cv
        }"""''')
P['h11'] = ('''# addTypeToUnion no longer ignores `never`. PREDICTION: UNIONPIN RED on
# union_reduction — `string | never` becomes a two-constituent union instead of
# answering `string`, and the UNIONGATE's count goes up. The reference's own
# one-line comment, priced.''',
'''old = """        ; 'never' is ignored in unions.
        if (flags & TypeFlagsNever) <> 0
            return includes"""
new = """        ; 'never' is ignored in unions.
        if false
            return includes"""''')
P['h12'] = ('''# The sorted insert always inserts — the binary search's `found` answer ignored.
# PREDICTION: UNIONPIN RED — `string | string` becomes a two-constituent union.
# The row that shows the DEDUPLICATION is the search's second answer and not a
# separate pass.''',
'''old = """        if found = false
            Checker.insert_type_at(type_set, index, t)"""
new = """        Checker.insert_type_at(type_set, index, t)"""''')
P['h13'] = ('''# addTypesToUnion no longer FLATTENS a union constituent. PREDICTION: UNIONPIN RED
# — `boolean | undefined` keeps booleanType as one constituent instead of its two
# literals, so formatUnionTypes has nothing to collapse and the name changes. The
# row that shows flattening and collapsing are two different mechanisms pointing
# the same way.''',
'''old = """                        let sub Checker.union_types_of(t)
                        if sub <> null
                            set includes: this.add_types_to_union(type_set, includes, sub as ref[Array[ref[Type]?]])"""
new = """                        set includes: this.add_type_to_union(type_set, includes, t)"""''')
P['h14'] = ('''# addTypesToUnion's `lastType` guard removed. PREDICTION: UNGATED with nothing
# moving — it is the reference's cheap dedup of an ALREADY-SORTED input, and the
# sorted insert below answers the same question exactly. The row exists to say that
# in a number: the reference has the line, and a port that dropped it would be
# right by accident.''',
'''old = """                if same = false"""
new = """                if true"""''')
P['h15'] = ('''# removeRedundantLiteralTypes is never called. PREDICTION: UNGATED or a small
# UNIONPIN move — the reduction it performs needs a literal type BESIDE its base
# primitive in one union, and every literal type in this corpus comes from an
# expression rather than from an annotation. The row is the containment proof for
# the literal-reduction half.''',
'''old = """                set type_set: this.remove_redundant_literal_types(type_set, includes, reduce_void_undefined)"""
new = """                set reduce: reduce"""''')
P['h16'] = ('''# The undefined/missing pair removal removed. PREDICTION: UNGATED with nothing
# moving — missingType is minted only under exactOptionalPropertyTypes, which is
# FALSE under this harness (strict_null_checks' header has the reading), so
# undefinedOrMissingType IS undefinedType and the pair cannot occur. A gate with a
# number rather than a comment.''',
'''old = """                    if pair
                        set type_set: this.type_list_without(type_set, 1)"""
new = """                    if false
                        set type_set: this.type_list_without(type_set, 1)"""''')
P['h17'] = ('''# The AnyOrUnknown collapse removed. PREDICTION: UNIONPIN RED on union_reduction —
# `string | any` becomes a two-constituent union instead of `any`, and `string |
# unknown` likewise. The row that shows the collapse is a REDUCTION and not an
# optimisation.''',
'''old = """            if (includes & TypeFlagsAnyOrUnknown) <> 0"""
new = """            if false"""''')
P['h18'] = ('''# The empty-typeSet fork removed — an empty set falls through to
# getUnionTypeFromSortedList, which answers neverType for it. PREDICTION: UNGATED
# with nothing moving, and that is the measurement: the only way to empty the set
# here is `never | never`, and the tail answers `never` for it too. The two paths
# differ only for the widening arms, which strictNullChecks makes unreachable.''',
'''old = """            if (type_set.get_length() as int) = 0"""
new = """            if false"""''')
P['h19'] = ('''# ObjectFlagsPrimitiveUnion is never set. PREDICTION: UNIONPIN RED on the
# OBJECTFLAGS column alone — every name and every id unchanged. The row that shows
# the pin has a column no other instrument in this directory has, and that the flag
# has no reader in this port yet (its readers are the relation and the printer's
# enum expansion).''',
'''old = """            set object_flags: ObjectFlagsPrimitiveUnion"""
new = """            set object_flags: ObjectFlagsNone"""''')
P['h20'] = ('''# getOptionalType's first-constituent identity test removed. PREDICTION: UNGATED or
# a UNIONPIN move on union_optional's `r?: string | undefined` — the test is what
# makes `getOptionalType(T | undefined)` answer the same object instead of building
# a second union with a duplicate constituent. The sorted insert would drop the
# duplicate anyway, so the row measures whether the shortcut is load-bearing or a
# shortcut.''',
'''old = """                        if (f as ref[Type]) = missing_or_undefined
                            return t"""
new = """                        if false
                            return t"""''')
P['h21'] = ('''# formatUnionTypes' boolean collapse removed. PREDICTION: UNIONPIN RED on the NAME
# column — `boolean | undefined` prints as `false | true | undefined`. It is the
# PRINTER's half of the same mechanism h06 breaks in the constructor, and the two
# rows together are what say the keyword needs both.''',
'''old = """                if collapse"""
new = """                if false"""''')
P['h22'] = ('''# formatUnionTypes no longer moves `null` and `undefined` to the END. PREDICTION:
# UNIONPIN RED on the NAME column of every optional — `string | undefined` prints
# as `undefined | string`, which is the SORTED order and the wrong printed one.
# Measured against the reference's own baselines: `string | undefined` occurs in
# 183 of them and `undefined | string` in none.
# ★★ THE FIRST DRAFT OF THIS ROW PATCHED ONLY THE `null` HALF AND CAME BACK
# UNGATED, because no pin fixture held a `| null` union — slice 77's g03 exactly:
# *a fixture that cannot make the mechanism fire is indistinguishable from a
# correct one*. Both halves are one mechanism upstream and both are patched here,
# and union_reduction.ts grew three `null` lines in the same commit.''',
'''old = """        if (flags & TypeFlagsNull) <> 0
            out.add(null_type)
        if (flags & TypeFlagsUndefined) <> 0
            out.add(undefined_type)"""
new = """        if false
            out.add(null_type)
        if false
            out.add(undefined_type)"""''')
P['h23'] = ('''# THE FINDING — maybeTypeOfKind's union recursion removed, i.e. the containment
# proof this slice invalidated in a chapter it never opened. PREDICTION: diagcheck
# RED by INVENTION on union_maybe_void — a function returning `number | void` needs
# no return statement, and without the recursion every one of them collects a
# TS2355 the reference does not have. Three units of 18 249 found it at stage 2 and
# none of the 1 481 at stage 1 until that fixture existed.''',
'''old = """        if (t.flags & TypeFlagsUnionOrIntersection) <> 0
        {
            let ts Checker.union_types_of(t)"""
new = """        if false
        {
            let ts Checker.union_types_of(t)"""''')
P['h24'] = ('''# containsUndefinedType's union arm removed — the other containment proof the union
# chapter invalidated, and the one whose note named its own expiry date.
# PREDICTION: diagcheck RED by INVENTION — `p: string | undefined` is exactly the
# property TS2564 must NOT be reported for, and without the arm every one of them
# collects it.''',
'''old = """        var ty t
        if (t.flags & TypeFlagsUnion) <> 0"""
new = """        var ty t
        if false"""''')
P['h25'] = ('''# isMatchingReference's property-access arm reverted to the stop slice 93 left
# there. PREDICTION: DIAGPIN RED on propinit_assigned at a LOSS — every `this.p =`
# in a constructor stops being an assignment the walk can see, so the walk stops
# and the caller makes no claim. The row that shows the synthetic reference and the
# matching arm are one mechanism.''',
'''old = """        if sk = KindPropertyAccessExpression
        {
            if Parser.is_access_expression(target)"""
new = """        if sk = KindPropertyAccessExpression
        {
            this.record_unported("is-matching-reference-source", sk)
            if false"""''')
P['h26'] = ('''# getAccessedPropertyName's NAME comparison forced true — every property access
# matches every other. PREDICTION: DIAGPIN RED on propinit_missing at a LOSS: a
# constructor that assigns ANY property would satisfy every uninitialized one. h25
# breaks the arm and this breaks its content, which is the pair that says WHICH
# half a fixture measures.''',
'''old = """                if source_len <> target_len
                    return false
                if Checker.text_equals(source_name, target_name, source_len) = false
                    return false"""
new = """                if false
                    return false
                if false
                    return false"""''')
P['h27'] = ('''# checkPropertyInitialization's per-member `continue` restored to the `return` its
# first draft had. PREDICTION: DIAGPIN RED at a LOSS on propinit_assigned — a walk
# that stops on member A abandons the class, so OverloadedCtorOnly's TS2564 goes
# with PartlyAssigns'. The row that prices the difference between *no claim about
# this member* and *no claim about this class*.''',
'''old = """            if this.unported_mark() <> mark
                continue
            if t = null
                continue"""
new = """            if this.unported_mark() <> mark
                return
            if t = null
                return"""''')
P['h28'] = ('''# isPropertyWithoutInitializer's definite-assignment (`!`) test removed.
# PREDICTION: diagcheck RED by INVENTION — `d!: string` is the spelling that says
# *I will assign this elsewhere*, and reporting TS2564 on it is a line the
# reference does not have.''',
'''old = """            if AstNode.kind_of(postfix as ref[AstNode]) = KindExclamationToken
                return false"""
new = """            if false
                return false"""''')
P['h29'] = ('''# The STATIC skip removed. PREDICTION: diagcheck RED by INVENTION — a static
# property is initialized in a static block or not at all, and the reference checks
# it through isPropertyInitializedInStaticBlocks, which this port does not have.
# The row that says the skip is what makes the ported half exact.''',
'''old = """            if b.is_static(member)
                continue"""
new = """            if false
                continue"""''')
P['h30'] = ('''# The synthetic reference carries no flow node. PREDICTION: DIAGPIN RED at a LOSS
# — getFlowTypeOfReferenceEx answers the DECLARED type when the reference has no
# flow node, so every property looks uninitialized and... no: it answers the
# declared type, which contains no undefined, so every property looks INITIALIZED
# and every TS2564 is lost. The row that shows which of the three slots on the
# synthetic node is the one that does the work.''',
'''old = """        set reference.flow_node: AstNode.return_flow_node_of(constructor)"""
new = """        set reference.flow_node: null"""''')
P['h31'] = ('''# The type-alias stop in getTypeFromUnionTypeNode removed. PREDICTION: UNIONPIN
# RED and the UNIONGATE's count up — `type X = string | number` starts minting a
# union whose NAME is `string | number` where the reference prints `X`. It is the
# one row here that measures a WRONG ANSWER rather than a missing one, which is
# why the stop is a stop and not an omission.''',
'''old = """        if this.get_alias_symbol_for_type_node(node) <> null
        {
            this.record_unported("type-alias-union", KindUnionType)
            return null
        }"""
new = """        if false
        {
            this.record_unported("type-alias-union", KindUnionType)
            return null
        }"""''')
P['h32'] = ('''# The dead early exit after checkTypeParameterListsIdentical restored — the
# pre-existing loss this slice exposed. PREDICTION: DIAGPIN or diagcheck UNGATED at
# a LOSS, and the STOPGATE moved: a merged interface's members walk stops running
# as soon as nothing earlier in the file has stopped. The row that shows a guard
# built on the STICKY `is_unported()` flag is dormant until a slice removes the
# earlier stop.''',
'''old = """        this.check_type_parameter_lists_identical(sym)
        ; ★★★ AND THERE IS NO EARLY EXIT AFTER IT"""
new = """        let unported_before_tpli this.is_unported()
        this.check_type_parameter_lists_identical(sym)
        if this.is_unported() <> unported_before_tpli
            return
        ; ★★★ AND THERE IS NO EARLY EXIT AFTER IT"""''')
P['h33'] = ('''# BOTH deduplications off at once — the sorted insert's `found` answer AND
# addTypesToUnion's `lastType` guard. PREDICTION: UNIONPIN RED where h12 and h14
# were each UNGATED, and that is the row's whole content: the two are EACH OTHER'S
# COVER on this corpus. `string | string` reaches addTypesToUnion as two identical
# adjacent constituents, so the lastType guard drops the second before the sorted
# insert is ever asked — break either one alone and the other answers. **A pair of
# mechanisms that agree on every input is indistinguishable from one mechanism
# until a control breaks both.**''',
'''old = """                if same = false
                {"""
new = """                if true
                {"""
s = s.replace(old, new, 1)
old = """        if found = false
            Checker.insert_type_at(type_set, index, t)"""
new = """        Checker.insert_type_at(type_set, index, t)"""''')

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

control "h01 THE PREMISE - getOptionalType reverted to its stop" $CHECKER "$PATCHDIR/h01.py"
control "h02 THE PREMISE - checkPropertyInitialization reverted to its stop" $CHECKER "$PATCHDIR/h02.py"
control "h03 THE PREMISE - getTypeFromUnionTypeNode reverted to its stop" $CHECKER "$PATCHDIR/h03.py"
control "h04 booleanType never minted" $CHECKER "$PATCHDIR/h04.py"
control "h05 the KindBooleanKeyword arm removed" $CHECKER "$PATCHDIR/h05.py"
control "h06 TypeFlagsBoolean not set on the boolean pair" $CHECKER "$PATCHDIR/h06.py"
control "h07 the union intern table always misses" $CHECKER "$PATCHDIR/h07.py"
control "h08 CompareTypes sort-order-flags key removed" $CHECKER "$PATCHDIR/h08.py"
control "h09 CompareTypes type-id fallback answers 0" $CHECKER "$PATCHDIR/h09.py"
control "h10 CompareTypes string-literal value comparison removed" $CHECKER "$PATCHDIR/h10.py"
control "h11 addTypeToUnion no longer ignores never" $CHECKER "$PATCHDIR/h11.py"
control "h12 the sorted insert always inserts" $CHECKER "$PATCHDIR/h12.py"
control "h13 addTypesToUnion no longer flattens a union" $CHECKER "$PATCHDIR/h13.py"
control "h14 addTypesToUnion lastType guard removed" $CHECKER "$PATCHDIR/h14.py"
control "h15 removeRedundantLiteralTypes never called" $CHECKER "$PATCHDIR/h15.py"
control "h16 the undefined/missing pair removal removed" $CHECKER "$PATCHDIR/h16.py"
control "h17 the AnyOrUnknown collapse removed" $CHECKER "$PATCHDIR/h17.py"
control "h18 the empty-typeSet fork removed" $CHECKER "$PATCHDIR/h18.py"
control "h19 ObjectFlagsPrimitiveUnion never set" $CHECKER "$PATCHDIR/h19.py"
control "h20 getOptionalType first-constituent identity test removed" $CHECKER "$PATCHDIR/h20.py"
control "h21 formatUnionTypes boolean collapse removed" $CHECKER "$PATCHDIR/h21.py"
control "h22 formatUnionTypes no longer moves null/undefined to the end" $CHECKER "$PATCHDIR/h22.py"
control "h23 THE FINDING - maybeTypeOfKind union recursion removed" $CHECKER "$PATCHDIR/h23.py"
control "h24 containsUndefinedType union arm removed" $CHECKER "$PATCHDIR/h24.py"
control "h25 isMatchingReference property-access arm reverted" $CHECKER "$PATCHDIR/h25.py"
control "h26 getAccessedPropertyName name comparison forced TRUE" $CHECKER "$PATCHDIR/h26.py"
control "h27 checkPropertyInitialization per-member continue restored to return" $CHECKER "$PATCHDIR/h27.py"
control "h28 the definite-assignment (!) test removed" $CHECKER "$PATCHDIR/h28.py"
control "h29 the STATIC skip removed" $CHECKER "$PATCHDIR/h29.py"
control "h30 the synthetic reference carries no flow node" $CHECKER "$PATCHDIR/h30.py"
control "h31 the type-alias stop removed" $CHECKER "$PATCHDIR/h31.py"
control "h32 the dead early exit after checkTypeParameterListsIdentical restored" $CHECKER "$PATCHDIR/h32.py"
control "h33 BOTH deduplications off at once" $CHECKER "$PATCHDIR/h33.py"

echo
echo "################################################################"
bold "DONE - read every row against its PREDICTION, not against its colour."
