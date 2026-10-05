#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice77.sh — the slice-77 battery: THE DUPLICATE INDEX SIGNATURES, and
# the interface arm's tail that had to be opened before either report could be
# reached.
#
# ★★★ THE SLICE'S PRODUCT IS DIAGNOSTICS AGAIN, so diagcheck is a POSITIVE
# instrument here for the first time in three slices — but it is asymmetric (a
# SUBSEQUENCE), so it breaks on a line INVENTED and stays green on a line LOST.
# Every losing row below is caught by the DIAGPIN, which compares the seven
# fixtures' C sections byte for byte and whose every line was checked against the
# reference's own C section before this battery ran (five of seven are equal, two
# are strict subsequences and CLAUDE.md §3.5dw names both).
#
# ★★ THE THIRD INSTRUMENT IS THE STOPGATE, and it is not decoration: half of what
# this slice does is move where the interface arm stops, which no diagnostic can
# see. The event count is the sensitive column — opening the tail took the corpus
# from 7 216 stop events to 7 886, because the members walk of every interface now
# runs.
#
# ★★★ ITERATE AT STAGE 1 AND CONFIRM AT STAGE 2 ONCE — slice 64's rule. The
# recorded verdicts are stage 1's.
#
# Usage (nothing may edit the tree while this runs — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # stage 1, ~25 s
#   packages/tscaly/tests/controls-slice77.sh 2>&1 | tee /tmp/battery77.log

set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.0/tscaly/checker.scaly
TYPEDUMP=$PKG/0.1.0/tscaly/TypeDump.scaly
FIX=$PKG/tests/fixtures

. packages/tscaly/tests/toolchain.sh || exit 2

# One fixture per guard, plus the one shape that reaches the wall. ★ ONE MECHANISM
# PER FILE: the tagpin is first-wins, so a fixture naming two mechanisms is a
# fixture nobody can read a red row off (slice 72's finding).
# One mechanism per file (slice 72's rule). Seven, and the last three are the
# negative controls without which a red row cannot be told from a broken fixture.
PINFILES="
$FIX/checker_index_signature_duplicate_interface.ts
$FIX/checker_index_signature_duplicate_class.ts
$FIX/checker_index_signature_merged_interface.ts
$FIX/checker_interface_extends_not_entity_name.ts
$FIX/checker_interface_extends_optional_chain.ts
$FIX/checker_interface_extends_type_arguments.ts
$FIX/checker_index_signature_distinct_ok.ts
$FIX/checker_index_signature_never_ok.ts
"
red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl77)

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

# The DIAGPIN: the C section of each pin file, one line each. `--diags` rather than
# the dump, because every one of these units stops somewhere and the dump prints
# nothing for such a unit (TypeDump.emit's own note).
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
# gate is what slice 76's instrument half moves; the counts are what catch the
# truncation the gate is blind to (stops.sh's own header).
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
  if grep -q '	$' "$WORK/base.tags"; then
    red "a fixture answers NO tag — the tagpin would be comparing two empties."
    exit 2
  fi
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
    echo "  diagpin   unmoved — all eight pin files answer the same C section."
  else
    green "diagpin   RED"
    diff "$WORK/base.diags" "$WORK/ctl.diags" | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.tags" "$WORK/ctl.tags"; then
    echo "  tagpin    unmoved — all four fixtures answer the same tag."
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
# ★★★ THE PREMISE ROW for the CLASS arm: its tail back to slice 74's bare stop.
# PREDICTION: diagpin RED on the class fixture alone (its two TS2374 lines go), the
# six others unmoved; diagcheck ungated, because losing a line is the direction a
# subsequence cannot see — which is exactly why the diagpin exists.
old = """        this.record_unported("check-index-constraints", AstNode.kind_of(node))
        this.check_class_or_interface_for_duplicate_index_signatures(node)"""
new = """        this.record_unported("check-index-constraints", AstNode.kind_of(node))"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g02.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE PREMISE ROW for the INTERFACE arm: the four tail statements put back
# inside the once-block's shadow by returning right after it. PREDICTION: diagpin
# RED on FIVE fixtures (both interface TS2374 files, the merged one and both
# TS2499 ones) and the stopgate moved hard — the members walk of every interface
# in the corpus stops happening, so the event count falls by hundreds.
old = """        this.check_interface_declaration_once(node, sym)"""
new = """        this.check_interface_declaration_once(node, sym)
        return"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g03.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE ONCE-BIT DROPPED. PREDICTION: diagpin RED on the MERGED fixture ALONE and
# diagcheck RED with it — a merged interface reaches the function through two
# declarations, so its two TS2374 lines are reported twice and the duplicate breaks
# the subsequence. This is the row that shows the bit is a REPORT memo and not an
# optimisation.
old = """        if links.index_signatures_checked
            return
        set links.index_signatures_checked: true"""
new = """"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g04.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE GROUPING REPLACED BY A COUNT — report every declaration as soon as the
# index symbol has more than one, which is the reading `len(declarations) <= 1`
# invites. PREDICTION: diagpin RED on the DISTINCT fixture (a string index beside a
# number index invents two TS2374) and diagcheck RED with it. The row that proves
# the grouping is by TYPE.
old = """            if partners > 1"""
new = """            if partners > 0"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g05.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE `never` ARM OF Distributed() DROPPED. PREDICTION: diagpin RED on the
# never fixture (two invented TS2374) and diagcheck RED with it. Without this row
# the arm would be transcription nobody can distinguish from a correct omission.
old = """            if (ty.flags & TypeFlagsNever) <> 0
                continue"""
new = """"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g06.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE ABANDON-ON-AN-UNKNOWN-TYPE TURNED INTO A SKIP, which is the tempting
# reading: keep the survivors and group those. PREDICTION: UNGATED with nothing
# moving at stage 1 — every index-signature parameter type in this corpus is a
# keyword arm getTypeFromTypeNode already answers, so no group is ever built out of
# survivors. The row is a MEASUREMENT of that, and the argument for the abandon is
# in the function's own note rather than in a colour here.
old = """            if this.is_unported() <> unported_before
                return
            if t = null
                return
            let ty t as ref[Type]"""
new = """            if this.is_unported() <> unported_before
                continue
            if t = null
                continue
            let ty t as ref[Type]"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g07.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE OPTIONAL-CHAIN HALF OF TS2499's CONDITION DROPPED. PREDICTION: diagpin RED
# on the optional-chain fixture ALONE — `a?.b` IS an entity-name expression, so the
# first test passes it and only this one catches it. The row exists because a port
# that wrote one of the two conditions would leave that file silent and every other
# fixture green.
old = """                    if Binder.is_optional_chain(ex)
                        set bad: true"""
new = """"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g08.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE ENTITY-NAME HALF DROPPED, the mirror of g07. PREDICTION: diagpin RED on the
# not-entity-name fixture alone. Two rows rather than one because the condition is
# two tests and a battery that broke them together could not say which fixture
# measures which.
old = """                    if Binder.is_entity_name_expression(ex) = false
                        set bad: true"""
new = """"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g09.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE REPORT MOVED FROM THE EXPRESSION TO THE HERITAGE ELEMENT, which is what a
# reader writes who does not look at `c.error(expr, ...)`. PREDICTION: diagpin and
# diagcheck RED on the TYPE-ARGUMENTS fixture and on NOTHING ELSE — an
# ExpressionWithTypeArguments with no type arguments spans exactly its expression,
# so the two spellings coincide on every other shape. ★The first draft of this row
# predicted a red on the two plain TS2499 fixtures and came back ungated against
# both; the fixture it needed did not exist yet. **"The two spellings agree on every
# fixture I have" is not a proof that they agree** — a span is the half of a
# diagnostic no message text carries, so the row needs an input whose two candidate
# nodes actually differ.
old = """                        this.error_on_node(ex, DiagAn_interface_can_only_extend_an_identifier_Slashqualified_name_with_optional_type_arguments)"""
new = """                        this.error_on_node(hn, DiagAn_interface_can_only_extend_an_identifier_Slashqualified_name_with_optional_type_arguments)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g10.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ getIndexSymbol ASKED FOR THE WRONG INTERNAL NAME — the UNPREFIXED spelling,
# which is the mistake slice 27 paid for one dimension down (four of the reference's
# constants carry no 0xFE prefix and `index` is not one of them). PREDICTION: diagpin
# RED on all four reporting fixtures — the lookup misses and every TS2374 is lost —
# and diagcheck UNGATED, because a loss is invisible to a subsequence. The pair is
# the sharpest statement of why this battery carries two instruments.
old = """        let nl Binder.internal_name(host, "index", &nd)"""
new = """        let nl Binder.internal_name_unprefixed(host, "index", &nd)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g11.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE `decl_count <= 1` GUARD DROPPED. PREDICTION: UNGATED with nothing moving —
# the guard is an early exit and the grouping below answers the same thing without
# it (one declaration can have no partner). The row is here because the reference
# has the line and a port that dropped it would be right by accident; a
# measurement, not a colour.
old = """        if decl_count <= 1
            return"""
new = """"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g12.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE KindIndexSignature FILTER DROPPED, so every declaration of the index
# symbol is grouped. PREDICTION: UNGATED with nothing moving at stage 1 — nothing
# but an index signature is ever filed under `%FEindex` in this corpus, so the
# reference's own guard has no input here. ★It is the reference's hook for LATE-BOUND
# index signatures (*"allow these to duplicate one another"*), which needs the
# late-binding chapter, so the row's silence is UNCOVERED and not unreachable.
old = """            if AstNode.kind_of(dn) <> KindIndexSignature
                continue"""
new = """"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g13.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ checkPropertyInitialization's STOP REMOVED from the class tail. PREDICTION:
# UNGATED on both pins and the STOPGATE MOVED by exactly the 235 units / 380 events
# the row is worth. It is the row that prices the honest report: the function is
# LIVE under this harness (both strict options answer true) and what it needs is the
# flow graph, so removing the tag would claim the class arm is finished when it is
# not.
old = """        this.record_unported("flow-graph", AstNode.kind_of(node))"""
new = """"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g14.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE ONCE-BLOCK PUT BACK INLINE in the crudest faithful way: its five returns
# restored as returns from the ARM by calling it and returning whenever it reported.
# PREDICTION: diagpin RED on both TS2499 fixtures ALONE — they are the two whose
# once-block stops (an extends clause reaches resolve-entity-name) — while the four
# index-signature fixtures, whose interfaces have no base, keep every line. ★That
# asymmetry IS the finding the split is for, and no other row shows it.
old = """        this.check_interface_declaration_once(node, sym)"""
new = """        let ub_arm this.is_unported()
        this.check_interface_declaration_once(node, sym)
        if this.is_unported() <> ub_arm
            return"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

# ── the dry run ─────────────────────────────────────────────────────────────
bold "DRY RUN — every patch against a copy of the tree"
DRY=$WORK/dry
for g in g01 g02 g03 g04 g05 g06 g07 g08 g09 g10 g11 g12 g13 g14; do
  rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
  if python3 "$PATCHDIR/$g.py" "$DRY/f.scaly" >/dev/null 2>&1; then
    echo "  $g applies"
  else
    red "  $g DOES NOT APPLY — its anchor has moved."; exit 2
  fi
done
rm -rf "$DRY"

baseline

control "g01 the CLASS tail's call removed (the premise)"                 "$CHECKER" "$PATCHDIR/g01.py"
control "g02 the INTERFACE tail closed again (the premise)"               "$CHECKER" "$PATCHDIR/g02.py"
control "g03 the once-bit dropped"                                        "$CHECKER" "$PATCHDIR/g03.py"
control "g04 the grouping replaced by a count"                            "$CHECKER" "$PATCHDIR/g04.py"
control "g05 the never arm of Distributed() dropped"                      "$CHECKER" "$PATCHDIR/g05.py"
control "g06 abandon-on-unknown-type turned into a skip"                  "$CHECKER" "$PATCHDIR/g06.py"
control "g07 the optional-chain half of TS2499 dropped"                   "$CHECKER" "$PATCHDIR/g07.py"
control "g08 the entity-name half of TS2499 dropped"                      "$CHECKER" "$PATCHDIR/g08.py"
control "g09 TS2499 reported on the heritage element, not the expression" "$CHECKER" "$PATCHDIR/g09.py"
control "g10 getIndexSymbol asks the UNPREFIXED internal name"            "$CHECKER" "$PATCHDIR/g10.py"
control "g11 the decl_count <= 1 guard dropped"                           "$CHECKER" "$PATCHDIR/g11.py"
control "g12 the KindIndexSignature filter dropped"                       "$CHECKER" "$PATCHDIR/g12.py"
control "g13 checkPropertyInitialization's stop removed"                  "$CHECKER" "$PATCHDIR/g13.py"
control "g14 the once-block's returns restored as arm returns"            "$CHECKER" "$PATCHDIR/g14.py"

echo
echo "################################################################"
bold "DONE — read every row against its PREDICTION, not against its colour."
