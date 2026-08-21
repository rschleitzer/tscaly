#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# numcheck.sh - the cross-check for jsnum (slice 44).
#
# WHY IT IS A GATE OF ITS OWN. A numeric literal's VALUE is not its source text:
# the reference's scanner ends every numeric arm with
# `jsnum.FromString(tokenValue).String()`, the ECMAScript ToString of the parsed
# double, and that text becomes a SYMBOL NAME. The four yardsticks therefore do
# compare it - in 27 of 17 797 units, all of them a literal used as a declaration
# name, and almost all of them a plain small integer. Everything else the
# conversion decides - the shortest round trip, the round-to-even tie, the
# fixed/exponential boundary at 1e-6 and 1e21, a denormal, Infinity, NaN, the
# sign of negative zero, a radix literal past int64, a leading-zero decimal, a
# numeric separator - no corpus of TypeScript sources exercises, and an
# unexercised arm is indistinguishable from a correct one. So: one generated
# corpus, two producers, a byte diff.
#
#   ours       packages/tscaly/0.1.0/tscaly_nums.scaly + tscaly/NumCheck.scaly
#   reference  packages/tscaly/tests/oracle/nums.go, over the submodule's jsnum
#
# The corpus is GENERATED here rather than committed, from a fixed seed, so the
# file both sides read is the same file and a wider corpus is one number away.
# One line is one input string, verbatim - so it carries no newline and needs no
# escaping for anything else, tabs and multi-byte whitespace included.
#
# Submodule discipline is run.sh's, for run.sh's reason: the submodule is also
# the test corpus, so it is checked clean on BOTH sides of the oracle build and
# the copy-in is removed again.
#
# Usage:  packages/tscaly/tests/numcheck.sh [count]      (default 20000)

set -u

cd "$(dirname "$0")/../../.."
REPO=$(pwd)

PKG=packages/tscaly
SUB=$PKG/_submodules/typescript-go
OUT=$PKG/tests/out/nums
COUNT=${1:-20000}

LIBSCALY=${LIBSCALY:-/tmp/libscaly.a}
SCALYC=${SCALYC:-$REPO/scalyc/build/scalyc}

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }

if [ ! -f "$SUB/go.mod" ]; then
  red "reference not present: the submodule is not initialized."
  echo "  git submodule update --init $SUB"
  exit 2
fi
if ! command -v go >/dev/null 2>&1; then
  red "oracle unavailable: no Go toolchain on PATH."
  echo "This is a missing dependency, not a test result - nothing was measured."
  exit 2
fi
if [ ! -x "$SCALYC" ]; then red "compiler not built: $SCALYC"; echo "  ./build.sh"; exit 2; fi
if [ ! -f "$LIBSCALY" ]; then red "runtime archive missing: $LIBSCALY"; exit 2; fi

submodule_dirty() { [ -n "$(git -C "$SUB" status --porcelain 2>/dev/null)" ]; }

if submodule_dirty; then
  red "the reference submodule has local changes - refusing to run."
  git -C "$SUB" status --short | sed 's/^/    /'
  exit 2
fi

mkdir -p "$OUT"

# -- the corpus ---------------------------------------------------------------
#
# Hand cases first, because a random generator does not produce the shapes a
# reader would think of - the two format boundaries, the safe-integer edge, the
# denormals, the specials, the whitespace set, the radix forms past int64. Then
# the random ones, in four families: random BIT PATTERNS printed at shortest
# round trip (which is the only way to reach an arbitrary double through a
# string), random digit strings of every length, random scientific spellings and
# random radix literals.
python3 - "$COUNT" > "$OUT/corpus" <<'PYEOF'
import random, struct, sys

count = int(sys.argv[1])
lines = []

def add(s):
    if "\n" not in s:
        lines.append(s)

# StrWhiteSpace: the LineTerminators that are not the newline this corpus splits
# on, the four WhiteSpace code points jsnum names outright, and the whole Zs
# category. Written as code points rather than as the characters themselves:
# this file is read by people, and a line whose content is one invisible code
# point is a line nobody can maintain.
WS = ["\r", "\t", "\v", "\f"] + [chr(c) for c in [
    0x2028, 0x2029, 0xFEFF,
    0x0020, 0x00A0, 0x1680, 0x2000, 0x2004, 0x200A, 0x202F, 0x205F, 0x3000]]
# and two that are NOT in it - U+0085, which the SCANNER's own single-line set
# carries while Zs does not, and a zero-width space, which is Cf.
NOT_WS = [chr(0x0085), chr(0x200B)]

for w in WS + NOT_WS:
    add(w + "1")
    add("1" + w)
    add(w + "1" + w)
    add(w)
    add(w + w + "2.5" + w + w)

for s in ["0", "1", "9", "10", "42", "007", "0.0", "1.0", "2.0", ".5", "5.",
          "0.5", "1.5", "100", "1000000", "0.000001", "0.0000001", "1e-6",
          "1e-7", "1e21", "1e20", "1e-321", "1e-323", "1e309", "1e308",
          "1.7976931348623157e308", "5e-324", "2.2250738585072014e-308",
          "9007199254740991", "9007199254740992", "9007199254740993",
          "-9007199254740991", "18446744073709551615", "18446744073709551616",
          "123456789012345678901234567890", "0.1", "0.2", "0.3", "1.1", "2.675",
          "11e-1", "0.12e1", "1e+21", "1E21", "1e", "1e+", "1e-", "e5", ".",
          "..", "-", "+", "-0", "+0", "-0.0", "", "Infinity", "+Infinity",
          "-Infinity", "infinity", "NaN", "nan", "abc", "1abc", "0x", "0X",
          "0b", "0o", "0x0", "0x1", "0xF00D", "0XF00D", "0xdeadbeef",
          "0xDEADBEEF", "0b110", "0B110", "0o23534", "0O23534",
          "0x1fffffffffffff", "0x20000000000000", "0xffffffffffffffff",
          "0x1ffffffffffffffff", "0b2", "0o8", "0xg", "0x_1", "1_000",
          "1_0.0_1", "1_0e1_0", "0777", "0888", "0.0e0", "00.5", "000",
          "0000000000000000000000001", "1000000000000000000000",
          "100000000000000000000", "-1e-7", "-1e21", "-0.000001", "-1.5",
          "-123", "1.7976931348623159e308", "4.9e-324",
          "2.4703282292062327e-324", "-0x10", "+0x10", "0x10n", "1n",
          "1234567890123456789012345678901234567890e-40",
          "0x" + "f" * 300, "0x" + "f" * 500, "1" + "0" * 400,
          "9" * 30, "9" * 400, "1." + "0" * 100, "0." + "0" * 320 + "1",
          "1e10000", "1e-10000", "1e99999999999999999999",
          "0." + "1" * 900, "1" * 900]:
    add(s)

r = random.Random(20260821)

n = 0
while len(lines) < count:
    n += 1
    fam = n % 4
    if fam == 0:
        b = r.getrandbits(64)
        f = struct.unpack("<d", struct.pack("<Q", b))[0]
        if f != f or f in (float("inf"), float("-inf")):
            continue
        add(repr(f))
    elif fam == 1:
        d = r.randrange(1, 26)
        add("".join(r.choice("0123456789") for _ in range(d)))
    elif fam == 2:
        m = "".join(r.choice("0123456789") for _ in range(r.randrange(1, 20)))
        frac = "".join(r.choice("0123456789") for _ in range(r.randrange(0, 20)))
        s = m + ("." + frac if frac else "")
        if r.randrange(2):
            s += r.choice("eE") + r.choice(["", "+", "-"]) + str(r.randrange(0, 340))
        add(s)
    else:
        base, digits = r.choice([("0x", "0123456789abcdefABCDEF"),
                                 ("0X", "0123456789abcdef"),
                                 ("0b", "01"), ("0B", "01"),
                                 ("0o", "01234567"), ("0O", "01234567")])
        add(base + "".join(r.choice(digits) for _ in range(r.randrange(1, 40))))

sys.stdout.write("\n".join(lines) + "\n")
PYEOF

cases=$(wc -l < "$OUT/corpus" | tr -d ' ')

# -- the reference ------------------------------------------------------------
SUB_GITDIR=$(git -C "$SUB" rev-parse --absolute-git-dir 2>/dev/null)
if [ -n "$SUB_GITDIR" ] && [ -d "$SUB_GITDIR/info" ]; then
  grep -qx '/oracle/' "$SUB_GITDIR/info/exclude" 2>/dev/null \
    || echo '/oracle/' >> "$SUB_GITDIR/info/exclude"
fi

mkdir -p "$SUB/oracle/nums"
cp "$PKG/tests/oracle/nums.go" "$SUB/oracle/nums/main.go"
( cd "$SUB" && go build -o "$REPO/$OUT/oracle_nums" ./oracle/nums ) \
  > "$OUT/oracle-build.log" 2>&1
orc=$?
rm -rf "$SUB/oracle"
if [ $orc -ne 0 ]; then
  red "the nums oracle failed to build:"; sed 's/^/    /' "$OUT/oracle-build.log"; exit 2
fi
if submodule_dirty; then
  red "the submodule is dirty AFTER the oracle build - a bug in this script."
  git -C "$SUB" status --short | sed 's/^/    /'
  exit 2
fi

# -- our side -----------------------------------------------------------------
"$SCALYC" -c --no-prelude -o "$OUT/tscaly.o" "$PKG/0.1.0/tscaly.scaly" \
  > "$OUT/pkg-build.log" 2>&1
if [ $? -ne 0 ]; then
  red "the tscaly package failed to compile:"; sed 's/^/    /' "$OUT/pkg-build.log"; exit 2
fi
"$SCALYC" -c -o "$OUT/tscaly_nums.o" "$PKG/0.1.0/tscaly_nums.scaly" \
  > "$OUT/prog-build.log" 2>&1
if [ $? -ne 0 ]; then
  red "tscaly_nums failed to compile:"; sed 's/^/    /' "$OUT/prog-build.log"; exit 2
fi
clang -o "$OUT/tscaly_nums" "$OUT/tscaly_nums.o" "$OUT/tscaly.o" "$LIBSCALY" -lm \
  > "$OUT/link.log" 2>&1
if [ $? -ne 0 ]; then
  red "the tscaly_nums link failed:"; sed 's/^/    /' "$OUT/link.log"; exit 2
fi

# -- the comparison -----------------------------------------------------------
#
# No pipeline around either binary: `rc=$?` after `$(prog | ...)` reads the last
# stage's status (root CLAUDE.md's harness rule).
"$OUT/oracle_nums" "$OUT/corpus" > "$OUT/ref" 2> "$OUT/ref.err"
rrc=$?
"$OUT/tscaly_nums" "$OUT/corpus" > "$OUT/ours" 2> "$OUT/ours.err"
orc=$?
if [ $rrc -ne 0 ]; then
  red "the oracle exited $rrc - suspect the harness, not the port:"
  sed 's/^/    /' "$OUT/ref.err"; exit 2
fi
if [ $orc -ne 0 ]; then
  red "tscaly_nums exited $orc:"; sed 's/^/    /' "$OUT/ours.err"; exit 1
fi

diff "$OUT/ref" "$OUT/ours" > "$OUT/diff" 2>&1
if [ $? -ne 0 ]; then
  n=$(grep -c '^<' "$OUT/diff")
  red "$n of $cases inputs differ from the reference:"
  head -20 "$OUT/diff" | sed 's/^/    /'
  echo "  full diff: $OUT/diff (the corpus line numbers are $OUT/corpus's)"
  exit 1
fi

green "OK - $cases inputs, byte-identical to the reference's own jsnum."
