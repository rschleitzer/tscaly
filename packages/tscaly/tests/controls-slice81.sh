#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice81.sh — the slice-81 battery: THE BASE CONSTRAINT OF A TYPE
# PARAMETER, and a chapter whose two reports cannot fire yet.
#
# ★★★ THE SLICE'S PRODUCT IS A WORK LIST AND NOT A DIAGNOSTIC, so the TAGPIN and the
# STOPGATE are the positive instruments here and diagcheck is a purely NEGATIVE one:
# the chapter's two reports — TS2313 for a circular constraint and TS2716 for a
# circular default — both need a type parameter to be NAMED inside a constraint or a
# default, i.e. a TypeReference, and that arm is the work list's own head
# (`get-type-from-type-node 184`). Two fixtures hold the reference's own witnesses
# for those codes and this port loses both, which a SUBSEQUENCE cannot see.
#
# ★★★ WHICH MAKES ONE ROW SHARPER THAN THE REST — g06, THE ONLY WAY THIS SLICE CAN
# INVENT. The reference's getResolvedTypeParameterDefault writes resolvingDefault
# Type into the memo before computing; this port has a path the reference does not,
# because get_type_from_type_node can STOP, and a marker left behind in that slot is
# read by the next ask as a recursive entry. One ask cannot see it (the ask that
# stopped is the one that skips the TS2716 test), so the witness has to be a type
# parameter that is checked TWICE — a MERGED interface — and
# checker_type_parameter_merged_default is that file. With the retraction removed
# the port answers `C 929 934 2716` where the reference answers nothing.
#
# ★★★ SIX ROWS MOVE SOMETHING AND TWELVE COME BACK SILENT, AND THE SILENT ONES ARE
# THE MEASUREMENT RATHER THAN THE SHORTFALL (§3.5v). Four break a real decision whose
# only observer would be type IDENTITY or a FRAME COUNT — g09 (an object type treated
# as unconstrained), g10 (the memo), g12 (the `this` type's early return), g13 (the
# `any` rewrite) — and each carries at its patch the reader that would make it
# observable (§3.5ao). Two are guards that provably cannot change an answer here
# (g02, g16), one is a corpus gap (g14) and one prices a report at ZERO (g11).
#
# ★★★ THREE PREDICTIONS WERE WRONG — g07, g17 AND g18 — AND THEY CARRY THE BATTERY'S
# TWO FINDINGS. g07 says the depth limiter cannot remove a stop, because the
# constraint is resolved by TWO independent routes and only one of them runs through
# computeBaseConstraint. g17 and g18 are one mistake: the two sentinels this chapter
# turns on cannot be told apart by the TS2716 report at all, because the shape that
# would make a mixed-up test fire — a type parameter with no default — is the one
# shape with no node to report on. Both were written expecting a colour and both
# turned into proofs; see each patch.
#
# ★★ READING THE STOPGATE ON A ROW THAT CHANGES A TAG: its counts are contaminated,
# because stops.sh compares against the UNPORTED line the artifact tree recorded with
# the BASELINE binary — a disagreeing unit drops out of the histogram, so `matched`
# and `speaking` both fall. Read `matched` FIRST. The clean before/after came from
# two full run.sh + stops.sh passes: over the same 1 327 units the slice takes stop
# events 7 901 -> 7 650.
#
# ★★★ ITERATE AT STAGE 1 AND CONFIRM AT STAGE 2 ONCE — slice 64's rule. The recorded
# verdicts are stage 1's.
#
# Usage (nothing may edit the tree while this runs, and no second harness may own
# tests/out — §3.5y, which slice 81 relearned by running a stage-2 pass beside a
# stage-1 one and losing both):
#
#   packages/tscaly/tests/run.sh                      # stage 1, ~25 s
#   packages/tscaly/tests/controls-slice81.sh 2>&1 | tee /tmp/battery81.log

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
# The first three are the chapter RESOLVING — a keyword constraint, an object-type
# constraint, and the constraint/default pair that reaches the row this slice's stop
# moves to. The next three are its three unreachable halves: the two reports and the
# marker retraction. The last two are slice 60's, over the same declaration shape,
# and they are here to show that a row aimed at this chapter leaves the grammar half
# where that slice put it.
PINFILES="
$FIX/checker_type_parameter_constraint_resolves.ts
$FIX/checker_type_parameter_constraint_object.ts
$FIX/checker_type_parameter_constraint_and_default.ts
$FIX/checker_type_parameter_circular_constraint.ts
$FIX/checker_type_parameter_circular_default.ts
$FIX/checker_type_parameter_merged_default.ts
$FIX/checker_type_parameter_constraint_keyword.ts
$FIX/checker_type_parameter_default_reference.ts
"
red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl81)

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
# the dump, because every one of these units stops somewhere and the dump prints
# nothing for such a unit (TypeDump.emit's own note).
#
# ★★★ SIX OF THE EIGHT ARE EMPTY, AND THAT IS THE INSTRUMENT RATHER THAN A GAP: this
# chapter produces no diagnostic that can fire, so the pin's whole job here is to
# catch an INVENTION. g06 is the row it exists for.
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

# The STOPGATE: stops.sh's internal agreement plus the counts it prints.
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
  bold "BASELINE — four instruments"
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
  if [ "$stop" = "$STOP_BASE" ]; then
    echo "  stopgate  unmoved — $stop"
  else
    green "stopgate  MOVED   $STOP_BASE -> $stop   (matched units speaking events other)"
    moved=1
  fi
  if [ "$moved" = 0 ]; then
    if [ "$speaking" != "$DIAG_LINES" ] || [ "$diags" != "$DIAG_DIAGS" ]; then
      echo "  ungated on all four, WITH A NUMBER: $DIAG_LINES/$DIAG_DIAGS -> $speaking/$diags."
    else
      red "UNGATED ON ALL FOUR AND NOTHING MOVED AT ALL."
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
# ★★★ THE PREMISE ROW: checkTypeParameter's tail reverted to the stop slice 65 left
# there. PREDICTION: tagpin RED on the three fixtures whose tag this slice moved,
# stopgate MOVED by the whole chapter, diagcheck ungated — the slice adds no
# diagnostic that can fire, which is what the rest of the battery prices.
old = """            let tp this.get_declared_type_of_type_parameter(tp_symbol as ref[Symbol])
            if tp <> null
            {
                let t tp as ref[Type]
                let mark this.unported_mark()
                let ignored this.get_base_constraint_of_type(t)"""
new = """            let tp this.get_declared_type_of_type_parameter(tp_symbol as ref[Symbol])
            this.record_unported("get-base-constraint-of-type", KindTypeParameter)
            if false
            {
                let t tp as ref[Type]
                let mark this.unported_mark()"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g02.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# getBaseConstraintOfType's FLAG FILTER dropped, so every type is eligible.
# PREDICTION: UNGATED, and the row is a PROOF rather than a gap — the function's one
# caller in this port hands it the type a type-parameter declaration denotes, which
# passes the filter by construction. What the filter protects is the two SENTINELS,
# and g03/g04 are the rows that price that.
old = """        if (t.flags & (TypeFlagsInstantiableNonPrimitive | TypeFlagsUnionOrIntersection | TypeFlagsTemplateLiteral | TypeFlagsStringMapping | TypeFlagsIndex)) = 0
            return null
        let constraint this.get_resolved_base_constraint(t)"""
new = """        let constraint this.get_resolved_base_constraint(t)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g03.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# getDefaultFromTypeParameter's two sentinel tests dropped, so noConstraintType
# leaks out as a DEFAULT. PREDICTION: stopgate MOVED and tagpin RED — every type
# parameter that has a constraint now looks as though it had a default too, so
# checkTypeParameter reaches the assignability stop where the reference does not.
old = """        let dt d as ref[Type]
        if dt = no_constraint_type
            return null
        if dt = circular_constraint_type
            return null
        dt
    }

    ; getResolvedTypeParameterDefault, whole but for the `target` path"""
new = """        d
    }

    ; getResolvedTypeParameterDefault, whole but for the `target` path"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g04.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# getConstraintFromTypeParameter's noConstraintType test dropped, so the sentinel
# leaks out as a CONSTRAINT. PREDICTION: the mirror of g03 over the other slot —
# stopgate MOVED, because a type parameter with a DEFAULT and no constraint now
# reaches the assignability stop.
old = """        let cur Checker.type_parameter_constraint_of(t)
        if cur = null
            return null
        if (cur as ref[Type]) = no_constraint_type
            return null
        cur"""
new = """        Checker.type_parameter_constraint_of(t)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g05.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# checkTypeParameter's MARK guard removed: the two reports and the assignability
# stop are reached even where the constraint's resolution STOPPED underneath.
# PREDICTION: stopgate MOVED and NO invention — which is the row's content, because
# it shows what actually keeps this port from reporting on an incomplete answer is
# the type-reference row and not this guard.
old = """                let ignored this.get_base_constraint_of_type(t)
                if this.unported_mark() = mark
                {"""
new = """                let ignored this.get_base_constraint_of_type(t)
                if true
                {"""
assert s.count(old) == 1
s = s.replace(old, new, 1)
old2 = """                    let default_type this.get_default_from_type_parameter(t)
                    if this.unported_mark() = mark
                    {"""
new2 = """                    let default_type this.get_default_from_type_parameter(t)
                    if true
                    {"""
assert s.count(old2) == 1
open(p, "w").write(s.replace(old2, new2, 1))
PY

cat > "$PATCHDIR/g06.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE ONLY WAY THIS SLICE CAN INVENT, and the one line the reference has no need
# for: the resolvingDefaultType marker is NOT taken back out of the memo when the
# computation stopped underneath. PREDICTION: diagcheck RED and diagpin RED on
# checker_type_parameter_merged_default alone — a merged interface asks the same type
# parameter twice, and the second ask reads the leftover marker as a recursive entry
# and reports a TS2716 the reference does not.
old = """                    if dt = null
                    {
                        Checker.set_resolved_default_type(t, null)
                        return null
                    }"""
new = """                    if dt = null
                        return null"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g07.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The depth limiter closed: computeBaseConstraint is never entered.
#
# ★★★ PREDICTED RED, MEASURED SILENT, AND THE REASON IS THE ROW'S WHOLE VALUE: the
# events do not move because THE CONSTRAINT IS RESOLVED BY TWO INDEPENDENT ROUTES
# AND ONLY ONE OF THEM HAS A LIMITER. checkTypeParameter asks
# getConstraintOfTypeParameter after getBaseConstraintOfType, and that path calls
# getConstraintFromTypeParameter DIRECTLY — so closing the limiter removes the walk
# through computeBaseConstraint and not one stop. Which also says what the limiter
# can and cannot be tested with here: it needs a constraint chain more than ten
# levels deep, every level of which has to NAME a type parameter, i.e. ten
# TypeReferences behind the work list's head. Unreachable, and stated rather than
# left as a silent row.
old = """        var explore false
        if base_constraint_depth < 10
            set explore: true"""
new = """        var explore false
        if base_constraint_depth < 0
            set explore: true"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g08.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The second bound's CONTAINS test dropped, so levels 10..49 explore
# unconditionally. PREDICTION: UNGATED with nothing moving — the reference's own
# comment says it has no test case reaching fifty levels of nesting, and this corpus
# does not reach TEN: g07 is what shows the first bound carries every unit here.
old = """            if base_constraint_depth < 50
            {
                if this.stack_has_recursion_identity(identity) = false
                    set explore: true
            }"""
new = """            if base_constraint_depth < 50
                set explore: true"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g09.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# is_constrained_type's three OBJECT arms dropped, so an object type takes
# getResolvedBaseConstraint's early exit. PREDICTION: UNGATED with nothing moving,
# and it is the row that PRICES the surprise rather than proving it wrong:
# computeBaseConstraint's tail answers `return t` for an object type, so both routes
# hand back the same type and only a FRAME COUNT differs. ★The reader that would make
# it observable is the first function to compare two object types by identity, i.e.
# the same one declared_type_links' note names.
old = """        choose t.data
            when tp: TypeParameter
                return true
            when i: Interface
                return true
            when r: Reference
                return true
            when a: Anonymous
                return true
        false"""
new = """        choose t.data
            when tp: TypeParameter
                return true
        false"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g10.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The MEMO write removed: every ask recomputes. PREDICTION: UNGATED with nothing
# moving — the recomputation is deterministic and the frame is popped before the
# second ask, so no cycle is found. What the memo buys is WORK, and the reader that
# would make it observable is a type whose base constraint is expensive, which
# arrives with the members dimension.
old = """        if Checker.resolved_base_constraint_of(t) = null
            Checker.set_resolved_base_constraint(t, constraint as ref[Type])
        constraint"""
new = """        constraint"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g11.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The TS2313 report removed. PREDICTION: UNGATED on all four, and the row's whole
# content is that number: the report is ported and prices at ZERO here, because
# every circular constraint has to NAME a type parameter and that names a
# TypeReference, whose arm is the work list's head.
# checker_type_parameter_circular_constraint holds the reference's own three TS2313
# and this port answers none of them either way.
old = """                let error_node this.get_constraint_declaration(t)
                this.error_on_node_or_null(error_node, DiagType_parameter_0_has_a_circular_constraint)"""
new = """                let error_node this.get_constraint_declaration(t)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g12.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# computeBaseConstraint's isThisType early return dropped, so the `this` type's
# constraint is resolved one step further. PREDICTION: UNGATED with nothing moving —
# that constraint is the class or interface type itself (getDeclaredTypeOfClassOr
# Interface writes it), and one more step through getNextBaseConstraint hands the
# same object type back. ★The reader that would separate them is a `this` type whose
# constraint is itself a type variable, which needs instantiateType.
old = """            if Checker.is_this_type_of(t)
                return constraint
            return this.get_next_base_constraint(constraint)"""
new = """            return this.get_next_base_constraint(constraint)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g13.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The `any` REWRITE dropped: `<T extends any>` keeps `any` as its constraint where
# the reference makes it `unknown`. PREDICTION: UNGATED with nothing moving — the
# difference is a TYPE, and nothing in this port prints one for a type parameter
# (type_to_string's tail records `type-to-string` and answers false).
# checker_type_parameter_constraint_resolves' third line is the witness that would
# speak the day getTypeOfNode's expression arm lands.
old = """                if (c.flags & TypeFlagsAny) <> 0
                {
                    if this.is_error_type(c) = false
                    {"""
new = """                if false
                {
                    if this.is_error_type(c) = false
                    {"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g14.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The MAPPED-TYPE arm of the `any` rewrite dropped, so a mapped type's key
# constraint takes `unknown` too instead of reporting. PREDICTION: UNGATED at stage 1,
# and a CORPUS fact rather than a structural one — the shape it needs is an `any`
# constraint on a MAPPED type's own type parameter, and stage 1 holds none.
# ★MEASURED at stage 2: the row `string-number-symbol-type 201` fires ONCE over 18 096
# units, which settles it as UNCOVERED rather than UNREACHABLE — the one verdict in
# this battery the cheap tree cannot give.
old = """                        if mapped
                        {
                            this.record_unported("string-number-symbol-type", KindMappedType)
                            return null
                        }"""
new = """                        if false
                        {
                            this.record_unported("string-number-symbol-type", KindMappedType)
                            return null
                        }"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g15.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The inferred-constraint GUARD's stop removed, so an `infer T` answers nil instead
# of reporting. PREDICTION: stopgate MOVED — this is the row the slice OPENS, worth
# 20 units and 50 events of stage 1, and the largest single thing it adds to the work
# list. Answering nil would be silently WRONG: the reference forms an intersection of
# the inferred constraints, and for `Foo<infer X>` that constraint exists.
old = """                    if AstNode.kind_of(p as ref[AstNode]) = KindInferType
                    {
                        this.record_unported("get-inferred-type-parameter-constraint", KindInferType)
                        return null
                    }"""
new = """                    if AstNode.kind_of(p as ref[AstNode]) = KindInferType
                        return null"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g16.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# getConstraintDeclaration's KIND test dropped. PREDICTION: UNGATED, and it is a
# PROOF: the walk is over the declarations of a symbol whose flags say TypeParameter,
# and every declaration of such a symbol IS a TypeParameterDeclaration — so the test
# the reference writes cannot select anything here. It is transcribed rather than
# folded away because the day a JSDoc `@template` declares one differently, the
# absence would be silent.
old = """                let dn d as ref[AstNode]
                if AstNode.kind_of(dn) = KindTypeParameter
                {
                    let c AstNode.type_parameter_constraint_of(dn)
                    if c <> null
                        return c
                }"""
new = """                let dn d as ref[AstNode]
                {
                    let c AstNode.type_parameter_constraint_of(dn)
                    if c <> null
                        return c
                }"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g17.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The TS2716 test aimed at noConstraintType instead of circularConstraintType — the
# SENTINEL-IDENTITY row.
#
# ★★★ PREDICTED RED BY INVENTION, MEASURED SILENT, AND IT IS A PROOF RATHER THAN A
# CORPUS GAP — the two sentinels cannot be told apart BY THIS REPORT at all.
# getResolvedTypeParameterDefault answers noConstraintType exactly when the type
# parameter has NO default declaration, and the report's error node is
# `tpNode.DefaultType`: the shape that would make the mistaken test fire is the one
# shape with nothing to report ON, so error_on_node_or_null drops it. A sentinel
# mix-up here is invisible; the same mix-up one hop away (g06) invents a line.
old = """                        if (rd as ref[Type]) = circular_constraint_type
                            this.error_on_node_or_null(AstNode.type_parameter_default_of(node), DiagType_parameter_0_has_a_circular_default)"""
new = """                        if (rd as ref[Type]) = no_constraint_type
                            this.error_on_node_or_null(AstNode.type_parameter_default_of(node), DiagType_parameter_0_has_a_circular_default)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g18.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The three markers collapsed onto ONE type.
#
# ★★★ PREDICTED RED, MEASURED SILENT, FOR g17's REASON AND NOT FOR A NEW ONE. The
# mechanism is real — with noConstraintType and resolvingDefaultType the same object,
# a type parameter with no default writes "no default" into the slot and the next ask
# reads it as "resolving" and overwrites it with circularConstraintType — but the
# TS2716 that would follow has no error node, because a parameter with no default is
# what got there. ★So what keeps the three markers safe on this corpus is NOT that
# they are three allocations; it is that the one report able to tell them apart is
# aimed at a node that does not exist. Read g06 for the same identity question in the
# position where it does bite.
old = """        set circular_constraint_type: this.new_object_type(ObjectFlagsAnonymous, null) as ref[Type]
        set resolving_default_type: this.new_object_type(ObjectFlagsAnonymous, null) as ref[Type]"""
new = """        set circular_constraint_type: no_constraint_type
        set resolving_default_type: no_constraint_type"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

# ── the dry run ─────────────────────────────────────────────────────────────
bold "DRY RUN — every patch against a copy of the tree"
DRY=$WORK/dry
for g in g01 g02 g03 g04 g05 g06 g07 g08 g09 g10 g11 g12 g13 g14 g15 g16 g17 g18; do
  rm -rf "$DRY"; mkdir -p "$DRY"; cp "$CHECKER" "$DRY/f.scaly"
  if python3 "$PATCHDIR/$g.py" "$DRY/f.scaly" >/dev/null 2>&1; then
    echo "  $g applies"
  else
    red "  $g DOES NOT APPLY — its anchor has moved."; exit 2
  fi
done
rm -rf "$DRY"

baseline

control "g01 checkTypeParameter's tail reverted to the stop (the premise)"    "$CHECKER" "$PATCHDIR/g01.py"
control "g02 getBaseConstraintOfType's flag filter dropped"                  "$CHECKER" "$PATCHDIR/g02.py"
control "g03 getDefaultFromTypeParameter's sentinel tests dropped"           "$CHECKER" "$PATCHDIR/g03.py"
control "g04 getConstraintFromTypeParameter's sentinel test dropped"         "$CHECKER" "$PATCHDIR/g04.py"
control "g05 checkTypeParameter's mark guard removed"                        "$CHECKER" "$PATCHDIR/g05.py"
control "g06 the resolvingDefaultType marker not retracted on the stop path"  "$CHECKER" "$PATCHDIR/g06.py"
control "g07 the depth limiter closed (computeBaseConstraint never entered)"  "$CHECKER" "$PATCHDIR/g07.py"
control "g08 the stack CONTAINS test dropped (levels 10..49 always explore)"  "$CHECKER" "$PATCHDIR/g08.py"
control "g09 is_constrained_type's object arms dropped"                      "$CHECKER" "$PATCHDIR/g09.py"
control "g10 the base-constraint memo write removed"                         "$CHECKER" "$PATCHDIR/g10.py"
control "g11 the TS2313 report removed"                                      "$CHECKER" "$PATCHDIR/g11.py"
control "g12 computeBaseConstraint's isThisType early return dropped"        "$CHECKER" "$PATCHDIR/g12.py"
control "g13 the \`any\` constraint rewrite dropped"                          "$CHECKER" "$PATCHDIR/g13.py"
control "g14 the mapped-type arm of the \`any\` rewrite dropped"              "$CHECKER" "$PATCHDIR/g14.py"
control "g15 the inferred-constraint guard's stop removed"                   "$CHECKER" "$PATCHDIR/g15.py"
control "g16 getConstraintDeclaration's kind test dropped"                   "$CHECKER" "$PATCHDIR/g16.py"
control "g17 the TS2716 test aimed at noConstraintType"                      "$CHECKER" "$PATCHDIR/g17.py"
control "g18 the three markers collapsed onto one type"                      "$CHECKER" "$PATCHDIR/g18.py"

echo
echo "################################################################"
bold "DONE — read every row against its PREDICTION, not against its colour."
