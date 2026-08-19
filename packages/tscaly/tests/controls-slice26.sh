#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice26.sh — the slice-26 control battery, four of them.
#
# Slice 26 ships an INSTRUMENT and not a construct: the binder yardstick, with our
# half reporting `unported` for every unit. That changes what a control can be. The
# usual battery breaks a claim in the PORT and counts what turns red; here three of
# the four break a claim in the ORACLE or in the RUNNER, because for as long as our
# half is unported the reference half is the only half there is — and an instrument
# nobody can see fail is not yet an instrument.
#
# ★★★ THE ROW THAT MATTERS MOST IS c3, and it is here because the defect it
# reproduces was REAL. The first draft of oracle/symbols.go numbered symbols in one
# pass and let the table printing discover new ones, so a symbol reachable only
# through a LOCALS table — `declareCommonJSVariable` makes two out of nothing, and a
# namespace's locals hold symbols the walk reaches through another container — got
# an index but never an `s` line. 24 of 296 fixtures referenced an index the dump
# never defined. Reading the code did not find that; checkdump.py did, and c3 is
# the proof that it still would.
#
# ★ ONE ROW IS DELIBERATELY UNGATED and says which of §3.5v's four kinds it is:
# `keep = 0` for this artifact (the reference dump is compared UNCUT) cannot be
# gated while our half is unported, because no comparison of a CORRECT dump happens
# at all. It is *unreachable*, not uncovered — no fixture can reach it — and the
# slice that makes our half answer owns it.
#
# Usage (c1 patches the source tree through ctl.sh and restores it; c2/c3 patch the
# ORACLE and rebuild it, so nothing may edit the tree while this runs — §3.5y):
#
#   packages/tscaly/tests/controls-slice26.sh 2>&1 | tee /tmp/battery26.log

set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

CTL=packages/tscaly/tests/ctl.sh
RUN=packages/tscaly/tests/run.sh
CHECK=packages/tscaly/tests/checkdump.py
PKG=packages/tscaly
SUB=$PKG/_submodules/typescript-go
ORACLE_SRC=$PKG/tests/oracle/symbols.go
ORACLE_BIN=$PKG/tests/out/oracle_symbols

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
# Our half answers `UNPORTED 0 binder 0` for every unit, so the symbols artifact
# never reaches compare.py's diff at all. This row replaces that report with a
# well-formed but wrong dump — one `f` line, which every reference dump also has —
# and expects every unit to turn RED. What it proves is threefold and each part is
# a claim this slice makes: the fourth artifact IS compared, the reference dump is
# never empty (so an empty answer cannot pass by accident), and the 865 units now
# in the `unported` column are units that would fail if they answered.

run "c1 our half answers a wrong dump instead of reporting unported" <<SPEC
FILE $PKG/0.1.0/tscaly_symbols.scaly
<<<OLD
    print "UNPORTED 0 binder 0"
>>>NEW
    print "f 0 0"
SPEC

# ── c2 and c3: the ORACLE's own two claims ───────────────────────────────────
#
# ctl.sh patches `.scaly` files exclusively (its fingerprint refuses anything else
# moving), so these two do their own patch/build/restore around checkdump.py. Each
# rebuilds the oracle from the patched source into the SAME path run.sh uses, then
# puts the source back and rebuilds again — a restored source is not a restored
# artifact (ctl.sh's own rule), and here nothing else would rebuild it.

oracle_build() {   # $1 = source file to build from
  mkdir -p "$SUB/oracle/symbols"
  cp "$1" "$SUB/oracle/symbols/main.go"
  ( cd "$SUB" && go build -o "$REPO/$ORACLE_BIN" ./oracle/symbols ) > /tmp/ctl26-build.log 2>&1
  local rc=$?
  rm -rf "$SUB/oracle"
  if [ $rc -ne 0 ]; then
    red "the patched oracle did not build — the control measures nothing:"
    sed 's/^/    /' /tmp/ctl26-build.log
    return 1
  fi
  if [ -n "$(git -C "$SUB" status --porcelain 2>/dev/null)" ]; then
    red "the submodule is dirty after an oracle build — refusing to continue."
    return 1
  fi
  return 0
}

oracle_control() {   # $1 = label, $2 = python patch expression file
  echo
  echo "################################################################"
  bold "CONTROL: $1"
  cp "$ORACLE_SRC" /tmp/ctl26-orig.go
  python3 "$2" "$ORACLE_SRC" || { red "the patch did not apply"; return 1; }
  if ! oracle_build "$ORACLE_SRC"; then cp /tmp/ctl26-orig.go "$ORACLE_SRC"; oracle_build "$ORACLE_SRC"; return 1; fi
  echo "  patched oracle built; running checkdump over all fixtures ..."
  "$CHECK" --runs 3 > /tmp/ctl26-check.log 2>&1
  local rc=$?
  tail -1 /tmp/ctl26-check.log | sed 's/^/  /'
  grep -m 3 -E 'INVARIANT|NONDETERMINISTIC' /tmp/ctl26-check.log | sed 's/^/  /'
  cp /tmp/ctl26-orig.go "$ORACLE_SRC"
  oracle_build "$ORACLE_SRC" || return 1
  if ! cmp -s /tmp/ctl26-orig.go "$ORACLE_SRC"; then
    red "the oracle source did NOT come back — every number here is suspect."
    return 1
  fi
  echo "  RESTORE VERIFIED   $ORACLE_SRC byte-identical, oracle rebuilt from it"
  echo
  if [ $rc -ne 0 ]; then
    green "RED — checkdump refuses the patched oracle"
  else
    red "UNGATED: checkdump still passes. Decide which of §3.5v's four kinds that is."
  fi
  return 0
}

cat > /tmp/ctl26-c2.py <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
old = """	names := make([]string, 0, len(t))
	for name := range t {
		names = append(names, name)
	}
	slices.Sort(names)
	return names"""
new = """	names := make([]string, 0, len(t))
	for name := range t {
		names = append(names, name)
	}
	return names"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

# The tables are the ONE normalisation this dump has, and a Go map's iteration
# order is randomised per run, so removing the sort must make the same file dump
# differently twice. If it did not, the sort would be decoration.
oracle_control "c2 the symbol tables are emitted in map order instead of by name" /tmp/ctl26-c2.py

cat > /tmp/ctl26-c3.py <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
i = s.index("\tfor _, t := range tables {\n\t\tfor _, name := range sortedNames(t.entries) {\n\t\t\tr.sym(t.entries[name])\n\t\t}\n\t}\n")
j = s.index("\n", s.index("}\n\n", i) + 2)
block = s[i:s.index("}\n\n", i) + 3]
assert "r.sym(t.entries[name])" in block, block
open(p, "w").write(s[:i] + s[i + len(block):])
PY

# The defect this reproduces was real (24 of 296 fixtures) and it is the reason
# checkdump.py exists at all.
oracle_control "c3 the locals tables' entries are not numbered before the symbols are printed" /tmp/ctl26-c3.py

# ── c4: the harness path that says "suspect the harness, not the port" ──────
#
# A yardstick whose ORACLE fails must not report a port defect. compare.py has a
# separate message for it, and until now nothing had exercised it for this
# artifact. The oracle is patched to exit 3 after binding; the run must turn every
# unit of the binder column red and name the oracle. It is the same argument c1
# makes from the other side: the column that reads 865/unported today has to be a
# column that CAN report something else.

cat > /tmp/ctl26-c4.py <<'PYEOF'
import sys
p = sys.argv[1]
s = open(p).read()
old = "\tbinder.BindSourceFile(sf)\n"
assert s.count(old) == 1
open(p, "w").write(s.replace(old, old + "\tos.Exit(3)\n"))
PYEOF

echo
echo "################################################################"
bold "CONTROL: c4 the ORACLE exits non-zero"
cp "$ORACLE_SRC" /tmp/ctl26-orig.go
python3 /tmp/ctl26-c4.py "$ORACLE_SRC"
if oracle_build "$ORACLE_SRC"; then
  "$RUN" > /tmp/ctl26-c4.log 2>&1 </dev/null
  sed -n '/binder yardstick/,+5p' /tmp/ctl26-c4.log | sed 's/^/  /'
  grep -m 2 'ORACLE exited' /tmp/ctl26-c4.log | sed 's/^/  /'
fi
cp /tmp/ctl26-orig.go "$ORACLE_SRC"
oracle_build "$ORACLE_SRC" || exit 2
if cmp -s /tmp/ctl26-orig.go "$ORACLE_SRC"; then
  echo "  RESTORE VERIFIED   $ORACLE_SRC byte-identical, oracle rebuilt from it"
else
  red "the oracle source did NOT come back"; exit 2
fi
echo
if grep -q 'ORACLE exited 3' /tmp/ctl26-c4.log; then
  green "RED — the runner names the oracle rather than the port"
else
  red "UNGATED: the run did not report an oracle failure."
fi

echo
echo "################################################################"
bold "the verifying run — the report must reproduce the baseline byte for byte"
"$RUN" > /tmp/ctl26-final.log 2>&1 </dev/null
if cmp -s "$TSCALY_BASELINE" /tmp/ctl26-final.log; then
  green "IDENTICAL to the baseline report — the tree and the oracle both came back"
else
  red "the final report DIFFERS from the baseline:"
  diff "$TSCALY_BASELINE" /tmp/ctl26-final.log | head -30
  echo "  A fingerprint proves the INPUTS came back and says nothing about whether"
  echo "  they still produce the same ANSWER (ctl.sh's own note). This is that check."
  exit 1
fi
