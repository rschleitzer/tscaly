#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice25.sh — the slice-25 control battery, seven of them.
#
# Slice 25 is the smallest slice in this port and it closes the largest claim: the
# LAST reachable `unported` of the scanner. `scan_number`'s trailing-name check
# read the byte after a numeric literal and reported anything >= 128 as a
# construct nobody had built — under a file banner and a field comment that both
# said nothing reachable from Scan() was unported any more. Corpus stage 2 reached
# it twice.
#
# ★★★ FIVE OF THE SEVEN ARE RED, ONE FALLS TO UNPORTED, AND ONE IS
# INDISTINGUISHABLE BY CONSTRUCTION. The indistinguishable one is the useful row,
# because the code carries the same argument at the place a reader would otherwise
# "fix" it (§3.5v) — and c6/c7 are here for the opposite reason: they measure a
# READING rather than this slice's code, since two parser comments called the
# reference's invalid-escape re-scan unreachable on a mechanism slice 13c retired.
# A note claiming unreachability is a control waiting to be written.
#
# ★ THE NUMBERS ARE A MEASUREMENT OF ONE TREE ON ONE DAY. Re-run after any change
# to scan_number or to the identifier predicates and expect them to MOVE; what
# must not change without an argument is a row's VERDICT.
#
# Usage (it patches the source tree and restores it after every control, so
# nothing may edit the tree while it runs — §3.5y):
#
#   packages/tscaly/tests/controls-slice25.sh 2>&1 | tee /tmp/battery25.log
#
# 1 baseline + 7 controls + 1 verifying run = 9 runs. See controls-slice22.sh's
# header for why the shared baseline is safe.

set -u
cd "$(dirname "$0")/../../.."

CTL=packages/tscaly/tests/ctl.sh
RUN=packages/tscaly/tests/run.sh
S=packages/tscaly/0.1.0/tscaly/scanner.scaly

export TSCALY_BASELINE=$(mktemp -t tscaly-baseline)
BATTERY_START=$(python3 -c 'import time; print(time.time())')
cleanup() { rm -f "$TSCALY_BASELINE" "$TSCALY_BASELINE.fp"; }
trap cleanup EXIT

echo "################################################################"
if ! "$CTL" --establish-baseline </dev/null; then
  exit 2
fi

run() { echo; echo "################################################################"; "$CTL" "$1"; }

# ── the character the check is asked about ───────────────────────────────────
#
# c1 restores the state of the tree through slice 24 exactly, unported report
# included, so its delta is the size of what this slice closed — and it falls to
# UNPORTED rather than to RED, which is the whole reason the defect survived
# twenty-four slices: unported is not a pass, but it is not a wrong answer
# either, and a reader looking for wrong answers never sees it.
#
# c2 removes the report and keeps the ASCII test, which is what the same defect
# looks like once somebody "cleans up" the bail-out. THAT one is red — the same
# omission, now answering.

run "c1 the trailing character is read as a BYTE, and non-ASCII reports unported" <<SPEC
FILE $S
<<<OLD
        let after this.utf8_decode_at(state.pos)
        if is_identifier_start(after)
>>>NEW
        let after this.char()
        if after >= 128
            return this.unported()
        if is_identifier_start(after)
SPEC

run "c2 the trailing character is tested with the ASCII predicate only" <<SPEC
FILE $S
<<<OLD
        let after this.utf8_decode_at(state.pos)
        if is_identifier_start(after)
>>>NEW
        let after this.utf8_decode_at(state.pos)
        if is_ident_start_ascii(after)
SPEC

# ── the run the check then walks ─────────────────────────────────────────────
#
# Two claims, and they are separable because the escape arm carries two
# observables of its own: scan_unicode_escape sets UnicodeEscape or
# ExtendedUnicodeEscape ON THE NUMERIC TOKEN, and pos decides the SPAN of the
# diagnostic the caller reports. c3 removes the arm, c4 keeps it and counts the
# source bytes instead of the decoded rune.

run "c3 the identifier run stops at a unicode escape" <<SPEC
FILE $S
<<<OLD
            if c = ("\\\\" as char) as int
            {
                let esc this.peek_unicode_escape()
                if esc >= 0
                {
                    if is_identifier_part(esc)
                    {
                        let cp this.scan_unicode_escape(true)
                        set len: len + utf8_encoded_size(cp)
                        continue
                    }
                }
            }
            break
>>>NEW
            break
SPEC

run "c4 an escape contributes its SOURCE length instead of its decoded length" <<SPEC
FILE $S
<<<OLD
                        let cp this.scan_unicode_escape(true)
                        set len: len + utf8_encoded_size(cp)
>>>NEW
                        let esc_start state.pos
                        let cp this.scan_unicode_escape(true)
                        set len: len + (state.pos - esc_start)
SPEC

# ── and the arm the length feeds ─────────────────────────────────────────────
#
# The `n` suffix arms are slice 3's, not this slice's, but the length is this
# slice's input to them, so one row asks whether the input is still read.

run "c5 the bigint suffix arms do not test the run's LENGTH" <<SPEC
FILE $S
<<<OLD
            if (result <> KindBigIntLiteral) and (id_len = 1)
>>>NEW
            if result <> KindBigIntLiteral
SPEC

# ── the two comments the sweep dated ─────────────────────────────────────────
#
# ★★★ NOT a claim of this slice's code but of its READING: two parser comments
# called the reference's invalid-escape re-scan UNREACHABLE, on a mechanism slice
# 13c retired. c6 is what turns that reading into a measurement — if the note were
# right, disabling the call would move nothing.

run "c6 the invalid-escape re-scan of a no-substitution template never runs" <<SPEC
FILE packages/tscaly/0.1.0/tscaly/parser.scaly
<<<OLD
            if (scanner.token_flags() & TokenFlagsIsInvalid) <> 0
            {
                this.re_scan_template_token(false)
                if this.is_unported()
                    return null
            }
            return this.parse_literal_expression(KindNoSubstitutionTemplateLiteral)
>>>NEW
            return this.parse_literal_expression(KindNoSubstitutionTemplateLiteral)
SPEC

run "c7 the invalid-escape re-scan of a template HEAD never runs" <<SPEC
FILE packages/tscaly/0.1.0/tscaly/parser.scaly
<<<OLD
        if is_tagged_template = false
        {
            if (scanner.token_flags() & TokenFlagsIsInvalid) <> 0
            {
                this.re_scan_template_token(false)
                if this.is_unported()
                    return null
            }
        }
        let pos this.node_pos()
>>>NEW
        let pos this.node_pos()
SPEC

# ── and the run that makes the seven numbers above mean anything ─────────────

echo
echo "################################################################"
echo "the 9th run: reproducing the baseline from the restored tree ..."
FINAL=$(mktemp -t tscaly-final)
"$RUN" > "$FINAL" 2>&1 </dev/null
FINAL_RC=$?
if [ $FINAL_RC -ne 0 ]; then
  printf '\033[31m%s\033[0m\n' "the final run is not green (rc $FINAL_RC) — the battery left the tree broken."
  tail -30 "$FINAL"
  rm -f "$FINAL"
  exit 2
fi
if diff -q "$TSCALY_BASELINE" "$FINAL" > /dev/null 2>&1; then
  printf '\033[32m%s\033[0m\n' "BATTERY VERIFIED: the final report is byte-identical to the baseline."
else
  printf '\033[31m%s\033[0m\n' "THE FINAL REPORT DIFFERS FROM THE BASELINE — every number above is suspect."
  diff "$TSCALY_BASELINE" "$FINAL" | head -40
  rm -f "$FINAL"
  exit 1
fi
rm -f "$FINAL"

python3 -c 'import sys,time; d=time.time()-float(sys.argv[1]); print("battery wall time: %d min %d s (%d runs of the yardsticks)" % (d//60, d%60, 9))' "$BATTERY_START"
