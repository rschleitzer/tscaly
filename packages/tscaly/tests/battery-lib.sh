#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# battery-lib.sh — THE CONTROL BATTERY'S MACHINERY, ONCE INSTEAD OF PER SLICE.
#
# ★★★ WHY IT EXISTS, AND IT IS A COST MEASUREMENT AND NOT A TIDY-UP. Every battery from
# slice 103 to slice 108 carried 550-630 lines of this, copied from its predecessor and
# then edited: slice 108's scaffolding differs from slice 107's in 193 lines out of 629.
# Four slices had paid for the same shell, and an instrument added in one battery was
# invisible to the next unless somebody copied it forward. Measured on slice 108: the
# apparatus around a slice ran to 2 290 written lines against 761 lines of ported Scaly —
# 3.0x the product, and about 10 apparatus lines per REFERENCE line at the checker
# dimension's historical rate of 225 reference lines a slice. This file is the largest
# single piece of that, removed.
#
# ★★★ IT DOES NOT WEAKEN THE MEASUREMENT, and that has to be said explicitly because the
# apparatus HAS earned its keep where it is real: slice 108's battery corrected four of
# its own predictions, and the stage-2 confirmation caught an invention on nine units that
# stage 1 structurally cannot see. The rows, the fixtures and the stage-2 pass stay. What
# is removed is the COPYING.
#
# Usage — a battery becomes its rows plus about fifteen lines:
#
#   . "$(dirname "$0")/battery-lib.sh"
#   PINFILES="$FIX/foo_one.ts $FIX/foo_two.ts"
#   battery_init "$@"          # parses the row filter, makes $WORK and $PATCHDIR
#   baseline
#   control "g01 THE PREMISE" $CHECKER "$PATCHDIR/g01.py"
#
# ★★ A NEW PIN GOES IN HERE, not in one battery — then every later battery asks it
# without being edited. ★An instrument dropped from a battery needs a REASON in that
# battery's header: slice 99's rule is that a new chapter does not replace the old
# instruments, and an instrument removed in silence is one that cannot go red.
set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.2/tscaly/checker.scaly
AST=$PKG/0.1.2/tscaly/ast.scaly
FIX=$PKG/tests/fixtures
CASES=$PKG/tests/out/cases

. packages/tscaly/tests/toolchain.sh || exit 2
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

if [ ! -f "$PKG/tests/out/run.db" ]; then
  red "no run store at $PKG/tests/out/run.db — run tests/run.sh first."
  exit 2
fi


PATCHED_FILES=""
cleanup() {
  local f i=0
  for f in $PATCHED_FILES; do
    [ -f "$WORK/orig.$i" ] && cp "$WORK/orig.$i" "$f"
    i=$((i+1))
  done
  [ -n "$PATCHED_FILES" ] && red "INTERRUPTED — $PATCHED_FILES restored from the row that was running."
  [ -n "${WORK:-}" ] && rm -rf "$WORK"
}
trap cleanup EXIT INT TERM

build_bins() {
  "$SCALYC" -c --no-prelude -o "$WORK/pkg.o" "$PKG/0.1.2/tscaly.scaly" > "$WORK/build.log" 2>&1 || return 1
  "$SCALYC" -c -o "$WORK/types.o" "$PKG/0.1.2/tscaly_types.scaly" >> "$WORK/build.log" 2>&1 || return 1
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

# ★★★ THE RELPIN — slice 101's instrument; the argument is in RelEvent's own
# header. `A <pos> <source flags> <target flags> <verdict>` per call of
# checkTypeRelatedToAndOptionallyElaborate, verdict 1 RELATED, 0 NOT RELATED, 2
# COULD NOT ANSWER. It exists because this chapter's commonest product is an
# ABSENCE: a relation that answers TRUE writes no diagnostic, no type and — now
# that the stop it replaced is gone — nothing in the stop log either.
relpin_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$(run_limited "$WORK/tscaly_types" --relations "$f" 2>/dev/null | tr '\n' '|')"
  done
}

# ★★★ THE KINDPIN — slice 102's instrument; the argument is in KindEvent's own
# header. `K <source flags> <kind> <strict> <arm> <verdict>` per call of
# isTypeAssignableToKindEx. It exists because the RELPIN cannot see this chapter:
# that pin sits at checkTypeRelatedToAndOptionallyElaborate and these calls enter
# the relation one level below it, and most of them never enter it at all.
kindpin_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$(run_limited "$WORK/tscaly_types" --kinds "$f" 2>/dev/null | tr '\n' '|')"
  done
}

# ★★★ THE FORKPIN — slice 103's instrument; the argument is in ForkEvent's own
# header. `F <source flags> <target flags> <route> <branch> <verdict>` per call of
# the structured branch of isRelatedToEx. It is asked here for slice 99's reason —
# a new chapter does not replace the old instruments — and it is not idle: an alias
# that answers hands the relation a type where it used to get nothing.
forkpin_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$(run_limited "$WORK/tscaly_types" --forks "$f" 2>/dev/null | tr '\n' '|')"
  done
}

# ★★ THE THREE PINS OF THE LAST TWO SLICES, asked beside this slice's own for
# slice 99's reason — **a new instrument does not replace the old ones**. They are
# asked over the FIXTURES only: a relation change that moved a member table or an
# object-literal type would be a defect of a different kind, and the fixtures are
# where it would show first.
fnpin_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$(run_limited "$WORK/tscaly_types" --functions "$f" 2>/dev/null | tr '\n' '|')"
  done
}

objpin_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$(run_limited "$WORK/tscaly_types" --objlits "$f" 2>/dev/null | tr '\n' '|')"
  done
}

mempin_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$(run_limited "$WORK/tscaly_types" --members "$f" 2>/dev/null | tr '\n' '|')"
  done
}

# ★★★ THE CALLPIN — slice 108's instrument; the argument is in CallEvent's own
# header. `L <pos> <kind> <verdict> <argcount> <paramcount> <minargs>` per call of
# resolve_signature's two ported doors. It exists because this chapter's product is a
# SIGNATURE: a call that resolves writes no diagnostic, no type this port can print,
# and — now that the row is gone — nothing in the stop log either.
callpin_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$(run_limited "$WORK/tscaly_types" --calls "$f" 2>/dev/null | tr '\n' '|')"
  done
}

# ★★★ THE TYPEPIN — slice 109's instrument, and it closes a hole the other fourteen
# had from the start: NONE OF THEM SEES THE DUMP. `tags_of` greps the UNPORTED line
# out of the dumper's output and throws the rest away, `diags_of` asks for the C
# section alone, and every gate below reads a side channel. So the T SECTION — the
# thing the checker yardstick actually compares, and the whole product of a slice
# that ports an arm of getTypeOfNode — was measurable by no row of any battery from
# 103 to 108.
#
# ★★ IT IS THE FULL DUMP AND NOT A COUNT, because the failure this chapter produces
# is a WRONG NAME at a right position: an arm that answers `any` where the reference
# answers a type writes the same number of lines. A count moves for a missing answer
# and never for a wrong one.
typepin_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$(run_limited "$WORK/tscaly_types" "$f" 2>/dev/null | tr '\n' '|')"
  done
}

# ★★★ THE WHOLE-CORPUS TYPEGATE, beside the pin for the relgate's reason, and it is
# the gate this family was missing: FOUR NUMBERS AND A CHECKSUM over every unit's
# own dump. A unit that stops answering moves ANSWERING against REPORTING; an arm
# that answers fewer nodes moves the T-LINE count; and an arm that answers a
# DIFFERENT NAME at the same position moves only the CHECKSUM — which is the one
# breakage no other instrument in this file can see.
#
# ★ It needs no oracle: it is our side against our side, which is what a control
# battery measures. The yardstick's own agreement is run.sh's job.
#
# ★ NUL-delimited and concatenated through `find | xargs cat`, for §3.5eu finding
# nine's two reasons: one stage-2 unit's path contains a SPACE, which shifts an
# `xargs -n 2` pairing and redirects the dumper's stdout into a CORPUS FILE, and a
# glob over 17 552 files is *Argument list too long*.
# ★★★ THE FIVE CORPUS GATES READ ONE DUMPER PASS (2026-09-02). Each of them used to
# spawn its own process per unit — five parses, five binds, five checks of every unit
# per row, and five files per unit written and deleted again, which on a 27-row
# battery is about 200 000 file events for the box's endpoint protection to scan
# (§3.5ck). `tscaly_types --gates` prints the type dump and the four event logs off
# ONE checker run, separated by `==== TSCALY-SECTION <name>` lines; `gates_pass`
# runs it once per CHUNK (`tscaly_types --gates --batch`, harness.run_batch) and
# splits the five sections into the same `<name>.all` files the gates always read,
# in store order. ★Byte-identity of every section with
# its standalone flag was measured over all 1 580 stage-1 units when this landed
# (0 differing), and the gate arithmetic below is the old arithmetic unchanged —
# only the `.all` files' PRODUCER moved. One pass is ~9 s where five were ~42 s.
#
# ★ `.all` is concatenated in SORTED unit order now, where the old per-gate loop
# used `find`'s directory order; both are stable within a run, and a checksum is
# only ever compared against the same run's baseline.
gates_pass() {
  rm -rf "$WORK/gout"
  WORK=$WORK LIMIT=$LIMIT python3 - <<'PY'
import os, sys
sys.path.insert(0, "packages/tscaly/tests")
import harness as H
W = os.environ["WORK"]
store = H.Store.open()
units = [(p, c) for ci, idx, cname, key, uname, p, c in store.units()]
got = H.run_batch(os.path.join(W, "tscaly_types"), "--gates", units, os.path.join(W, "gout"), 8, float(os.environ["LIMIT"]))
names = ['type', 'rel', 'kind', 'fork', 'call']
seps = [b'==== TSCALY-SECTION relations\n', b'==== TSCALY-SECTION kinds\n',
        b'==== TSCALY-SECTION forks\n', b'==== TSCALY-SECTION calls\n']
outs = {n: open(f'{W}/{n}.all', 'wb') for n in names}
answering = reporting = 0
for p, _ in units:
    rc, rest, err = got.get(p, (1, b"", b""))
    if rc != 0:
        rest = b""                 # a killed or crashed dumper: every section empty,
    parts = []                     # as its files were
    for sp in seps:
        if sp in rest:
            a, rest = rest.split(sp, 1)
        else:
            a, rest = rest, b''
        parts.append(a)
    parts.append(rest)
    if any(l.startswith(b'T ') for l in parts[0].split(b'\n')):
        answering += 1
    if any(l.startswith(b'UNPORTED ') for l in parts[0].split(b'\n')):
        reporting += 1
    for n, part in zip(names, parts):
        outs[n].write(part)
for f in outs.values():
    f.close()
open(f'{W}/gates.tcount', 'w').write(f'{answering} {reporting}\n')
PY
}

typegate() {
  local ans rep tl
  read -r ans rep < "$WORK/gates.tcount"
  tl=$(grep -c '^T ' "$WORK/type.all")
  echo "$ans $rep $tl $(cksum < "$WORK/type.all" | cut -d' ' -f1)"
}

# ★★★ THE WHOLE-CORPUS RELGATE, beside the pin for slice 92's h08/h11/h25 reason:
# a fixture is written around the arm its author is thinking of, and the shape
# that distinguishes an arm is usually not that shape.
#
# ★★ IT IS FOUR NUMBERS AND A CHECKSUM, so four breakages are told apart without a
# diff: a site that stops being wired moves the ROW count; an arm that answers
# differently moves RELATED against NOT-RELATED; a guard that turns a report into
# a row moves COULD-NOT-ANSWER; and a wrong position or a wrong pair of flag words
# moves only the CHECKSUM.
#
# ★★★ THE PAIR LIST IS NUL-DELIMITED AND THAT IS NOT A STYLE CHOICE — IT IS THE
# DEFECT THIS SLICE FOUND IN ITS OWN HARNESS AND IN THE ONE IT WAS COPIED FROM.
# `xargs` splits on WHITESPACE, the stage-2 corpus holds exactly ONE unit whose
# name contains a space (`u00_①Ⅻㄨㄩ 啊阿…`), and from that unit onward the `-n 2`
# pairing shifts by one — so `> "$2"` redirects the dumper's stdout INTO A CORPUS
# FILE and half the tree is replaced by `cannot read …/rout/009997`. It is
# invisible at stage 1, where no unit path has a space, which is why the pattern
# survived several slices. See §3.5eu finding nine.
relgate() {
  local n rel no cna
  n=$(grep -c '^A ' "$WORK/rel.all")
  rel=$(grep '^A ' "$WORK/rel.all" | awk '$5==1' | wc -l | tr -d ' ')
  no=$(grep '^A ' "$WORK/rel.all" | awk '$5==0' | wc -l | tr -d ' ')
  cna=$(grep '^A ' "$WORK/rel.all" | awk '$5==2' | wc -l | tr -d ' ')
  echo "$n $rel $no $cna $(cksum < "$WORK/rel.all" | cut -d' ' -f1)"
}

# ★★★ THE WHOLE-CORPUS KINDGATE, beside the pin for the reason the relgate has one:
# a fixture is written around the arm its author is thinking of, and the shape that
# distinguishes an arm is usually not that shape.
#
# ★★ IT IS FOUR NUMBERS AND A CHECKSUM, so four breakages are told apart without a
# diff: a call site that stops being wired moves the ROW count; an arm that answers
# differently moves TRUE against FALSE; a comparison that starts stopping moves
# COULD-NOT-ANSWER; and a wrong arm number or a wrong flag word moves only the
# CHECKSUM. ★★★The pair list is NUL-delimited and the concatenation goes through
# `find | xargs cat` for §3.5eu finding nine's two reasons: one stage-2 unit's path
# contains a SPACE, which shifts an `xargs -n 2` pairing and redirects the dumper's
# stdout into a CORPUS FILE, and `cat "$WORK"/kout/*` is *Argument list too long* at
# 17 552 files — a gate that cannot RUN and a gate that cannot FAIL print the same
# word.
kindgate() {
  local n t f cna
  n=$(grep -c '^K ' "$WORK/kind.all")
  t=$(grep '^K ' "$WORK/kind.all" | awk '$6==1' | wc -l | tr -d ' ')
  f=$(grep '^K ' "$WORK/kind.all" | awk '$6==0' | wc -l | tr -d ' ')
  cna=$(grep '^K ' "$WORK/kind.all" | awk '$6==2' | wc -l | tr -d ' ')
  echo "$n $t $f $cna $(cksum < "$WORK/kind.all" | cut -d' ' -f1)"
}

# ★★★ THE WHOLE-CORPUS FORKGATE, beside the pin for the relgate's reason: a
# fixture is written around the arm its author is thinking of, and the shape that
# distinguishes an arm is usually not that shape.
#
# ★★ IT IS FOUR NUMBERS AND A CHECKSUM plus TWO HISTOGRAMS, and the histograms are
# what no other gate in this family has. Four breakages are told apart without a
# diff: a site that stops being wired moves the ROW count; an arm that answers
# differently moves TRUE against FALSE; a guard that turns an answer into a stop
# moves COULD-NOT-ANSWER; and a wrong flag word moves only the CHECKSUM. ★★★The
# ROUTE histogram is the one that prices the successor — route 3 is what is left
# for the recursion — and the BRANCH histogram is the one that separates a broken
# arm from an arm with no input, which is the KINDPIN's argument arriving in a
# second chapter.
#
# ★ NUL-delimited and concatenated through `find | xargs cat`, for §3.5eu finding
# nine's two reasons: one stage-2 unit's path contains a SPACE, which shifts an
# `xargs -n 2` pairing and redirects the dumper's stdout into a CORPUS FILE, and
# `cat "$WORK"/fout/*` is *Argument list too long* at 17 552 files.
forkgate() {
  local n t f cna routes branches
  n=$(grep -c '^F ' "$WORK/fork.all")
  t=$(grep '^F ' "$WORK/fork.all" | awk '$6==1' | wc -l | tr -d ' ')
  f=$(grep '^F ' "$WORK/fork.all" | awk '$6==0' | wc -l | tr -d ' ')
  cna=$(grep '^F ' "$WORK/fork.all" | awk '$6==2' | wc -l | tr -d ' ')
  routes=$(grep '^F ' "$WORK/fork.all" | awk '{print $4}' | sort | uniq -c | awk '{printf "%s:%s ", $2, $1}')
  branches=$(grep '^F ' "$WORK/fork.all" | awk '$4==2{print $5}' | sort -n | uniq -c | awk '{printf "%s:%s ", $2, $1}')
  echo "$n $t $f $cna $(cksum < "$WORK/fork.all" | cut -d' ' -f1) | routes ${routes}| branches ${branches}"
}

# ★★★ THE WHOLE-CORPUS CALLGATE, beside the pin for the relgate's reason: a fixture
# is written around the arm its author is thinking of, and the shape that
# distinguishes an arm is usually not that shape.
#
# ★★ IT IS FIVE NUMBERS AND A CHECKSUM, so four breakages are told apart without a
# diff: a call site that stops being wired moves the ROW count; an arm that answers
# differently moves RESOLVED against COULD-NOT-ANSWER; a singleton returned where a
# candidate belongs moves UNTYPED or ERROR; and a wrong arity column moves only the
# CHECKSUM. ★NUL-delimited and concatenated through `find | xargs cat`, for §3.5eu
# finding nine's two reasons.
callgate() {
  local n res cna unt err
  n=$(grep -c '^L ' "$WORK/call.all")
  cna=$(grep '^L ' "$WORK/call.all" | awk '$4==0' | wc -l | tr -d ' ')
  res=$(grep '^L ' "$WORK/call.all" | awk '$4==1' | wc -l | tr -d ' ')
  unt=$(grep '^L ' "$WORK/call.all" | awk '$4==2' | wc -l | tr -d ' ')
  err=$(grep '^L ' "$WORK/call.all" | awk '$4==3' | wc -l | tr -d ' ')
  echo "$n $res $unt $err $cna $(cksum < "$WORK/call.all" | cut -d' ' -f1)"
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

DIAG_BASE=""; DIAG_LINES=""; DIAG_DIAGS=""; STOP_BASE=""; REL_BASE=""; KIND_BASE=""; FORK_BASE=""; CALL_BASE=""; TYPE_BASE=""

baseline() {
  echo "################################################################"
  bold "BASELINE — fifteen instruments"
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
  relpin_of > "$WORK/base.rel"
  kindpin_of > "$WORK/base.kind"
  forkpin_of > "$WORK/base.fork"
  fnpin_of > "$WORK/base.fn"
  objpin_of > "$WORK/base.obj"
  mempin_of > "$WORK/base.mem"
  callpin_of > "$WORK/base.call"
  typepin_of > "$WORK/base.type"
  python3 "$PKG/tests/harness.py" units > "$WORK/units.txt"
  gates_pass
  STOP_BASE=$(stopgate)
  REL_BASE=$(relgate)
  KIND_BASE=$(kindgate)
  FORK_BASE=$(forkgate)
  CALL_BASE=$(callgate)
  TYPE_BASE=$(typegate)
  echo
  echo "  the STOPPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.stops"
  echo
  echo "  the TAGPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.tags"
  echo
  echo "  the RELPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.rel"
  echo
  echo "  the KINDPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.kind"
  echo
  echo "  the FORKPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.fork"
  echo
  echo "  the CALLPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.call"
  echo
  echo "  the TYPEPIN on the unpatched tree:"
  cut -c1-200 "$WORK/base.type" | sed 's/^/    /'
  echo
  echo "  BASELINE   diagcheck $DIAG_BASE consistent, $DIAG_LINES speaking, $DIAG_DIAGS diagnostics"
  echo "             stopgate  (matched units speaking events other) = $STOP_BASE"
  echo "             relgate   (rows related notrelated couldnotanswer checksum) over $(wc -l < "$WORK/units.txt" | tr -d ' ') units = $REL_BASE"
  echo "             kindgate  (rows true false couldnotanswer checksum) over the same units = $KIND_BASE"
  echo "             forkgate  (rows true false couldnotanswer checksum | routes | branches) = $FORK_BASE"
  echo "             callgate  (rows resolved untyped errorcall couldnotanswer checksum) = $CALL_BASE"
  echo "             typegate  (units answering, units reporting, T lines, checksum) = $TYPE_BASE"
}


control() {   # $1 = label, $2 = files, $3 = patch
  if [ -n "$ONLY" ]; then
    case " $ONLY " in
      *" ${1%% *} "*) ;;
      *) return 0 ;;
    esac
  fi
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
  relpin_of > "$WORK/ctl.rel"
  kindpin_of > "$WORK/ctl.kind"
  forkpin_of > "$WORK/ctl.fork"
  fnpin_of > "$WORK/ctl.fn"
  objpin_of > "$WORK/ctl.obj"
  mempin_of > "$WORK/ctl.mem"
  callpin_of > "$WORK/ctl.call"
  typepin_of > "$WORK/ctl.type"
  gates_pass
  stop=$(stopgate)
  local rel_g kind_g fork_g call_g type_g
  rel_g=$(relgate)
  kind_g=$(kindgate)
  fork_g=$(forkgate)
  call_g=$(callgate)
  type_g=$(typegate)
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
    echo "  diagpin   unmoved — all $NPIN pin files answer the same C section."
  else
    green "diagpin   RED"
    diff "$WORK/base.diags" "$WORK/ctl.diags" | cut -c1-240 | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.tags" "$WORK/ctl.tags"; then
    echo "  tagpin    unmoved — all $NPIN pin files answer the same tag."
  else
    green "tagpin    RED"
    diff "$WORK/base.tags" "$WORK/ctl.tags" | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.stops" "$WORK/ctl.stops"; then
    echo "  stoppin   unmoved — all $NPIN pin files log the same stops, in order."
  else
    green "stoppin   RED"
    diff "$WORK/base.stops" "$WORK/ctl.stops" | cut -c1-240 | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.rel" "$WORK/ctl.rel"; then
    echo "  relpin    unmoved — all $NPIN pin files make the same comparisons, in order."
  else
    green "relpin    RED"
    diff "$WORK/base.rel" "$WORK/ctl.rel" | cut -c1-240 | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.kind" "$WORK/ctl.kind"; then
    echo "  kindpin   unmoved — all $NPIN pin files ask the same kinds and take the same arms."
  else
    green "kindpin   RED"
    diff "$WORK/base.kind" "$WORK/ctl.kind" | cut -c1-240 | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.fn" "$WORK/ctl.fn"; then
    echo "  fnpin     unmoved — all $NPIN pin files decide the same way, in the same order."
  else
    green "fnpin     RED"
    diff "$WORK/base.fn" "$WORK/ctl.fn" | cut -c1-240 | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.obj" "$WORK/ctl.obj"; then
    echo "  objpin    unmoved — all $NPIN pin files build the same object-literal types."
  else
    green "objpin    RED"
    diff "$WORK/base.obj" "$WORK/ctl.obj" | cut -c1-240 | sed 's/^/    /'
    moved=1
  fi
  if [ "$stop" = "$STOP_BASE" ]; then
    echo "  stopgate  unmoved — $stop"
  else
    green "stopgate  MOVED   $STOP_BASE -> $stop   (matched units speaking events other)"
    moved=1
  fi
  if cmp -s "$WORK/base.mem" "$WORK/ctl.mem"; then
    echo "  mempin    unmoved — all $NPIN pin files resolve the same members."
  else
    green "mempin    RED"
    diff "$WORK/base.mem" "$WORK/ctl.mem" | cut -c1-240 | sed 's/^/    /'
    moved=1
  fi
  if [ "$rel_g" = "$REL_BASE" ]; then
    echo "  relgate   unmoved — $rel_g"
  else
    green "relgate   MOVED   $REL_BASE -> $rel_g   (rows related notrelated couldnotanswer checksum)"
    moved=1
  fi
  if [ "$kind_g" = "$KIND_BASE" ]; then
    echo "  kindgate  unmoved — $kind_g"
  else
    green "kindgate  MOVED   $KIND_BASE -> $kind_g   (rows true false couldnotanswer checksum)"
    moved=1
  fi
  if cmp -s "$WORK/base.fork" "$WORK/ctl.fork"; then
    echo "  forkpin   unmoved — all $NPIN pin files take the same routes and answer the same."
  else
    green "forkpin   RED"
    diff "$WORK/base.fork" "$WORK/ctl.fork" | cut -c1-240 | sed 's/^/    /'
    moved=1
  fi
  if [ "$fork_g" = "$FORK_BASE" ]; then
    echo "  forkgate  unmoved — $fork_g"
  else
    green "forkgate  MOVED"
    echo "    was $FORK_BASE"
    echo "    now $fork_g"
    moved=1
  fi
  if cmp -s "$WORK/base.call" "$WORK/ctl.call"; then
    echo "  callpin   unmoved — all $NPIN pin files resolve the same calls, in order."
  else
    green "callpin   RED"
    diff "$WORK/base.call" "$WORK/ctl.call" | cut -c1-240 | sed 's/^/    /'
    moved=1
  fi
  if [ "$call_g" = "$CALL_BASE" ]; then
    echo "  callgate  unmoved — $call_g"
  else
    green "callgate  MOVED   $CALL_BASE -> $call_g   (rows resolved untyped errorcall couldnotanswer checksum)"
    moved=1
  fi
  if cmp -s "$WORK/base.type" "$WORK/ctl.type"; then
    echo "  typepin   unmoved — all $NPIN pin files answer the same DUMP."
  else
    green "typepin   RED"
    diff "$WORK/base.type" "$WORK/ctl.type" | cut -c1-240 | sed 's/^/    /'
    moved=1
  fi
  if [ "$type_g" = "$TYPE_BASE" ]; then
    echo "  typegate  unmoved — $type_g"
  else
    green "typegate  MOVED   $TYPE_BASE -> $type_g   (units answering, units reporting, T lines, checksum)"
    moved=1
  fi
  if [ "$moved" = 0 ]; then
    if [ "$speaking" != "$DIAG_LINES" ] || [ "$diags" != "$DIAG_DIAGS" ]; then
      echo "  ungated on all sixteen, WITH A NUMBER: $DIAG_LINES/$DIAG_DIAGS -> $speaking/$diags."
    else
      red "UNGATED ON ALL SIXTEEN AND NOTHING MOVED AT ALL."
      echo "  Decide which of §3.5v's four kinds this is. A row that predicted"
      echo "  this is a measurement; a row that did not is a hole in the battery."
    fi
  fi
  return 0
}




# ★ The row filter, the work directory and the patch directory, which every battery set
# up by hand. `battery_init "$@"` replaces all three.
battery_init() {
  ONLY="$*"
  NPIN=$(printf '%s\n' $PINFILES | grep -c .)
  WORK=$(mktemp -d -t tscaly-battery)
  PATCHDIR=$WORK/patches
  mkdir -p "$PATCHDIR"
  if [ ! -f "$PKG/tests/out/run.db" ]; then
    red "no run store at $PKG/tests/out/run.db — run tests/run.sh first."
    exit 2
  fi
}
