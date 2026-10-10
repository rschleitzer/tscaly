#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice46.sh — the slice-46 control battery, six of them.
#
# Slice 46 ships an INSTRUMENT and not a construct: the CHECKER yardstick, with
# our half reporting `unported` for every unit. That is slice 26's situation
# exactly, and it has the same consequence for what a control can be — for as long
# as our half is unported, the reference half is the only half there is, so four of
# the six rows break a claim in the ORACLE or in the RUNNER rather than in the port.
# An instrument nobody can see fail is not yet an instrument.
#
# ★★★ THE TWO ROWS THAT MATTER MOST ARE c5 AND c6, because they gate a mechanism
# this slice INVENTED: the oracle's exit 3, "the reference could not answer this
# unit". A new class that cannot fail the run is exactly the defect slice 26's c4
# found in the four-yardstick sums — a column nothing can turn red is a column that
# is not measured — so the class goes through accepted.txt, and these two rows prove
# it in both directions: an UNARGUED crash must be a failure (c5) and an argued one
# must stay green only while its argument is on file (c6).
#
# ★★★ c1 FOUND A DEFECT IN THE CONTROL HARNESS ITSELF, on its first run: it
# answered UNGATED while 1 037 units were red, because ctl.sh's parse_counts read
# TWELVE numbers — four yardsticks — and there are now five. A column a control
# cannot see is a column no control measures, which is slice 26's c4 sentence one
# level down. Fixed in the same commit; the row is RED 1 037 now.
#
# ★★ c4 CAME BACK UNGATED AND ITS VERDICT IS *unreachable*, which is worth more
# than the row would have been. The claim — that the TRANSCRIBED exclusions are
# load-bearing — is about the CONTENT of the T section, and content is invisible
# for as long as our half reports unported: no comparison of a correct dump happens
# at all (slice 26 has the same deliberately-ungated row). ★And the suspicion the
# row was written under is measurably WRONG: the crash the type walk can produce
# does not come from IsPartOfTypeNode but from the type-only import clause, which
# is a DIFFERENT exclusion and is c5's. Removing IsPartOfTypeNode over all 469
# fixtures crashes nothing.
#
# Usage (c1 patches the source tree through ctl.sh; c2-c6 patch the ORACLE or the
# accepted list and rebuild, so nothing may edit the tree while this runs — §3.5y):
#
#   packages/tscaly/tests/controls-slice46.sh 2>&1 | tee /tmp/battery46.log
#
# 1 baseline + 6 controls, about 6 minutes on an idle box.

set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

CTL=packages/tscaly/tests/ctl.sh
RUN=packages/tscaly/tests/run.sh
CHECK=packages/tscaly/tests/checktypes.py
PKG=packages/tscaly
SUB=$PKG/_submodules/typescript-go
ORACLE_SRC=$PKG/tests/oracle/types.go
ORACLE_BIN=$PKG/tests/out/oracle_types
ACCEPTED=$PKG/tests/accepted.txt

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

export TSCALY_BASELINE=$(mktemp -t tscaly-baseline)
cleanup() { rm -f "$TSCALY_BASELINE" "$TSCALY_BASELINE.fp"; }
trap cleanup EXIT

echo "################################################################"
if ! "$CTL" --establish-baseline </dev/null; then
  exit 2
fi

run() { echo; echo "################################################################"; "$CTL" "$1"; }

# ── c1: the comparison PATH, and that unported is not a pass ─────────────────
#
# Our half answers `UNPORTED 0 checker 0` for every unit, so the types artifact
# never reaches compare.py's diff at all. This row replaces that report with a
# well-formed but wrong dump — one C line, which a reference dump can also have —
# and expects every unit to turn RED. Three claims at once: the fifth artifact IS
# compared, the reference dump is never that line, and the units now sitting in the
# `unported` column are units that would fail if they answered.

run "c1 our half answers a wrong dump instead of reporting unported" <<SPEC
FILE $PKG/0.1.2/tscaly_types.scaly
<<<OLD
    print "UNPORTED 0 checker 0"
>>>NEW
    print "C 0 0 2322"
SPEC

# ── c2..c4: the ORACLE's own claims, gated by checktypes.py ──────────────────
#
# ctl.sh patches `.scaly` files exclusively (its fingerprint refuses anything else
# moving), so these do their own patch/build/restore around checktypes.py — and a
# restored source is not a restored artifact, so each one rebuilds twice.

oracle_build() {   # $1 = source file to build from
  mkdir -p "$SUB/oracle/types"
  cp "$1" "$SUB/oracle/types/main.go"
  ( cd "$SUB" && go build -o "$REPO/$ORACLE_BIN" ./oracle/types ) > /tmp/ctl46-build.log 2>&1
  local rc=$?
  rm -rf "$SUB/oracle"
  if [ $rc -ne 0 ]; then
    red "the patched oracle did not build — the control measures nothing:"
    sed 's/^/    /' /tmp/ctl46-build.log
    return 1
  fi
  if [ -n "$(git -C "$SUB" status --porcelain 2>/dev/null)" ]; then
    red "the submodule is dirty after an oracle build — refusing to continue."
    return 1
  fi
  return 0
}

oracle_control() {   # $1 = label, $2 = python patch file
  echo
  echo "################################################################"
  bold "CONTROL: $1"
  cp "$ORACLE_SRC" /tmp/ctl46-orig.go
  python3 "$2" "$ORACLE_SRC" || { red "the patch did not apply"; return 1; }
  if ! oracle_build "$ORACLE_SRC"; then cp /tmp/ctl46-orig.go "$ORACLE_SRC"; oracle_build "$ORACLE_SRC"; return 1; fi
  echo "  patched oracle built; running checktypes over all fixtures ..."
  "$CHECK" --runs 2 > /tmp/ctl46-check.log 2>&1
  local rc=$?
  tail -1 /tmp/ctl46-check.log | sed 's/^/  /'
  grep -m 3 -E 'INVARIANT|NONDETERMINISTIC|exited' /tmp/ctl46-check.log | sed 's/^/  /'
  cp /tmp/ctl46-orig.go "$ORACLE_SRC"
  oracle_build "$ORACLE_SRC" || return 1
  if ! cmp -s /tmp/ctl46-orig.go "$ORACLE_SRC"; then
    red "the oracle source did NOT come back — every number here is suspect."
    return 1
  fi
  echo "  RESTORE VERIFIED   $ORACLE_SRC byte-identical, oracle rebuilt from it"
  echo
  if [ $rc -ne 0 ]; then
    green "RED — checktypes refuses the patched oracle"
  else
    red "UNGATED: checktypes still passes. Decide which of §3.5v's four kinds that is."
  fi
  return 0
}

cat > /tmp/ctl46-c2.py <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
old = '''	for _, d := range c.GetDiagnostics(context.Background(), unit) {
		fmt.Fprintf(out, "C %d %d %d\\n", d.Pos(), d.End(), d.Code())
	}'''
new = '''	diags := c.GetDiagnostics(context.Background(), unit)
	for i := len(diags) - 1; i >= 0; i-- {
		d := diags[i]
		fmt.Fprintf(out, "C %d %d %d\\n", d.Pos(), d.End(), d.Code())
	}'''
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

# The C lines are nondecreasing in pos because GetDiagnostics sorts them, and a
# port answering in DISCOVERY order would differ from the reference on every unit
# with two diagnostics — as a wrong SPAN rather than as a wrong order, which is
# why the gate asserts it.
oracle_control "c2 the diagnostics are emitted in reverse order" /tmp/ctl46-c2.py

cat > /tmp/ctl46-c3.py <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
old = '''		fmt.Fprintf(out, "T %d %d %d %s\\n", node.Kind, node.Pos(), node.End(), escape(c.TypeToString(t)))'''
new = '''		fmt.Fprintf(out, "T %d %d %d %s\\n", node.Kind, node.Pos(), node.End()+1, escape(c.TypeToString(t)))'''
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

# A span one byte past the end is the smallest wrong answer that still looks like
# a right one — §3.5bw's class — and the file's own size is the only thing that
# can refuse it.
oracle_control "c3 a T span reaches one byte past the end of the file" /tmp/ctl46-c3.py

cat > /tmp/ctl46-c4.py <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
old = '''	if ast.IsPartOfTypeNode(node) {
		return true
	}'''
new = '''	if false {
		return true
	}'''
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

# Predicted RED, came back UNGATED — see the header: the claim is about the T
# section's CONTENT, which nothing compares while our half is unported, and the
# crash it was suspected of belongs to c5's exclusion instead. Kept because the
# slice that makes our half answer owns the row.
oracle_control "c4 the type walk asks a TYPE NODE for its type" /tmp/ctl46-c4.py

# ── c5 and c6: the exit-3 class, in both directions ─────────────────────────

full_run() {   # $1 = label
  "$RUN" > /tmp/ctl46-run.log 2>&1 </dev/null
  local rc=$?
  sed -n '/checker yardstick/,+6p' /tmp/ctl46-run.log | sed 's/^/  /'
  grep -m 2 -E 'panicked inside the reference|NO reference answer' /tmp/ctl46-run.log | sed 's/^/  /'
  return $rc
}

cat > /tmp/ctl46-c5.py <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
old = '''		if isNamelessTypeOnlyImportClause(node) {
			continue
		}'''
new = '''		if false {
			continue
		}'''
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

echo
echo "################################################################"
bold "CONTROL: c5 an UNARGUED reference crash (the one exclusion of ours, removed)"
cp "$ORACLE_SRC" /tmp/ctl46-orig.go
python3 /tmp/ctl46-c5.py "$ORACLE_SRC"
if oracle_build "$ORACLE_SRC"; then
  if full_run; then red "UNGATED: the run still passed — an unargued crash is not gated."; else green "RED — the run fails on a crash no accepted.txt entry argues"; fi
fi
cp /tmp/ctl46-orig.go "$ORACLE_SRC"
oracle_build "$ORACLE_SRC" || exit 2
cmp -s /tmp/ctl46-orig.go "$ORACLE_SRC" && echo "  RESTORE VERIFIED   oracle back and rebuilt"

echo
echo "################################################################"
bold "CONTROL: c6 the accepted.txt entry that argues the known crash, removed"
cp "$ACCEPTED" /tmp/ctl46-accepted.txt
grep -v '^fixtures_parser_jsdoc_reparse_full_signature_guard' /tmp/ctl46-accepted.txt > "$ACCEPTED"
if full_run; then red "UNGATED: the run still passed without the argument."; else green "RED — the run fails when the argument is taken away"; fi
cp /tmp/ctl46-accepted.txt "$ACCEPTED"
cmp -s /tmp/ctl46-accepted.txt "$ACCEPTED" && echo "  RESTORE VERIFIED   accepted.txt back"

echo
echo "################################################################"
echo "the battery is done; the tree and the oracle are restored."
