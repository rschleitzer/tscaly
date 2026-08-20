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
#   ★★★ AND THE COMMONEST WAY TO BREAK THAT RULE IS TO INVERT A TEST RATHER THAN
#     DISABLE A BRANCH — `if x = false` → `if x = true` does not merely stop the
#     behaviour where it belongs, it ADDS it everywhere it does not. Write
#     `if true  return` instead. Slice 22 shipped six controls with this defect
#     and caught them only on a re-read: c22 reported RED 28 where the claim
#     gates 3, and c36 RED 12 where it gates 2.
#
#     ★★★ THE DIRECTION IS THE POINT. A control that reports too LOW looks like a
#     weak gate and gets investigated; one that reports too HIGH looks like
#     strong evidence for the very claim being defended, and reads as success.
#     Nobody audits a number that flatters them. The tell in slice 22 was
#     implausibility alone — c22 appeared to gate more units than the commonest
#     tag in the whole corpus.
#
#   ★★ AN INVERTED NULL TEST ALSO WALKS INTO THE BRANCH IT WAS GUARDING.
#     `if x = null  return` → `if x <> null  return` means the patched port
#     dereferences a null on every input that has one. Three of slice 22's
#     controls did this and did not crash — which is luck about what the corpus
#     contains, not a property of the control.
#
#   ★★★ AND ONE STEP FURTHER OUT: REMOVING A DECLARATION WALKS INTO EVERY LATER
#     LINE THAT WAS ENTITLED TO ASSUME IT. Slice 32's c1 first read
#     `if false  this.bind_object_literal_expression(n)`, which left the literal
#     a CONTAINER with no symbol — so the members arm asked Symbol.get_members of
#     a null and the DUMPER died: RED 131, of which 130 units read `our dumper
#     exited -11`. A crash is not a disagreement, and a red built out of crashes
#     measures the port's tolerance for a tree it cannot produce. When a control
#     takes away something the rest of the pass may rely on, make it REPORT
#     (`record_unported`) rather than silently omit: that is the pre-slice
#     behaviour exactly, and the row then measures what the arm unlocks.
#     ★ The tell is in the unit list, not in the number — read it.
#
#   ★ A BASELINE IS A MEASUREMENT OF ONE TREE ON ONE DAY. Slice 7 nearly wrote
#     off three working gates because their numbers were read against a stale
#     baseline — and the direction that bites is the surprising one: a stale
#     baseline can make a real gate look DEAD.
#
#     ★★★ SO THE BASELINE IS SHARED ACROSS A BATTERY, AND THE THING THAT MAKES
#     THAT SAFE IS A FINGERPRINT RATHER THAN A RE-RUN. The "after" of control N
#     is constructively the "before" of control N+1 — ctl.sh restores the one
#     file it patched and touches nothing else — so re-measuring it 45 times cost
#     45 runs to learn what a hash answers in 0.2 s. `TSCALY_BASELINE=<file>`
#     caches the baseline report and, beside it, a SHA-256 over every input a run
#     has: all of `0.1.0/**/*.scaly`, every fixture (394 today, and the hash is over whatever is there), the four oracle sources,
#     accepted.txt, the submodule's pinned commit, the compiler binary and the
#     runtime archive. Every control verifies that fingerprint before it trusts
#     the cached numbers and again after it restores.
#
#     ★★ That is STRICTLY STRONGER than the second run it replaces, which is the
#     only reason it is allowed to replace it. The old check compared four
#     COUNTERS and could not see a change that does not move one — §3.5y records
#     exactly that hole ("a comment does not move a count, so BASELINE AFTER
#     RESTORE is green whether the edit survived or was reverted"). The
#     fingerprint sees any byte of any input, in any file, including the ones
#     this control never named.
#
#   ★ A RESTORED SOURCE IS NOT A RESTORED ARTIFACT. Slice 6 read a probe wrong
#     because ctl.sh put the file back and left the BINARIES under tests/out
#     patched.
#
#     ★★★ THE CHECK STAYS AND ITS SECOND MEASUREMENT GOES. What made slice 6's
#     reading wrong was ctl.sh REPORTING a baseline measured with patched
#     binaries; no baseline is measured after the restore any more, so there is
#     nothing to misreport. And `run.sh` rebuilds the package and all three
#     programs on EVERY invocation, unconditionally — so the next run is built
#     from the restored source whether or not this script rebuilds it. What is
#     left is the hazard of somebody reading `tests/out/tscaly_*` WITHOUT a run,
#     and that gets a marker instead of a rebuild: ctl.sh drops
#     `tests/out/.built-from-patched-tree`, run.sh removes it once it has built,
#     and this script says so on its way out.
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

PKG=packages/tscaly
SUB=$PKG/_submodules/typescript-go
OUT=$PKG/tests/out
LIBSCALY=${LIBSCALY:-/tmp/libscaly.a}
SCALYC=${SCALYC:-$REPO/scalyc/build/scalyc}

# Every INPUT a run of the yardsticks has, as one hash. This is what lets a
# baseline be shared across a battery instead of re-measured 45 times, and it is
# deliberately wider than the file a control patches: the whole point of the
# check is to catch a change the control never named.
#
# ★ NUL-separated, so a path with a space is one path. And `shasum` is fed the
# names as well as the contents, so a RENAME moves the hash.
fingerprint() {
  {
    find "$PKG/0.1.0" -name '*.scaly' -print0 | sort -z
    find "$PKG/tests/fixtures" -type f -print0 | sort -z
    find "$PKG/tests/oracle" -name '*.go' -print0 | sort -z
    printf '%s\0' "$PKG/tests/accepted.txt" "$SCALYC" "$LIBSCALY"
  } | xargs -0 shasum -a 256 | shasum -a 256 | awk '{print $1}'
  git -C "$SUB" rev-parse HEAD 2>/dev/null
}

# ── `--establish-baseline`: fill the shared cache and stop ───────────────────
#
# ★ This mode exists so that the fingerprint rule has exactly ONE definition.
# The first draft had the battery script compute its own, which is the shape the
# root CLAUDE.md warns about twice — a second copy of a rule, and an instrument
# whose scope is narrower than its claim. A caller that wants a shared baseline
# asks for one here.
if [ "${1:-}" = "--establish-baseline" ]; then
  if [ -z "${TSCALY_BASELINE:-}" ]; then
    red "--establish-baseline needs TSCALY_BASELINE=<file> in the environment."; exit 2
  fi
  echo "establishing the shared baseline ..."
  "$RUN" > "$TSCALY_BASELINE" 2>&1 </dev/null
  rc=$?
  if [ $rc -ne 0 ]; then
    red "the baseline run is not green (rc $rc) — refusing to seed a battery from it,"
    red "because every number measured against it would come from a broken tree."
    tail -30 "$TSCALY_BASELINE"
    rm -f "$TSCALY_BASELINE"
    exit 2
  fi
  fingerprint > "$TSCALY_BASELINE.fp"
  grep -E '^(scanner|parser|jsdoc|binder) yardstick' -A1 "$TSCALY_BASELINE" | sed 's/^/  /'
  exit 0
fi

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

parse_counts() {   # a run.sh report -> twelve numbers, three per yardstick
  python3 - "$1" <<'PY'
import re, sys
t = open(sys.argv[1]).read()
out = []
for name in ("scanner yardstick", "parser yardstick", "jsdoc yardstick",
             "binder yardstick"):
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

# `TSCALY_BASELINE=<file>` shares one baseline across a battery. The report is
# cached at that path and its input fingerprint beside it as `<file>.fp`; a
# cached baseline is used only when the fingerprint still matches the tree, so a
# stale one REFUSES rather than answering. Unset, this control measures its own,
# exactly as before.
FP_NOW=$(fingerprint)
BASE_LOG=$WORK/base.log

if [ -n "${TSCALY_BASELINE:-}" ] && [ -f "$TSCALY_BASELINE" ] && [ -f "$TSCALY_BASELINE.fp" ]; then
  if [ "$FP_NOW" != "$(cat "$TSCALY_BASELINE.fp")" ]; then
    red "REFUSED: the cached baseline's input fingerprint does not match this tree."
    echo "  $TSCALY_BASELINE was measured against different inputs, and slice 7's"
    echo "  lesson is that a stale baseline can make a real gate look DEAD. Either"
    echo "  something edited the tree while the battery ran (§3.5y), or a previous"
    echo "  control did not restore. Delete the cache and start the battery again."
    exit 2
  fi
  BASE_LOG=$TSCALY_BASELINE
  echo "  baseline: shared, fingerprint verified ($TSCALY_BASELINE)"
else
  echo "  running the baseline ..."
  "$RUN" > "$BASE_LOG" 2>&1 </dev/null
  if [ -n "${TSCALY_BASELINE:-}" ]; then
    cp "$BASE_LOG" "$TSCALY_BASELINE"
    printf '%s\n' "$FP_NOW" > "$TSCALY_BASELINE.fp"
    BASE_LOG=$TSCALY_BASELINE
  fi
fi

read -r BM_T BU_T BF_T BM_A BU_A BF_A BM_J BU_J BF_J BM_S BU_S BF_S <<<"$(parse_counts "$BASE_LOG")"
echo "  BASELINE BEFORE   scanner $BM_T/$BU_T/$BF_T   parser $BM_A/$BU_A/$BF_A   jsdoc $BM_J/$BU_J/$BF_J   binder $BM_S/$BU_S/$BF_S"

if [ "$BF_T" != "0" ] || [ "$BF_A" != "0" ] || [ "$BF_J" != "0" ] || [ "$BF_S" != "0" ]; then
  red "the baseline is not clean — every number below would be meaningless."
  sed -n '/unexplained failures/,$p' "$BASE_LOG" | head -20
  exit 2
fi

# ── patch, run, restore ─────────────────────────────────────────────────────

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
read -r CM_T CU_T CF_T CM_A CU_A CF_A CM_J CU_J CF_J CM_S CU_S CF_S <<<"$(parse_counts "$WORK/ctl.log")"
echo "  PATCHED           scanner $CM_T/$CU_T/$CF_T   parser $CM_A/$CU_A/$CF_A   jsdoc $CM_J/$CU_J/$CF_J   binder $CM_S/$CU_S/$CF_S   (rc $CTL_RC)"

cp "$WORK/orig" "$FILE"

# A restored source is not a restored artifact: the binaries under tests/out were
# built from the PATCHED tree and nothing has replaced them yet. `run.sh` rebuilds
# unconditionally, so the next run is correct either way — the marker is for
# anything that reads those binaries WITHOUT a run.
touch "$OUT/.built-from-patched-tree"

# ── the restore is VERIFIED, twice, and neither check is a run ───────────────
#
# First the file this control named, byte for byte against the copy taken before
# the patch. Then every other input, through the fingerprint — which is what the
# four-counter comparison here used to do and could not do well (§3.5y: a comment
# does not move a counter).
if ! cmp -s "$WORK/orig" "$FILE"; then
  red "the tree did NOT come back — $FILE differs from the copy taken before the"
  red "patch. This is a bug in ctl.sh, and every number above is suspect."
  exit 2
fi

FP_AFTER=$(fingerprint)
if [ "$FP_AFTER" != "$FP_NOW" ]; then
  red "RESTORED, but some OTHER input moved while this control ran — the"
  red "fingerprint before and after disagree, so the baseline above no longer"
  red "describes this tree and any battery sharing it must be restarted."
  echo "  While a control is running, the source tree belongs to it (§3.5y)."
  exit 2
fi
echo "  RESTORE VERIFIED   $FILE byte-identical, and every other input unchanged"

# ── the verdict ──────────────────────────────────────────────────────────────

echo
if [ "$CF_A" != "0" ] || [ "$CF_T" != "0" ] || [ "$CF_J" != "0" ] || [ "$CF_S" != "0" ]; then
  green "RED $CF_J (jsdoc)$([ "$CF_A" != 0 ] && echo " + $CF_A (parser)")$([ "$CF_T" != 0 ] && echo " + $CF_T (scanner)")$([ "$CF_S" != 0 ] && echo " + $CF_S (binder)")"
  echo "  the units that differ:"
  sed -n '/unexplained failures/,$p' "$WORK/ctl.log" | sed -n '2,25p'
elif [ "$CM_A" != "$BM_A" ] || [ "$CM_T" != "$BM_T" ] || [ "$CM_J" != "$BM_J" ] || [ "$CM_S" != "$BM_S" ]; then
  green "MATCHED-COUNT GATE: parser $BM_A -> $CM_A, scanner $BM_T -> $CM_T, jsdoc $BM_J -> $CM_J, binder $BM_S -> $CM_S"
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

if [ -f "$OUT/.built-from-patched-tree" ]; then
  echo
  echo "  NOTE: $OUT/tscaly_{tokens,ast,jsdoc,symbols} were built from the PATCHED tree."
  echo "  The source is restored and verified; run.sh rebuilds unconditionally, so"
  echo "  the next run is clean. Do not read those binaries directly until then."
fi
