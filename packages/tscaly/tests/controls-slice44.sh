#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice44.sh - the slice-44 control battery, sixteen of them.
#
# Slice 44 is jsnum: a numeric literal's VALUE, which is the ECMAScript ToString
# of the parsed double and not any span of the source. It is the first slice
# whose subject is not a binder arm, and the shape of the battery follows from
# that: what the four yardsticks can see of it is exactly one thing, a numeric
# literal used as a DECLARATION NAME, so every row below is a binder row
# measuring a claim that lives three files away.
#
# FOUR GROUPS, and they are the four stages the value passes through.
#
#   c1        what the slice UNLOCKS: the normalization at all.
#
#   c2..c6    the RAW VALUE the scanner hands over, which is the reference's
#             tokenValue before jsnum sees it - the span the exponent decided
#             (c2), the radix marker (c3), the radix separators (c4), and the two
#             arms that compute or normalize a value of their own on an ERROR
#             path (c5, c6).
#
#   c7..c11   FromString - the radix prefixes (c7), the two routines that could
#             remove a decimal separator and the one that does (c8, c9), the
#             leading zeros that move the decimal point (c10), and the
#             round-to-even tie (c11).
#
#   c12..c16  String - the shortest round trip (c12), the two boundaries that
#             choose the exponential form (c13, c14), the textual fix-up on the
#             exponent (c15), and the safe-integer fast path (c16).
#
# ★★★ c8 AND c9 ARE THE SAME QUESTION ASKED OF TWO ROUTINES, AND ONLY ONE OF THEM
# ANSWERS. A decimal literal's separator LOOKS as though it is removed twice -
# once by the scanner while it builds the raw value, which is where the reference
# removes it, and again by `decimal.set`'s own `_` arm, which the reference also
# has. It is not: `FromString` walks the runes before it parses anything and
# `isNumberRune` does not admit `_`, so a value still carrying one answers NaN
# long before any decimal is built. c8 (the scanner's removal) is RED 1 and c9
# (decimal.set's arm) is UNGATED - on this battery AND on numcheck.sh, which feeds
# jsnum raw strings and is the only other instrument that could reach it. The arm
# is dead code on both sides, ported because decimal.set is ported arm for arm and
# because in Go it IS live: its other caller is ParseFloat.
#
# ★★★ c16 IS THE ROW THAT WAS PREDICTED RED AND CAME BACK UNGATED, AND THE REASON
# IS WORTH MORE THAN THE ROW. Removing the safe-integer fast path leaves every
# integer printing correctly through the float formatter and negative ZERO
# printing as "-0", which ECMAScript says is "0" - so the fast path is a DECISION
# rather than an optimisation, and it ought to gate the `[-0]` fixture member.
# It does not, because a numeric literal is never negative: the minus is a
# separate node and getDeclarationName prepends its TEXT, so the double that
# reaches ToString from a declaration name is never signed. ToString's negative
# zero is UNREACHABLE from all four yardsticks, and numcheck.sh gates it instead -
# RED 2 of 20 000, on the inputs `-0` and `-0.0`.
#
# ★★ c2 IS THE ROW THE FIXTURE WAS WRITTEN FOR. `1e` with no digits after the `e`
# is the one shape where the reference's `end` and its `s.pos` differ, and taking
# the value from the token's whole span reads `1e`, which is not a number at all.
# Nothing in 13 218 cases contains it.
#
# ★★ THREE ROWS ARE DELIBERATELY NARROW BECAUSE THE OBVIOUS PATCH OVERFLOWS THE
# OUTPUT BUFFER. `jsnum_to_string` writes into 64 bytes and the bound is proved -
# after roundShortest a double has at most 17 significant digits, and the format
# rule keeps the point within 21 places of them. Disabling roundShortest outright,
# or moving a boundary so that a DENORMAL prints in fixed notation, writes the
# exact expansion instead: 751 digits for the smallest denormal, 309 for the
# largest finite double. So c12 rounds to a fixed seventeen digits rather than to
# none, and c13/c14 move each boundary by one decade rather than to infinity. Each
# still moves exactly the members it is about, and none of them measures the
# port's tolerance for a string it cannot produce (ctl.sh's header, on controls
# built out of crashes).
#
# ★ c3 and c7 both make a radix literal unreadable and they are not the same
# claim: c3 says the MARKER is part of the value the scanner builds (drop it and
# `0x10` is the decimal 10, a well-formed wrong answer), c7 says FromString reads
# the marker at all (drop that and `0x10` is NaN).
#
# Usage (it patches the source tree and restores it after every control, so
# nothing may edit the tree while it runs - §3.5y):
#
#   packages/tscaly/tests/controls-slice44.sh 2>&1 | tee /tmp/battery44.log
#
# 1 baseline + 16 controls = 17 runs, about 25 minutes on an idle box. ★If it
# takes hours, read §3.5ck before suspecting the battery.

set -u
cd "$(dirname "$0")/../../.."

CTL=packages/tscaly/tests/ctl.sh
J=packages/tscaly/0.1.1/tscaly/jsnum.scaly
S=packages/tscaly/0.1.1/tscaly/scanner.scaly

export TSCALY_BASELINE=$(mktemp -t tscaly-baseline)
cleanup() { rm -f "$TSCALY_BASELINE" "$TSCALY_BASELINE.fp"; }
trap cleanup EXIT

echo "################################################################"
if ! "$CTL" --establish-baseline </dev/null; then
  exit 2
fi

run() { echo; echo "################################################################"; "$CTL" "$1"; }

# -- group 1: what the slice unlocks -----------------------------------------

run "c1 a numeric literal's value is NORMALIZED at all" <<SPEC
FILE $S
<<<OLD
    procedure normalize_numeric_token_value(this)
    {
        var out char[JSNUM_MAX_TEXT]
>>>NEW
    procedure normalize_numeric_token_value(this)
    {
        if true
            return
        var out char[JSNUM_MAX_TEXT]
SPEC

# -- group 2: the raw value ---------------------------------------------------

run "c2 the value spans what the EXPONENT accepted, not the whole token" <<SPEC
FILE $S
<<<OLD
        this.set_numeric_raw_value(start, end_pos)
>>>NEW
        this.set_numeric_raw_value(start, state.pos)
SPEC

run "c3 a radix value carries its MARKER, so it is not read as decimal" <<SPEC
FILE $S
<<<OLD
        this.value_put_byte(("0" as char) as int)
        this.value_put_byte(marker)
>>>NEW
SPEC

run "c4 a RADIX literal's separators are dropped while the value is built" <<SPEC
FILE $S
<<<OLD
            var i dstart
            while i < dstop
            {
                if (*(buffer + i) as int) <> (("_" as char) as int)
                    this.value_put_byte(*(buffer + i) as int)
                set i: i + 1
            }
>>>NEW
            var i dstart
            while i < dstop
            {
                this.value_put_byte(*(buffer + i) as int)
                set i: i + 1
            }
SPEC

run "c5 the legacy OCTAL arm computes a value of its own" <<SPEC
FILE $S
<<<OLD
                        this.set_octal_token_value(dstart, state.pos)
>>>NEW
                        this.set_token_value_range(dstart, state.pos)
SPEC

run "c6 the LEADING-ZERO arm is normalized like every other" <<SPEC
FILE $S
<<<OLD
            this.error_at(DiagDecimals_with_leading_zeros_are_not_allowed, start, state.pos - start)
            this.normalize_numeric_token_value()
>>>NEW
            this.error_at(DiagDecimals_with_leading_zeros_are_not_allowed, start, state.pos - start)
SPEC

# -- group 3: FromString ------------------------------------------------------

run "c7 FromString reads the three RADIX prefixes" <<SPEC
FILE $J
<<<OLD
    let c1 (*(s + (off + 1)) as int) | 0x20
    var base 0
>>>NEW
    let c1 (*(s + (off + 1)) as int) | 0x20
    var base 0
    if true
        return false
SPEC

run "c8 the SCANNER removes a DECIMAL literal's separators" <<SPEC
FILE $S
<<<OLD
        if (state.token_flags & TokenFlagsContainsSeparator) = 0
        {
            this.set_token_value_range(start, stop)
            return
        }
>>>NEW
        if true
        {
            this.set_token_value_range(start, stop)
            return
        }
SPEC

run "c9 decimal.set's own separator arm removes anything (it cannot be reached)" <<SPEC
FILE $J
<<<OLD
        let c (*(s + i) as int)
        if c = (("_" as char) as int)
        {
            set i: i + 1
            continue
        }
        if c = (("." as char) as int)
>>>NEW
        let c (*(s + i) as int)
        if c = (("." as char) as int)
SPEC

run "c10 decimal.set's leading ZEROS move the decimal point" <<SPEC
FILE $J
<<<OLD
                ; ignore leading zeros
                set a.dp: a.dp - 1
                set i: i + 1
>>>NEW
                ; ignore leading zeros
                set i: i + 1
SPEC

run "c11 an exact halfway value rounds to EVEN" <<SPEC
FILE $J
<<<OLD
        if nd <= 0
            return false
        return (((*(a.d + (nd - 1)) as int) - (("0" as char) as int)) % 2) <> 0
>>>NEW
        return true
SPEC

# -- group 4: String ----------------------------------------------------------

run "c12 the digits are the SHORTEST that read back, not a fixed seventeen" <<SPEC
FILE $J
<<<OLD
    let minexp FLT_BIAS + 1
>>>NEW
    dec_round(d, 17)
    return
    let minexp FLT_BIAS + 1
SPEC

run "c13 the exponential form starts at 1e21" <<SPEC
FILE $J
<<<OLD
define BITS_1E21:       u64 0x444B1AE4D6E2EF50
>>>NEW
define BITS_1E21:       u64 0x4480F0CF064DD592
SPEC

run "c14 the exponential form resumes below 1e-6" <<SPEC
FILE $J
<<<OLD
define BITS_1E_MINUS_6: u64 0x3EB0C6F7A0B5ED8D
>>>NEW
define BITS_1E_MINUS_6: u64 0x3E45798EE2308C3A
SPEC

run "c15 a one-digit NEGATIVE exponent loses its leading zero" <<SPEC
FILE $J
<<<OLD
            if (*(out + (n - 4)) as int) = (("e" as char) as int)
>>>NEW
            if false
SPEC

run "c16 the safe-integer fast path, i.e. ToString(-0) is 0" <<SPEC
FILE $J
<<<OLD
    var mag: u64 0
    if jsnum_safe_integer(bits, &mag)
>>>NEW
    var mag: u64 0
    if false
SPEC
