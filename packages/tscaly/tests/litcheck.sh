#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# litcheck.sh - the cross-check for a LITERAL TYPE'S NAME (slice 71).
#
# WHY IT IS A GATE OF ITS OWN, and this one is sharper than numcheck's. A
# numeric literal's value at least reaches 27 units of the corpus; a literal
# TYPE's name reaches NONE. The checker yardstick writes a T line for a node the
# type walk asks about, and getTypeOfNode answers an expression through
# `IsExpressionNode -> getRegularTypeOfExpression`, neither of which is ported -
# so the kind INVENTORY admits three token and statement kinds, no expression,
# and every one of the four names slice 71 composes is invisible to every
# yardstick this repository has. An unexercised arm is indistinguishable from a
# correct one, so: one generated corpus, two producers, a byte diff.
#
#   ours       packages/tscaly/0.1.0/tscaly_lits.scaly + tscaly/LitCheck.scaly
#   reference  packages/tscaly/tests/oracle/lits.go, over the submodule's own
#              printer.EscapeString and jsnum.ParsePseudoBigInt
#
# TWO directions, tagged per line, because two of the four arms compose a name
# out of bytes and the other two do not: the STRING literal (quote, escape,
# quote) and the BIGINT literal (ParsePseudoBigInt, the leading-zero trim,
# PseudoBigInt.String, `n`). The number arm is jsnum_to_string, which
# numcheck.sh already gates from both directions; the boolean arm is two static
# keywords.
#
# ONE LINE IS `<tag> <hex bytes>`, and the hex is not decoration: the inputs
# that matter most here are exactly the ones a verbatim corpus cannot carry - a
# newline, a NUL, a lone surrogate's three-byte sentinel, a stray byte that is
# not UTF-8 at all.
#
# Submodule discipline is run.sh's, for run.sh's reason: the submodule is also
# the test corpus, so it is checked clean on BOTH sides of the oracle build and
# the copy-in is removed again.
#
# Usage:  packages/tscaly/tests/litcheck.sh [count]      (default 20000)

set -u

cd "$(dirname "$0")/../../.."
REPO=$(pwd)

PKG=packages/tscaly
SUB=$PKG/_submodules/typescript-go
OUT=$PKG/tests/out/lits
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
# Hand cases first, for numcheck's reason: a random generator does not produce
# the shapes a reader would think of. For the STRING side those are the
# canonical escapes, the sub-0x20 controls, the three line-ish code points, the
# quote and the backslash themselves, a NUL followed by a digit and one not, a
# lone surrogate written as its three-byte sentinel, a supplementary code point
# (which becomes TWO \u escapes), and a stray byte that is not UTF-8. For the
# BIGINT side those are the four bases, both cases of the hex digits, the
# leading zeros, the all-zero values, the separator base 0 tolerates, and a text
# big.Int refuses.
#
# Every non-ASCII case is written as a CODE POINT and not as the character
# itself, which is numcheck.sh's rule for its corpus generator too: this file is
# read by people, and a line whose content is one invisible code point is a line
# nobody can maintain.
python3 - "$COUNT" > "$OUT/corpus" <<'PYEOF'
import random, sys

count = int(sys.argv[1])
lines = []

def add_s(b):
    lines.append("S " + b.hex())

def add_b(t):
    lines.append("B " + t.encode("utf-8").hex())

def add_t(src):
    lines.append("T " + src.encode("utf-8").hex())

HAND = [
    "", "a", "abc", "hello world",
    chr(0x22), chr(0x5C), chr(0x22) + chr(0x5C) + chr(0x22),
    "\t", "\n", "\r", "\r\n", "\v", "\f", "\b",
    "\x00", "\x007", "\x00a", "a\x00b",
    "\x01\x02\x1e\x1f", "\x7f",
    " ", chr(0x85), chr(0xA0), chr(0x2028), chr(0x2029),
    chr(0xE9), "caf" + chr(0xE9), chr(0x4E2D) + chr(0x6587),
    chr(0x1F600), chr(0x10FFFF), "a" + chr(0x1F600) + "b",
    "$", "`", "${", "a`b", "'",
    "line1\nline2", " leading", "trailing ", "  ",
    chr(0x200B), chr(0xFEFF), chr(0xFFFD),
    "a" * 200,
]
for s in HAND:
    add_s(s.encode("utf-8"))

# The three-byte SENTINEL the scanner writes a lone surrogate out as, which Go's
# own utf8 decoder refuses and DecodeJSStringRune recognises. And a stray byte,
# which is the other half of the decoder's contract.
for cp in (0xD800, 0xDBFF, 0xDC00, 0xDFFF):
    b = bytes([0xE0 | (cp >> 12), 0x80 | ((cp >> 6) & 0x3F), 0x80 | (cp & 0x3F)])
    add_s(b)
    add_s(b + b"x")
    add_s(b"x" + b)
# an adjacent high+low pair, which is TWO lone surrogates and not one code point
add_s(bytes([0xED, 0xA0, 0x80]) + bytes([0xED, 0xB0, 0x80]))
for stray in (b"\x80", b"\xbf", b"\xc0", b"\xc2", b"\xf5", b"\xff",
              b"a\xffb", b"\xe0\x80", b"\xf0\x9f\x98"):
    add_s(stray)

for t in ["0", "0n", "1", "1n", "9", "10", "007", "0007n", "00", "000n",
          "123456789012345678901234567890",
          "0x0", "0x1", "0xf", "0xF", "0xff", "0xFF", "0xFf", "0xffn",
          "0X10", "0xdeadbeef", "0xDEADBEEF", "0x" + "f" * 64,
          "0b0", "0b1", "0b101", "0b101n", "0B1010", "0b" + "1" * 200,
          "0o0", "0o7", "0o777", "0o777n", "0O644", "0o" + "7" * 100,
          "0x1_f", "0b1_01", "1_000", "0x00ff", "0b0001", "0o0007"]:
    add_b(t)

# The SCANNER direction. A bigint in every spelling the scanner has a branch for,
# because what is measured is scanBigIntSuffix's two steps and they fork on the
# specifier; the separator forms are the ones the raw-slice stand-in got wrong,
# and the plain numeric forms are here so a change to the bigint arm that also
# moved the NUMERIC one could not pass.
for src in ["1n", "0n", "007n", "1_000n", "1_2_3n", "10000000000000000000000n",
            "0x0n", "0x1n", "0xffn", "0xFFn", "0Xffn", "0xf_fn", "0x00ffn",
            "0b0n", "0b1n", "0b101n", "0B101n", "0b1_01n", "0b0001n",
            "0o0n", "0o7n", "0o777n", "0O777n", "0o7_7n", "0o0007n",
            "0b" + "1" * 100 + "n", "0o" + "7" * 60 + "n", "0x" + "f" * 60 + "n",
            "1", "0", "007", "1_000", "0x10", "0b101", "0o777", "1e3", "1.5",
            "0xn", "0bn", "0on", "1n2", "0o777", "0"]:
    add_t(src)

r = random.Random(20260826)

n = 0
while len(lines) < count:
    n += 1
    fam = n % 4
    if fam == 0:
        # random BYTES, so the decoder's invalid-UTF-8 arms are reached
        add_s(bytes(r.randrange(256) for _ in range(r.randrange(0, 24))))
    elif fam == 1:
        # random CODE POINTS across every plane, surrogates excluded - those are
        # covered by the sentinel cases above, which is a different encoding
        cps = []
        for _ in range(r.randrange(0, 16)):
            c = r.randrange(0x110000)
            while 0xD800 <= c <= 0xDFFF:
                c = r.randrange(0x110000)
            cps.append(chr(c))
        add_s("".join(cps).encode("utf-8"))
    elif fam == 2:
        base, digits = r.choice([("0x", "0123456789abcdefABCDEF"),
                                 ("0X", "0123456789abcdef"),
                                 ("0b", "01"), ("0B", "01"),
                                 ("0o", "01234567"), ("0O", "01234567"),
                                 ("", "0123456789")])
        t = base + "".join(r.choice(digits) for _ in range(r.randrange(1, 60)))
        if r.randrange(2):
            t += "n"
        add_b(t)
    else:
        base, digits = r.choice([("0x", "0123456789abcdefABCDEF"),
                                 ("0X", "0123456789abcdef"),
                                 ("0b", "01"), ("0B", "01"),
                                 ("0o", "01234567"), ("0O", "01234567"),
                                 ("", "0123456789")])
        ds = list(r.choice(digits) for _ in range(r.randrange(1, 40)))
        # a separator between two digits, which is the shape the stand-in broke
        if len(ds) > 2 and r.randrange(2):
            ds.insert(r.randrange(1, len(ds)), "_")
        add_t(base + "".join(ds) + ("n" if r.randrange(2) else ""))

sys.stdout.write("\n".join(lines) + "\n")
PYEOF

cases=$(wc -l < "$OUT/corpus" | tr -d ' ')

# -- the reference ------------------------------------------------------------
SUB_GITDIR=$(git -C "$SUB" rev-parse --absolute-git-dir 2>/dev/null)
if [ -n "$SUB_GITDIR" ] && [ -d "$SUB_GITDIR/info" ]; then
  grep -qx '/oracle/' "$SUB_GITDIR/info/exclude" 2>/dev/null \
    || echo '/oracle/' >> "$SUB_GITDIR/info/exclude"
fi

mkdir -p "$SUB/oracle/lits"
cp "$PKG/tests/oracle/lits.go" "$SUB/oracle/lits/main.go"
( cd "$SUB" && go build -o "$REPO/$OUT/oracle_lits" ./oracle/lits ) \
  > "$OUT/oracle-build.log" 2>&1
orc=$?
rm -rf "$SUB/oracle"
if [ $orc -ne 0 ]; then
  red "the lits oracle failed to build:"; sed 's/^/    /' "$OUT/oracle-build.log"; exit 2
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
"$SCALYC" -c -o "$OUT/tscaly_lits.o" "$PKG/0.1.0/tscaly_lits.scaly" \
  > "$OUT/prog-build.log" 2>&1
if [ $? -ne 0 ]; then
  red "tscaly_lits failed to compile:"; sed 's/^/    /' "$OUT/prog-build.log"; exit 2
fi
clang -o "$OUT/tscaly_lits" "$OUT/tscaly_lits.o" "$OUT/tscaly.o" "$LIBSCALY" -lm \
  > "$OUT/link.log" 2>&1
if [ $? -ne 0 ]; then
  red "the tscaly_lits link failed:"; sed 's/^/    /' "$OUT/link.log"; exit 2
fi

# -- the comparison -----------------------------------------------------------
#
# No pipeline around either binary: `rc=$?` after `$(prog | ...)` reads the last
# stage's status (root CLAUDE.md's harness rule).
"$OUT/oracle_lits" "$OUT/corpus" > "$OUT/ref" 2> "$OUT/ref.err"
rrc=$?
"$OUT/tscaly_lits" "$OUT/corpus" > "$OUT/ours" 2> "$OUT/ours.err"
orc=$?
if [ $rrc -ne 0 ]; then
  red "the oracle exited $rrc - suspect the harness, not the port:"
  sed 's/^/    /' "$OUT/ref.err"; exit 2
fi
if [ $orc -ne 0 ]; then
  red "tscaly_lits exited $orc:"; sed 's/^/    /' "$OUT/ours.err"; exit 1
fi

diff "$OUT/ref" "$OUT/ours" > "$OUT/diff" 2>&1
if [ $? -ne 0 ]; then
  n=$(grep -c '^<' "$OUT/diff")
  red "$n of $cases inputs differ from the reference:"
  head -20 "$OUT/diff" | sed 's/^/    /'
  echo "  full diff: $OUT/diff (the corpus line numbers are $OUT/corpus's)"
  exit 1
fi

green "OK - $cases inputs, byte-identical to the reference's own printer and jsnum."
