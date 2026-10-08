#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice76.sh — the slice-76 battery: checkVarDeclaredNamesNotShadowed's
# THREE GUARDS, and the correction to slice 75's stop log that measuring them
# forced.
#
# ★★★ THE SLICE PRODUCES NO DIAGNOSTIC, SO DIAGCHECK IS A PURELY NEGATIVE
# INSTRUMENT HERE and every positive row is a PIN or the stop instrument itself.
# What the slice moves is the work list: a row that read 405 events over 245 units
# — more units than any other stop in the corpus — and whose reference returns at
# its own first line for two thirds of them. A battery carrying diagcheck alone
# would score the whole slice as untested.
#
# ★★★ THE THREE INSTRUMENTS, and each answers a question the others cannot:
#
#   TAGPIN     the four fixtures' first unported tag. The positive instrument:
#              each fixture is aimed at exactly one guard (slice 72's rule) and a
#              guard put back makes its fixture read the old row again.
#   STOPGATE   tests/stops.sh's own internal gate plus its two printed counts.
#              This is the only instrument that can see the SECOND half of the
#              slice, because that half is the log's coverage and nothing else
#              reads it.
#   diagcheck  negative throughout: the slice adds no line, so any movement is an
#              INVENTION and the row is a defect rather than a measurement.
#
# ★★ THE STOPGATE IS NOT REDUNDANT WITH THE TAGPIN and g07 is why: reverting the
# instrument half leaves all four tags untouched (a tag is read off `types.ours`,
# which the dump writes) while the gate falls from 1296/1296 to 1264/1296. The two
# halves of this slice are disjoint in what can see them.
#
# ★★★ ITERATE AT STAGE 1 AND CONFIRM AT STAGE 2 ONCE — slice 64's rule. The
# recorded verdicts are stage 1's.
#
# Usage (nothing may edit the tree while this runs — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # stage 1, ~25 s
#   packages/tscaly/tests/controls-slice76.sh 2>&1 | tee /tmp/battery76.log

set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.1/tscaly/checker.scaly
TYPEDUMP=$PKG/0.1.1/tscaly/TypeDump.scaly
FIX=$PKG/tests/fixtures

. packages/tscaly/tests/toolchain.sh || exit 2

# One fixture per guard, plus the one shape that reaches the wall. ★ ONE MECHANISM
# PER FILE: the tagpin is first-wins, so a fixture naming two mechanisms is a
# fixture nobody can read a red row off (slice 72's finding).
PINFILES="
$FIX/checker_var_shadow_var.ts
$FIX/checker_var_shadow_let_inert.ts
$FIX/checker_var_shadow_const_inert.ts
$FIX/checker_var_shadow_catch_inert.ts
"
red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl76)

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
  if grep -q '	$' "$WORK/base.tags"; then
    red "a fixture answers NO tag — the tagpin would be comparing two empties."
    exit 2
  fi
  STOP_BASE=$(stopgate)
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
  if [ "$rc" != 0 ]; then
    red "diagcheck RED $differing   — the slice ADDS NO LINE, so a red here is an INVENTION and a defect, not a measurement."
  else
    echo "  diagcheck ungated — speaking on $speaking units with $diags diagnostics, was $DIAG_LINES/$DIAG_DIAGS."
  fi
  local moved=0
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
# ★★★ THE PREMISE ROW: the whole function back to slice 75's unconditional stop.
# PREDICTION: tagpin RED on all four fixtures — the three inert ones go back to
# `check-var-declared-names-not-shadowed 261` and the fourth trades `resolve-name`
# for the same row; stopgate moved (the events go back up); diagcheck ungated,
# because none of this is a diagnostic.
old = """        if (Binder.combined_node_flags(node) & NodeFlagsBlockScoped) <> 0
            return
        if Binder.is_part_of_parameter_declaration(node)
            return
        let symbol this.symbol_of_declaration(node)
        if symbol = null
            return
        if (Symbol.flags_of(symbol as ref[Symbol]) & SymbolFlagsFunctionScopedVariable) = 0
            return
        this.record_unported("resolve-name", AstNode.kind_of(node))"""
new = """        this.record_unported("check-var-declared-names-not-shadowed", AstNode.kind_of(node))"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g02.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE FLAGS GUARD DROPPED. PREDICTION: tagpin RED on let_inert and const_inert
# only — the catch fixture is finished by the SYMBOL test and the var one never
# entered this branch. That is the row proving the two guards are not duplicates.
old = """        if (Binder.combined_node_flags(node) & NodeFlagsBlockScoped) <> 0
            return
        if Binder.is_part_of_parameter_declaration(node)"""
new = """        if Binder.is_part_of_parameter_declaration(node)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g03.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE SYMBOL TEST DROPPED. PREDICTION: tagpin RED on catch_inert ALONE. Its
# node carries no Let and no Const, so the flags guard lets it through and only
# this test finishes it — the whole content of the fixture's own note.
old = """        if (Symbol.flags_of(symbol as ref[Symbol]) & SymbolFlagsFunctionScopedVariable) = 0
            return
        this.record_unported("resolve-name", AstNode.kind_of(node))"""
new = """        this.record_unported("resolve-name", AstNode.kind_of(node))"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g04.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE FLAGS GUARD NARROWED TO `let` — NodeFlagsBlockScoped is Let|Const|Using
# and this substitutes Let alone. PREDICTION: tagpin RED on const_inert only. The
# row exists because a guard tested through ONE of its three bits is a guard two
# thirds untested, and g02 cannot tell the three apart.
old = "        if (Binder.combined_node_flags(node) & NodeFlagsBlockScoped) <> 0"
new = "        if (Binder.combined_node_flags(node) & NodeFlagsLet) <> 0"
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g05.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE PARAMETER GUARD DROPPED. PREDICTION: NOTHING MOVES, and the row is a
# MEASUREMENT rather than a hole — the guard fires ZERO times over the stage-1
# corpus, measured with a per-guard probe the day the slice landed (blockscoped
# 238 events / 163 units, parameter 0, symbol test 13 / 5, resolve-name 157 / 90).
# It is UNCOVERED and not unreachable: a parameter's binding element stops two
# chapters earlier at get-type-for-binding-element-parent, so nothing in this
# corpus arrives here with a Parameter root. Kept because the reference has it and
# a guard removed on the strength of a corpus is a guard removed on the strength of
# a corpus.
old = """        if Binder.is_part_of_parameter_declaration(node)
            return
"""
new = ""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g06.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE NULL-SYMBOL GUARD DROPPED, replaced by an unconditional unwrap.
# PREDICTION: nothing moves — `symbol_of_declaration` answers null for no node this
# corpus reaches here (the same probe measured 0). The row is here so that the
# unwrap's safety is a measured claim rather than an inherited one; if it ever goes
# red the fixture set is what is wrong.
old = """        let symbol this.symbol_of_declaration(node)
        if symbol = null
            return
        if (Symbol.flags_of(symbol as ref[Symbol]) & SymbolFlagsFunctionScopedVariable) = 0"""
new = """        let symbol this.symbol_of_declaration(node)
        if (Symbol.flags_of(symbol as ref[Symbol]) & SymbolFlagsFunctionScopedVariable) = 0"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g07.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE INSTRUMENT HALF REVERTED: write_stops stops running the dump walk, which
# is exactly what slice 75 shipped. PREDICTION: stopgate MOVED — matched 1296 ->
# 1264 and `other` 1 -> 33 — while the TAGPIN DOES NOT MOVE AT ALL, because a tag
# is read off the dump and the dump is untouched. That disjointness is the argument
# for carrying two instruments in this battery.
old = """        TypeDump.emit(host, c, file, false, false, true)
        let sb StringBuilder^host()"""
new = """        let sb StringBuilder^host()"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g08.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE STOP LOG TRUNCATED to its first entry — slice 75's own negative control B,
# re-run from inside a battery because it is the one failure the gate is blind to
# BY CONSTRUCTION (a truncated log's first entry is still the right one).
# PREDICTION: the gate stays GREEN at 1296 and the EVENT COUNT collapses to the
# speaking-unit count. If the two numbers are ever equal on an unpatched tree, the
# log is truncated and the gate will not say so.
old = """        set unported_count: unported_count + 1
        let ev host.allocate(sizeof StopEvent, alignof StopEvent) as pointer[StopEvent]
        set *ev: StopEvent(tag, detail)
        stop_log.add(ev as ref[StopEvent])
        if unported_pos < 0
        {"""
new = """        set unported_count: unported_count + 1
        if unported_pos < 0
        {
            let ev host.allocate(sizeof StopEvent, alignof StopEvent) as pointer[StopEvent]
            set *ev: StopEvent(tag, detail)
            stop_log.add(ev as ref[StopEvent])"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g09.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE TAG REPLACED BY A CONSTANT — slice 75's negative control A. PREDICTION:
# stopgate RED (matched collapses), because the log and the work list are two views
# of one event stream and the gate compares them. This is the row that proves the
# gate bites at all, and it must be re-run whenever the log's collection site moves
# — which slice 76 moved.
old = """        stop_log.add(ev as ref[StopEvent])"""
new = """        let const_ev host.allocate(sizeof StopEvent, alignof StopEvent) as pointer[StopEvent]
        set *const_ev: StopEvent("constant", detail)
        stop_log.add(const_ev as ref[StopEvent])"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g10.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE TWO CALL SITES COLLAPSED TO THE VARIABLE ONE — the BindingElement arm of
# the trailing block dropped. PREDICTION: nothing moves on any of the four
# fixtures, WITH A NUMBER: the arm is worth 1 event over 1 unit at stage 1, which
# is why no fixture pins it (every shape tried stops two chapters earlier at
# get-type-for-binding-element-parent). Written as a row rather than left out, so
# the arm's cost is recorded instead of assumed.
old = """        if nk = KindBindingElement
            this.check_var_declared_names_not_shadowed(node)
"""
new = ""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g11.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE TAG RENAMED to this function's own name, which is what a reader would
# write without slice 75's finding in hand. PREDICTION: tagpin RED on the var
# fixture ALONE. The row is not about a defect — both spellings compile and both
# are honest — it is about the ROW: `resolve-name` already had one member before
# this slice (the implicit-any parameter message) and checkIdentifier will join it,
# so a caller-named tag splits one wall into three rows on the histogram the next
# successor is chosen from.
old = """        this.record_unported("resolve-name", AstNode.kind_of(node))"""
new = """        this.record_unported("check-var-declared-names-not-shadowed", AstNode.kind_of(node))"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

# ── the dry run ─────────────────────────────────────────────────────────────
#
# Every patch applied against a COPY before the first build is spent (slice 57's
# rule): an anchor that has moved is a row that measures nothing, and finding that
# out eleven builds in costs eleven builds.
bold "DRY RUN — every patch against a copy of the tree"
DRY=$WORK/dry
for g in g01 g02 g03 g04 g05 g06 g08 g09 g10 g11; do
  rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
  if python3 "$PATCHDIR/$g.py" "$DRY/f.scaly" >/dev/null 2>&1; then
    echo "  $g applies"
  else
    red "  $g DOES NOT APPLY — its anchor has moved."; exit 2
  fi
done
for g in g07; do
  rm -rf "$DRY"; mkdir -p "$DRY"; cp "$TYPEDUMP" "$DRY/f.scaly"
  if python3 "$PATCHDIR/$g.py" "$DRY/f.scaly" >/dev/null 2>&1; then
    echo "  $g applies"
  else
    red "  $g DOES NOT APPLY — its anchor has moved."; exit 2
  fi
done
rm -rf "$DRY"

baseline

control "g01 the whole function back to slice 75's unconditional stop (the premise)" "$CHECKER" "$PATCHDIR/g01.py"
control "g02 the FLAGS guard dropped"                                                "$CHECKER" "$PATCHDIR/g02.py"
control "g03 the SYMBOL test dropped"                                                "$CHECKER" "$PATCHDIR/g03.py"
control "g04 the flags guard narrowed to Let alone"                                  "$CHECKER" "$PATCHDIR/g04.py"
control "g05 the PARAMETER guard dropped"                                            "$CHECKER" "$PATCHDIR/g05.py"
control "g06 the null-symbol guard dropped"                                          "$CHECKER" "$PATCHDIR/g06.py"
control "g07 the instrument half reverted — write_stops runs no walk"                "$TYPEDUMP" "$PATCHDIR/g07.py"
control "g08 the stop log TRUNCATED to its first entry"                              "$CHECKER" "$PATCHDIR/g08.py"
control "g09 the logged tag replaced by a constant"                                  "$CHECKER" "$PATCHDIR/g09.py"
control "g10 the BindingElement call site dropped"                                   "$CHECKER" "$PATCHDIR/g10.py"
control "g11 the tag renamed after its caller"                                       "$CHECKER" "$PATCHDIR/g11.py"

echo
echo "################################################################"
bold "DONE — read every row against its PREDICTION, not against its colour."
