#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice98.sh — the slice-98 battery: THE APPARENT TYPE OF A REFERENCE.
#
# ★★★ THE ROW THIS SLICE CLOSES IS SLICE 97'S OWN NEAR WALL, AND THE SLICE IS
# FOUR LINES OF CODE. `get-type-with-this-argument` was 85 events over 31 units at
# stage 1 and 1 359 events over 519 units at stage 2; what removes it is routing
# getApparentType's REFERENCE arm into the getTypeWithThisArgument that
# resolve_object_type_members has called since slice 67. So this battery's first
# job is not to defend a new function — it is to show that a chapter whose whole
# product is a TYPE IDENTITY can be broken in six different ways that no yardstick
# in this directory would notice.
#
# ★★★ THE ELEVENTH INSTRUMENT, AND THE SHARPEST CASE OF THE ARGUMENT THE LAST FOUR
# WERE BUILT ON. This chapter's answer has the SAME PRINTED NAME as its input — a
# reference is named after its target, so `C` re-anchored on `this` prints `C` —
# and it sits at no node, resolves no symbol and reports nothing. `tscaly_types
# --withthis` prints `W <inid> <argid> <outid> <arm> <name>` per call the function
# ANSWERED. The `argid` column is the one the chapter is about: a caller that
# passes the wrong `this` argument still produces a well-formed reference with the
# right name, the right arm and a fresh id, and only that column says it is
# anchored on the wrong thing.
#
# ★★★ THE HAND COUNT THAT LICENSES THE NUMBERS BELOW, run before the baseline
# printed anything: `--withthis` over the 1 412 units of the pre-fixture tree reads
# **872 rows — 690 arm 1 and 182 arm 0** — and the same tree with this slice's one
# arm reverted reads **787, of which 605 arm 1**. The difference is 85 rows, all of
# them arm 1, against 85 stop events removed. Every stop this slice deleted became
# an ANSWER, one for one, which is a checksum neither instrument gives alone.
#
# ★★★ ITERATE AT STAGE 1 AND CONFIRM AT STAGE 2 ONCE — slice 64's rule. The
# recorded verdicts are stage 1's, and slice 97's finding eight is why that is said
# rather than assumed: a containment proof is a stage-1 proof.
#
# Usage (nothing may edit the tree while this runs, and no second harness may own
# tests/out — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # stage 1
#   packages/tscaly/tests/controls-slice98.sh 2>&1 | tee /tmp/battery98.log
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

# ★ ONE MECHANISM PER FILE (slice 72's rule). Six files: the premise arm, the
# second producer of it, the concatenate path, the identity arm, the null-argument
# call site, and the wall. TWO of the six are containment proofs rather than
# measurements — withthis_stops.ts for both arms with no input — and each says so
# in its own header.
PINFILES="
$FIX/withthis_apparent.ts
$FIX/withthis_constraint.ts
$FIX/withthis_generic.ts
$FIX/withthis_identity.ts
$FIX/withthis_base.ts
$FIX/withthis_stops.ts
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

WORK=$(mktemp -d -t tscaly-ctl98)

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

# ★★★ THE WITHPIN — slice 98's ELEVENTH instrument; the argument is in
# WithThisEvent's own header. `W <inid> <argid> <outid> <arm> <name>` per call
# getTypeWithThisArgument ANSWERED, in the order the check reached them.
withpin_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$(run_limited "$WORK/tscaly_types" --withthis "$f" 2>/dev/null | tr '\n' '|')"
  done
}

# ★★★ THE WHOLE-CORPUS WITHGATE, beside the pin for slice 92's h08/h11/h25 reason:
# a fixture is written around the arm its author is thinking of, and the shape that
# distinguishes an arm is usually not that shape. It reads 872 against the six
# fixtures' 26, so the corpus is a live half of every row below and not a constant.
#
# ★ The units are dispatched in PARALLEL and each writes its own file, then the
# files are concatenated in a fixed order. A shared pipe would interleave and the
# checksum would move on its own — an instrument that disagrees with itself is
# worse than none.
#
# ★★ IT IS FOUR NUMBERS AND A CHECKSUM, so four breakages are told apart without a
# diff: a chapter that stops answering moves the COUNT, an arm that fires where it
# should not moves the ARM-1 count, a wrong thisArgument moves the ANCHORED count
# (rows whose argid is not 0) at every other column unchanged, and a wrong type
# identity or a wrong printed name moves only the CHECKSUM.
#
# ★ NUL-DELIMITED SINCE SLICE 101, AND THE FIX IS NOT COSMETIC: `xargs` splits on
# WHITESPACE, the stage-2 corpus holds one unit whose name contains a space, and
# from it onward the `-n 2` pairing shifts by one — which redirects the dumper's
# stdout INTO A CORPUS FILE. Invisible at stage 1, where no unit path has a space.
# See §3.5eu finding nine.
withgate() {
  local i=0 u
  rm -rf "$WORK/wout" "$WORK/wpairs"; mkdir -p "$WORK/wout"
  while IFS= read -r u; do
    printf '%s\0%s\0' "$u" "$(printf '%s/wout/%06d' "$WORK" "$i")"
    i=$((i+1))
  done < "$WORK/units.txt" > "$WORK/wpairs"
  LIMIT=$LIMIT xargs -0 -P 8 -n 2 sh -c 'perl -e "alarm $LIMIT; exec @ARGV" "$0" --withthis "$1" > "$2" 2>/dev/null' "$WORK/tscaly_types" < "$WORK/wpairs"
  find "$WORK/wout" -type f -print0 | xargs -0 cat > "$WORK/with.all"
  local n a1 anc q
  n=$(grep -c '^W ' "$WORK/with.all")
  a1=$(grep '^W ' "$WORK/with.all" | awk '$5==1' | wc -l | tr -d ' ')
  anc=$(grep '^W ' "$WORK/with.all" | awk '$3!=0' | wc -l | tr -d ' ')
  q=$(grep -c ' ?$' "$WORK/with.all")
  echo "$n $a1 $anc $q $(cksum < "$WORK/with.all" | cut -d' ' -f1)"
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

DIAG_BASE=""; DIAG_LINES=""; DIAG_DIAGS=""; STOP_BASE=""; WITH_BASE=""

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
  withpin_of > "$WORK/base.with"
  find "$PKG/tests/out/cases" -path '*/units/*' -type f \
       \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.mjs' -o -name '*.cjs' \) \
       | sort > "$WORK/units.txt"
  STOP_BASE=$(stopgate)
  WITH_BASE=$(withgate)
  echo
  echo "  the STOPPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.stops"
  echo
  echo "  the TAGPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.tags"
  echo
  echo "  the WITHPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.with"
  echo
  echo "  BASELINE   diagcheck $DIAG_BASE consistent, $DIAG_LINES speaking, $DIAG_DIAGS diagnostics"
  echo "             stopgate  (matched units speaking events other) = $STOP_BASE"
  echo "             withgate  (rows arm1 anchored unnamed checksum) over $(wc -l < "$WORK/units.txt" | tr -d ' ') units = $WITH_BASE"
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
  withpin_of > "$WORK/ctl.with"
  stop=$(stopgate)
  local with_g
  with_g=$(withgate)
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
    echo "  diagpin   unmoved — all six pin files answer the same C section."
  else
    green "diagpin   RED"
    diff "$WORK/base.diags" "$WORK/ctl.diags" | cut -c1-240 | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.tags" "$WORK/ctl.tags"; then
    echo "  tagpin    unmoved — all six fixtures answer the same tag."
  else
    green "tagpin    RED"
    diff "$WORK/base.tags" "$WORK/ctl.tags" | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.stops" "$WORK/ctl.stops"; then
    echo "  stoppin   unmoved — all six fixtures log the same stops, in order."
  else
    green "stoppin   RED"
    diff "$WORK/base.stops" "$WORK/ctl.stops" | cut -c1-240 | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.with" "$WORK/ctl.with"; then
    echo "  withpin   unmoved — all six fixtures answer the same arms, anchors and identities."
  else
    green "withpin   RED"
    diff "$WORK/base.with" "$WORK/ctl.with" | cut -c1-240 | sed 's/^/    /'
    moved=1
  fi
  if [ "$stop" = "$STOP_BASE" ]; then
    echo "  stopgate  unmoved — $stop"
  else
    green "stopgate  MOVED   $STOP_BASE -> $stop   (matched units speaking events other)"
    moved=1
  fi
  if [ "$with_g" = "$WITH_BASE" ]; then
    echo "  withgate  unmoved — $with_g"
  else
    green "withgate  MOVED   $WITH_BASE -> $with_g   (rows arm1 anchored unnamed checksum)"
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

P['g01'] = ('''# THE PREMISE — getApparentType's REFERENCE arm reverted to the stop it was until
# this slice. PREDICTION: everything RED, and the two gates moving by exactly the
# numbers the hand count named — 85 stop events back, 85 arm-1 rows gone.''',
'''old = """            if ty <> t
                return this.get_type_with_this_argument(ty, t, false)"""
new = """            if ty <> t
            {
                this.record_unported("get-type-with-this-argument", ty.object_flags)
                return null
            }"""''')

P['g02'] = ('''# THE PREMISE'S GUARD — the arm fires for EVERY reference, not only where the
# instantiable hop replaced the type. PREDICTION: the withgate's arm-1 count goes
# UP and its checksum moves, because a plain `C` receiver now gets re-anchored on
# itself. It is the row that says the guard is the whole difference between this
# arm and an unconditional rewrite of every object type in the corpus.''',
'''old = """        if (ty.object_flags & ObjectFlagsReference) <> 0
        {
            if ty <> t
                return this.get_type_with_this_argument(ty, t, false)
        }"""
new = """        if (ty.object_flags & ObjectFlagsReference) <> 0
            return this.get_type_with_this_argument(ty, t, false)"""''')

P['g03'] = ('''# THE ARGUMENT — getApparentType passes NULL where the reference passes the
# ORIGINAL type, so the answer is anchored on the target's own `this` type instead
# of on the type parameter the constraint came from. PREDICTION: the withgate's
# ANCHORED count is unchanged, the arm-1 count is unchanged, the printed names are
# unchanged, and the CHECKSUM moves. The row the argid column exists for, and the
# defect a name-only pin cannot see.''',
'''old = """            if ty <> t
                return this.get_type_with_this_argument(ty, t, false)"""
new = """            if ty <> t
                return this.get_type_with_this_argument(ty, null, false)"""''')

P['g04'] = ('''# THE INSTANTIABLE HOP removed from getApparentType, so `ty` is always `t` and the
# reference arm can never fire. PREDICTION: everything RED — but it is NOT g01
# twice: g01 removes the answer and leaves the constraint walk, this removes the
# walk and leaves the answer unreachable, so the stop that comes back is a
# DIFFERENT one and the two rows must be read together to see that the arm has two
# premises rather than one.''',
'''old = """        var base: ref[Type]? null
        if (t.flags & TypeFlagsInstantiable) <> 0
        {"""
new = """        var base: ref[Type]? null
        if false
        {"""''')

P['g05'] = ('''# THE ARITY TEST dropped, so an already-anchored reference is anchored again.
# PREDICTION: ungated with an argument — the arm is the reference's IDEMPOTENCE
# guard and nothing in this corpus asks twice (arm 2 is 0 rows at stage 1). A row
# that CANNOT go red, with its containment proof in withthis_stops.ts.''',
'''old = """            if Checker.type_parameter_count_of(tg) <> argn
            {
                this.record_with_this(t, null, t, 2)
                return t
            }"""
new = """            if false
            {
                this.record_with_this(t, null, t, 2)
                return t
            }"""''')

P['g06'] = ('''# THE NULL-ARGUMENT FALLBACK removed, so a caller that passes no `this` argument
# gets a reference anchored on nothing. PREDICTION: the withgate's ANCHORED count
# falls and the checksum moves — the class and interface checks are the two call
# sites that pass null, and withthis_base.ts is their fixture.''',
'''old = """            var arg this_argument
            if arg = null
                set arg: Checker.this_type_of(tg)"""
new = """            var arg this_argument"""''')

P['g07'] = ('''# THE needApparentType TAIL replaced by the frozen `false` this slice removed, i.e.
# the flag put back the way slice 97's finding four found it. PREDICTION: UNGATED
# ON ALL SEVEN, PREDICTED — the flag has no input on this corpus, because its only
# true caller upstream is getApparentTypeOfIntersectionType and no intersection
# ever becomes a type here (withthis_stops.ts measures the wall in front of it).
# The arm is defended from the REFERENCE, not from this row.''',
'''old = """        if need_apparent_type
        {
            let ap this.get_apparent_type(t)
            if ap = null
                return null
            this.record_with_this(t, null, ap as ref[Type], 3)
            return ap
        }"""
new = """        if false
        {
            let ap this.get_apparent_type(t)
            if ap = null
                return null
            this.record_with_this(t, null, ap as ref[Type], 3)
            return ap
        }"""''')

P['g08'] = ('''# THE INTERSECTION STOP removed — the arm answers `t` instead of reporting.
# PREDICTION: ungated with an argument, and it is a containment proof one chapter
# out: `A & B` stops at getTypeFromTypeNode's IntersectionType arm, so no
# intersection in this corpus is ever a TYPE and this arm has no input by
# construction. Measured separately from g07 because the two arms are held by
# DIFFERENT walls and a reader who sees one green must not read it as the other.''',
'''old = """        if (t.flags & TypeFlagsIntersection) <> 0
        {
            this.record_unported("type-with-this-argument-intersection", 0)
            return null
        }
        if need_apparent_type"""
new = """        if false
        {
            this.record_unported("type-with-this-argument-intersection", 0)
            return null
        }
        if need_apparent_type"""''')

P['g09'] = ('''# THE APPEND PUT AT THE FRONT of the argument list instead of the back.
# PREDICTION: the withgate's checksum moves and its three counts do not — a
# non-generic class re-anchors an EMPTY list, so the two orders are the same
# operation there and only the generic fixtures can tell them apart. The row
# withthis_generic.ts exists for, and the shape a corpus of non-generic classes
# would have called green.''',
'''old = """            let combined this.new_type_list(type_arguments)
            combined.add(arg)
            let made this.create_type_reference(tg, combined, ObjectFlagsNone)"""
new = """            let combined this.new_type_list(null)
            combined.add(arg)
            if type_arguments <> null
            {
                let src type_arguments as ref[Array[ref[Type]?]]
                let sn src.get_length() as int
                var si 0
                while si < sn
                {
                    combined.add(src[si])
                    set si: si + 1
                }
            }
            let made this.create_type_reference(tg, combined, ObjectFlagsNone)"""''')

P['g10'] = ('''# THE INSTANTIATION MEMO bypassed, so every re-anchoring mints a fresh type.
# PREDICTION: the withgate's checksum moves at all three counts unchanged, because
# the answer is structurally right and its IDENTITY is not — and identity is what
# every later comparison in this checker is made of. It prices createTypeReference's
# cache from the one chapter that asks it the same question over and over.''',
'''old = """        let existing Checker.find_instantiation(target, type_arguments)
        if existing <> null
            return existing"""
new = """        let existing Checker.find_instantiation(target, type_arguments)
        if false
            return existing"""''')

P['g11'] = ('''# THE ANSWER REPLACED BY ITS INPUT — the reference arm returns the constraint
# unchanged instead of re-anchoring it. PREDICTION: no stop comes back and the
# WITHPIN loses this slice's 85 rows, so the port answers a WELL-FORMED WRONG TYPE
# where it used to answer a wall. It is the silent shape the whole instrument was
# built for: the printed name of the two answers is the same string.''',
'''old = """            if ty <> t
                return this.get_type_with_this_argument(ty, t, false)"""
new = """            if ty <> t
                return ty"""''')

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

control "g01 THE PREMISE (getApparentType's reference arm) reverted to its stop" $CHECKER "$PATCHDIR/g01.py"
control "g02 the arm's ty<>t GUARD dropped" $CHECKER "$PATCHDIR/g02.py"
control "g03 the ORIGINAL TYPE not passed as the this argument" $CHECKER "$PATCHDIR/g03.py"
control "g04 the INSTANTIABLE HOP removed, so the arm is unreachable" $CHECKER "$PATCHDIR/g04.py"
control "g05 the ARITY (idempotence) test dropped" $CHECKER "$PATCHDIR/g05.py"
control "g06 the NULL-ARGUMENT fallback removed" $CHECKER "$PATCHDIR/g06.py"
control "g07 the needApparentType TAIL frozen back to false" $CHECKER "$PATCHDIR/g07.py"
control "g08 the INTERSECTION STOP removed" $CHECKER "$PATCHDIR/g08.py"
control "g09 the this argument APPENDED AT THE FRONT" $CHECKER "$PATCHDIR/g09.py"
control "g10 createTypeReference's INSTANTIATION MEMO bypassed" $CHECKER "$PATCHDIR/g10.py"
control "g11 the reference arm answers its INPUT instead of re-anchoring it" $CHECKER "$PATCHDIR/g11.py"

echo
echo "################################################################"
bold "DONE - read every row against its PREDICTION, not against its colour."
