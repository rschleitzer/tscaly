#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# ctl.sh — run ONE negative control against the yardsticks.
#
# A control breaks a specific claim on purpose and measures what turns red. Every
# parser slice in CLAUDE.md carries a table of them, and the discipline behind
# that table is what this script mechanises, because each rule in it was paid for
# once:
#
#   ★ THE ANCHOR MUST OCCUR EXACTLY ONCE. Slice 10 aimed a control at
#     `parse_computed_property_name` while its row claimed to be about array
#     patterns — the first two lines are identical in both — and the number it
#     produced was measuring a different claim. A control that patches the wrong
#     site reports a real red for a false reason, so this refuses rather than
#     guesses, and PRINTS the file and line it patched.
#
#   ★ ONE CLAIM PER CONTROL. The first "dotDotDotToken order" control rotated
#     three slots and so moved two of them: RED 12, of which 8 belonged to a
#     different row. A control that changes two things measures neither.
#
#   ★ A BASELINE IS A MEASUREMENT OF ONE TREE ON ONE DAY. Slice 7 nearly wrote
#     off three working gates because their numbers were read against a stale
#     baseline — and the direction that bites is the surprising one: a stale
#     baseline can make a real gate look DEAD. So this prints the baseline BEFORE
#     and again AFTER the restore, and a mismatch between those two is a bug in
#     this script, not a result.
#
#   ★ A RESTORED SOURCE IS NOT A RESTORED ARTIFACT. Slice 6 read a probe wrong
#     because ctl.sh put the file back and left the BINARIES under tests/out
#     patched. The rebuild at the end is not optional; same family as the root
#     CLAUDE.md's stale-stage2 trap.
#
#   ★ CLOSE STDIN FOR THE RUN. Slice 7 lost five minutes to what looked like an
#     infinite loop in the port: this script reads its spec from stdin, the run
#     inherited it, and waited. `</dev/null` on the run.
#
#   ★ WHILE THIS IS RUNNING, THE SOURCE TREE BELONGS TO IT (§3.5y). An edit made
#     between the patch and the restore is reverted; one made between controls is
#     folded into the next control's baseline. Both look exactly like having made
#     no edit.
#
# Usage:
#
#   packages/tscaly/tests/ctl.sh "the claim in one line" <<'SPEC'
#   FILE packages/tscaly/0.1.0/tscaly/scanner.scaly
#   <<<OLD
#   ...text exactly as it appears, one occurrence in that file...
#   >>>NEW
#   ...what to replace it with...
#   SPEC
#
# Reports, per yardstick: the baseline, the patched result, and the DELTA. Read
# the delta the way CLAUDE.md's tables do:
#
#   RED n            n units now differ — the strongest gate
#   matched -n       n units fell to unported instead: real (unported is not a
#                    pass) but weaker, and it is what most controls produce while
#                    this port bails where the reference RECOVERS
#   UNGATED          nothing moved. That is one of FOUR verdicts, not one — see
#                    §3.5v (uncovered / unreachable / indistinguishable /
#                    unmodelled) — and they need different answers.

set -u

cd "$(dirname "$0")/../../.."
REPO=$(pwd)
RUN=packages/tscaly/tests/run.sh
LABEL=${1:-"(unlabelled control)"}

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

# ── read the spec ────────────────────────────────────────────────────────────

SPEC=$(cat)
FILE=$(printf '%s\n' "$SPEC" | sed -n '1s/^FILE //p')
if [ -z "$FILE" ]; then
  red "the spec's first line must be: FILE <path>"; exit 2
fi
if [ ! -f "$FILE" ]; then
  red "no such file: $FILE"; exit 2
fi

OLD=$(printf '%s\n' "$SPEC" | sed -n '/^<<<OLD$/,/^>>>NEW$/p' | sed '1d;$d')
NEW=$(printf '%s\n' "$SPEC" | sed -n '/^>>>NEW$/,$p' | sed '1d')
if [ -z "$OLD" ]; then
  red "the spec has no <<<OLD block"; exit 2
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
printf '%s\n' "$OLD" > "$WORK/old"
printf '%s\n' "$NEW" > "$WORK/new"

# ── the anchor must be unique, and we say where it landed ────────────────────

OCC=$(python3 - "$FILE" "$WORK/old" <<'PY'
import sys
src = open(sys.argv[1]).read()
old = open(sys.argv[2]).read().rstrip("\n")
print(src.count(old))
PY
)
if [ "$OCC" != "1" ]; then
  red "REFUSED: the anchor occurs $OCC times in $FILE — a control must patch exactly one site."
  echo "  Slice 10's array-pattern control anchored on two lines that are also the"
  echo "  first two of parse_computed_property_name. Widen the anchor."
  exit 2
fi

LINE=$(python3 - "$FILE" "$WORK/old" <<'PY'
import sys
src = open(sys.argv[1]).read()
old = open(sys.argv[2]).read().rstrip("\n")
print(src[:src.index(old)].count("\n") + 1)
PY
)

bold "CONTROL: $LABEL"
echo "  patching $FILE:$LINE"

# ── baseline ─────────────────────────────────────────────────────────────────

parse_counts() {   # stdin = a run.sh report; sets M_TOK U_TOK F_TOK M_AST U_AST F_AST
  python3 - "$1" <<'PY'
import re, sys
t = open(sys.argv[1]).read()
out = []
for name in ("scanner yardstick", "parser yardstick"):
    i = t.find(name)
    if i < 0:
        out += ["?", "?", "?"]; continue
    seg = t[i:i+400]
    def g(k):
        m = re.search(r"^\s*" + k + r"\s+(\d+)", seg, re.M)
        return m.group(1) if m else "?"
    out += [g("matched"), g("unported"), g("UNEXPLAINED")]
print(" ".join(out))
PY
}

echo "  running the baseline ..."
"$RUN" > "$WORK/base.log" 2>&1 </dev/null
read -r BM_T BU_T BF_T BM_A BU_A BF_A <<<"$(parse_counts "$WORK/base.log")"
echo "  BASELINE BEFORE   scanner $BM_T/$BU_T/$BF_T   parser $BM_A/$BU_A/$BF_A"

if [ "$BF_T" != "0" ] || [ "$BF_A" != "0" ]; then
  red "the baseline is not clean — every number below would be meaningless."
  sed -n '/unexplained failures/,$p' "$WORK/base.log" | head -20
  exit 2
fi

# ── patch, run, restore, REBUILD ─────────────────────────────────────────────

cp "$FILE" "$WORK/orig"
python3 - "$FILE" "$WORK/old" "$WORK/new" <<'PY'
import sys
path, oldf, newf = sys.argv[1:4]
src = open(path).read()
old = open(oldf).read().rstrip("\n")
new = open(newf).read().rstrip("\n")
open(path, "w").write(src.replace(old, new, 1))
PY

echo "  running the control ..."
"$RUN" > "$WORK/ctl.log" 2>&1 </dev/null
CTL_RC=$?
read -r CM_T CU_T CF_T CM_A CU_A CF_A <<<"$(parse_counts "$WORK/ctl.log")"
echo "  PATCHED           scanner $CM_T/$CU_T/$CF_T   parser $CM_A/$CU_A/$CF_A   (rc $CTL_RC)"

cp "$WORK/orig" "$FILE"

# A restored source is not a restored artifact: the binaries under tests/out are
# still the patched ones until something rebuilds them, and the next probe would
# measure the control.
echo "  restoring and rebuilding ..."
"$RUN" > "$WORK/after.log" 2>&1 </dev/null
read -r AM_T AU_T AF_T AM_A AU_A AF_A <<<"$(parse_counts "$WORK/after.log")"
echo "  BASELINE AFTER RESTORE   scanner $AM_T/$AU_T/$AF_T   parser $AM_A/$AU_A/$AF_A"

if [ "$AM_T" != "$BM_T" ] || [ "$AM_A" != "$BM_A" ] || [ "$AU_A" != "$BU_A" ]; then
  red "the tree did NOT come back to its baseline — this is a bug in ctl.sh, and"
  red "every number above is suspect. Check $FILE against git."
  exit 2
fi

# ── the verdict ──────────────────────────────────────────────────────────────

echo
if [ "$CF_A" != "0" ] || [ "$CF_T" != "0" ]; then
  green "RED $CF_A (parser)$([ "$CF_T" != 0 ] && echo " + $CF_T (scanner)")"
  echo "  the units that differ:"
  sed -n '/unexplained failures/,$p' "$WORK/ctl.log" | sed -n '2,25p'
elif [ "$CM_A" != "$BM_A" ] || [ "$CM_T" != "$BM_T" ]; then
  green "MATCHED-COUNT GATE: parser $BM_A -> $CM_A, scanner $BM_T -> $CM_T"
  echo "  Real — unported is not a pass — but weaker than a red. This is what most"
  echo "  controls produce while the port bails where the reference recovers."
else
  red "UNGATED: nothing moved."
  echo "  That is FOUR possible verdicts, not one (§3.5v). Decide which:"
  echo "    uncovered        no case exercises the claim -> write the fixture"
  echo "    unreachable      no text CAN, while another part of the port is missing"
  echo "    indistinguishable  both answers are unported and tags are not compared"
  echo "    unmodelled       the difference is in a field this port does not store"
fi
