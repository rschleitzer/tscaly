#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# arithcheck.sh - the cross-check for jsnum's ARITHMETIC (slice 116).
#
# numcheck.sh's twin, and half of the reference file apart from it. That one
# measures the CONVERSION - FromString and String, which is Go's decimal<->binary
# code and runs without a single floating-point operation. This one measures the
# OPERATIONS the enum evaluator needs: the four arithmetic operators, the five
# bitwise ones, the three shifts, Remainder and Exponentiate.
#
# WHY IT IS A GATE OF ITS OWN. The checker yardstick sees these operators through
# ENUM MEMBER VALUES and nowhere else, and the corpus's enums are almost all
# small non-negative integers: ToInt32's modulus, the shift count's `& 31`, a
# NaN through a remainder, the sign of a negative zero, `-1 >>> 0` and an
# exponent that is not an integer are between them ZERO units. An unexercised arm
# is indistinguishable from a correct one, so: one generated corpus, two
# producers, a byte diff.
#
#   ours       packages/tscaly/0.1.0/tscaly_arith.scaly + tscaly/ArithCheck.scaly
#   reference  packages/tscaly/tests/oracle/arith.go, over the submodule's jsnum
#
# The corpus is GENERATED here rather than committed, from a fixed seed. One line
# is TWO 16-hex-digit bit patterns, which is the only spelling that reaches an
# arbitrary pair of doubles - a decimal text cannot, and neither can a source.
#
# Submodule discipline is run.sh's, for run.sh's reason.
#
# Usage:  packages/tscaly/tests/arithcheck.sh [count]      (default 20000)

set -u

cd "$(dirname "$0")/../../.."
REPO=$(pwd)

PKG=packages/tscaly
SUB=$PKG/_submodules/typescript-go
OUT=$PKG/tests/out/arith
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
seen = set()

def bits(x):
    return "%016X" % struct.unpack("<Q", struct.pack("<d", x))[0]

def add(a, b):
    line = a + " " + b
    if line not in seen:
        seen.add(line)
        lines.append(line)

# The hand cases first, because a random generator does not produce the values a
# reader would think of: the two zeros, the specials, the int32 and uint32
# boundaries, the shift-count wrap at 32, the safe-integer edge, a denormal, and
# the exponent shapes Exponentiate's own switch names.
HAND = [0.0, -0.0, 1.0, -1.0, 2.0, -2.0, 0.5, -0.5, 3.0, 10.0, 31.0, 32.0, 33.0,
        63.0, 64.0, 65.0, 255.0, 256.0,
        2147483647.0, 2147483648.0, -2147483648.0, -2147483649.0,
        4294967295.0, 4294967296.0, 4294967297.0,
        9007199254740991.0, 9007199254740992.0, -9007199254740991.0,
        1e21, 1e-21, 1e308, -1e308, 5e-324, 2.2250738585072014e-308,
        0.1, 0.2, 1.5, 2.5, -2.5, 1e-6, 123.456, -123.456,
        float("inf"), float("-inf"), float("nan")]
for a in HAND:
    for b in HAND:
        add(bits(a), bits(b))

# A NaN with a payload of its own: the port answers one fixed pattern where Go's
# math.NaN() answers another, and only a corpus that carries both can show that
# every operation propagates the OPERAND's payload rather than minting one.
PAYLOAD = ["7FF8000000000001", "7FF8000000000000", "FFF8000000000000",
           "7FF0000000000001", "FFFFFFFFFFFFFFFF"]
for p in PAYLOAD:
    for a in HAND[:12]:
        add(p, bits(a))
        add(bits(a), p)

r = random.Random(20260901)
def rnd():
    fam = r.randrange(4)
    if fam == 0:
        return "%016X" % r.getrandbits(64)
    if fam == 1:
        return bits(float(r.randrange(-(1 << 34), 1 << 34)))
    if fam == 2:
        return bits(r.uniform(-1e6, 1e6))
    return bits(float(r.randrange(0, 64)))

while len(lines) < count:
    add(rnd(), rnd())

sys.stdout.write("\n".join(lines[:count]) + "\n")
PYEOF

cases=$(wc -l < "$OUT/corpus" | tr -d ' ')

# -- the reference ------------------------------------------------------------
SUB_GITDIR=$(git -C "$SUB" rev-parse --absolute-git-dir 2>/dev/null)
if [ -n "$SUB_GITDIR" ] && [ -d "$SUB_GITDIR/info" ]; then
  grep -qx '/oracle/' "$SUB_GITDIR/info/exclude" 2>/dev/null \
    || echo '/oracle/' >> "$SUB_GITDIR/info/exclude"
fi

mkdir -p "$SUB/oracle/arith"
cp "$PKG/tests/oracle/arith.go" "$SUB/oracle/arith/main.go"
( cd "$SUB" && go build -o "$REPO/$OUT/oracle_arith" ./oracle/arith ) \
  > "$OUT/oracle-build.log" 2>&1
orc=$?
rm -rf "$SUB/oracle"
if [ $orc -ne 0 ]; then
  red "the arith oracle failed to build:"; sed 's/^/    /' "$OUT/oracle-build.log"; exit 2
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
"$SCALYC" -c -o "$OUT/tscaly_arith.o" "$PKG/0.1.0/tscaly_arith.scaly" \
  > "$OUT/prog-build.log" 2>&1
if [ $? -ne 0 ]; then
  red "tscaly_arith failed to compile:"; sed 's/^/    /' "$OUT/prog-build.log"; exit 2
fi
clang -o "$OUT/tscaly_arith" "$OUT/tscaly_arith.o" "$OUT/tscaly.o" "$LIBSCALY" -lm \
  > "$OUT/link.log" 2>&1
if [ $? -ne 0 ]; then
  red "the tscaly_arith link failed:"; sed 's/^/    /' "$OUT/link.log"; exit 2
fi

# -- the comparison -----------------------------------------------------------
#
# No pipeline around either binary: `rc=$?` after `$(prog | ...)` reads the last
# stage's status (root CLAUDE.md's harness rule).
"$OUT/oracle_arith" "$OUT/corpus" > "$OUT/ref" 2> "$OUT/ref.err"
rrc=$?
"$OUT/tscaly_arith" "$OUT/corpus" > "$OUT/ours" 2> "$OUT/ours.err"
orc=$?
if [ $rrc -ne 0 ]; then
  red "the oracle exited $rrc - suspect the harness, not the port:"
  sed 's/^/    /' "$OUT/ref.err"; exit 2
fi
if [ $orc -ne 0 ]; then
  red "tscaly_arith exited $orc:"; sed 's/^/    /' "$OUT/ours.err"; exit 1
fi

# -- the comparison, and the ONE column that is not byte-exact ----------------
#
# ★★★ TWELVE COLUMNS ARE COMPARED BYTE FOR BYTE. The thirteenth, Exponentiate,
# is compared by CATEGORY exactly and by MANTISSA within a measured bound, and
# that is a divergence this suite reports rather than one it hides: Go's
# `math.Pow` is a Go implementation over Frexp/Log/Exp/Sqrt with its own special
# cases (`y == 0.5` becomes Sqrt, an integer exponent becomes repeated squaring),
# where this port calls libm's `pow`. Closing it means porting math.Pow, math.Exp
# and math.Log — see the operator's own note in jsnum.scaly for what that would
# buy, measured over both corpora.
#
# ★★★ WHAT THE CATEGORY TEST PINS, and it is the half that matters for a port:
# NaN-ness, an infinity and its sign, the sign of a finite result and a zero.
# Measured over 20 000 pairs: those agree on EVERY line, in both directions. So a
# `-1 ** 0.5` that stops being NaN, or an overflow that stops being +Inf, is RED
# here — only the last mantissa digits are tolerated.
#
# ★★ AND THE MANTISSA BOUND IS A NUMBER SOMEBODY MEASURED. The observed maximum
# on this host is 113 ULP, at `0.2 ** 254` and its neighbours; the bound is set
# at 512 so a host whose libm rounds differently is not a red run, and a real
# defect — which moves an answer by orders of magnitude, not by digits — still
# is. The distribution is printed, because a tolerance nobody counts is a silence.
python3 - "$OUT/ref" "$OUT/ours" "$cases" <<'PYEOF'
import struct, sys

MAX_ULP = 512
ref, ours, cases = open(sys.argv[1]), open(sys.argv[2]), int(sys.argv[3])
NAMES = "add sub mul div rem exp or and xor shl shr ushr not".split()
EXP = NAMES.index("exp")
INF, NEG_INF = float("inf"), float("-inf")

def val(h):
    return struct.unpack("<d", struct.pack("<Q", int(h, 16)))[0]

def ordered(h):
    # The IEEE bit pattern read as a signed magnitude, so |a-b| == 1 means
    # ADJACENT doubles across the whole range, zero and denormals included.
    b = int(h, 16)
    return b if b < (1 << 63) else -(b - (1 << 63))

def category(v):
    if v != v:
        return "nan"
    if v == INF:
        return "+inf"
    if v == NEG_INF:
        return "-inf"
    if v == 0:
        return "zero"
    return "neg" if v < 0 else "pos"

hard, tolerated, worst, lines = [], 0, 0, 0
for a, b in zip(ref, ours):
    a, b = a.rstrip("\n"), b.rstrip("\n")
    if not a and not b:
        continue
    lines += 1
    if a == b:
        continue
    fa, fb = a.split(), b.split()
    if len(fa) != 13 or len(fb) != 13:
        hard.append((lines, "malformed line", a[:32], b[:32]))
        continue
    for i, (x, y) in enumerate(zip(fa, fb)):
        if x == y:
            continue
        if i != EXP:
            hard.append((lines, NAMES[i], x, y))
            continue
        vx, vy = val(x), val(y)
        if category(vx) != category(vy):
            hard.append((lines, "exp category %s/%s" % (category(vx), category(vy)), x, y))
            continue
        if vx != vx:
            tolerated += 1          # two NaNs, different payloads
            continue
        d = abs(ordered(x) - ordered(y))
        if d > MAX_ULP:
            hard.append((lines, "exp %d ULP" % d, x, y))
            continue
        tolerated += 1
        worst = max(worst, d)

if hard:
    print("\033[31m%d differences the bound does not cover, over %d inputs:\033[0m"
          % (len(hard), cases))
    for ln, what, x, y in hard[:20]:
        print("    line %d  %-22s ref %s  ours %s" % (ln, what, x, y))
    sys.exit(1)

print("\033[32mOK - %d inputs; twelve operators byte-identical to the reference's own"
      " jsnum.\033[0m" % cases)
print("  Exponentiate: %d lines differ, category exact on every one, worst mantissa"
      " gap %d ULP (bound %d) - see its note in jsnum.scaly."
      % (tolerated, worst, MAX_ULP))
PYEOF
