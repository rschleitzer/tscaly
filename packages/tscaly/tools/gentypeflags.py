#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
#
# gentypeflags.py — generate tscaly/TypeFlags.scaly from the reference's
# internal/checker/types.go.
#
# ★★★ WHY THIS ONE IS GENERATED, and it is gensymbolflags.py's argument one
# dimension over: it is the COMPOSITES, not the size of the table. Thirty-eight of
# this enum's entries are derived — TypeFlagsPrimitive, TypeFlagsNarrowable,
# TypeFlagsPossiblyFalsy, TypeFlagsIncludesMask — and each of them is a SET the
# checker tests a type's flags against to decide what a type IS. A transcription
# slip there does not fail to compile: it makes `void` falsy or `never`
# narrowable, and the corpus reports it in a type string a thousand units away
# from the table.
#
# ★ AND THE REFERENCE'S OWN COMMENT AT THE HEAD OF THE BLOCK IS WHY THE BIT
# POSITIONS MAY NOT BE REARRANGED: "the numeric values of TypeFlags determine the
# order computed by the CompareTypes function and therefore the order of
# constituent types in union types". So this table is not only a set of names, it
# is an ORDER that a union's printed form depends on — which is exactly what the
# fifth yardstick compares. Generating it is how that order stays the
# reference's.
#
# ★ Scaly cannot spell the expressions anyway, which is the second half of the
# argument, verbatim from gensymbolflags.py: a module-level `define` initializer
# folds constants only within ONE precedence level and has no bitwise complement,
# so `A & ^B` cannot be written. Each composite is resolved here
# to the PRIMITIVE bits it contains and emitted as an `|` chain of their names —
# symbolic, so a moved bit position cannot leave a stale composite behind — with
# the reference's own expression kept in the comment.
#
# ★★ THE EVALUATOR IS SHARED IN SPIRIT AND NOT IN CODE, and that is deliberate:
# gensymbolflags.py's header records that a borrowed evaluator brings its own
# grammar (Python binds `-` tighter than `<<`, Go the other way round, and the
# first draft of that script turned `1<<30 - 1` into `1<<29` — a well-formed line
# naming a real flag). The same Go-precedence parser is therefore repeated here
# rather than imported across a tools directory, and the CHECKSUM below is what
# says it agrees with the reference: every value is compared against the numbers
# the GO COMPILER prints for the same names (--verify), which is a second
# producer rather than a closer reading.
#
# Usage (from the repo root, submodule initialized):
#   packages/tscaly/tools/gentypeflags.py [--verify]
#
# The output is committed; with the submodule absent the committed file stays
# valid and this script simply cannot run — the arrangement genkind.py describes.

import os
import re
import subprocess
import sys
import tempfile

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
SUB = os.path.join(REPO, "packages/tscaly/_submodules/typescript-go")
SRC = os.path.join(SUB, "internal/checker/types.go")
DST = os.path.join(REPO, "packages/tscaly/0.1.1/tscaly/TypeFlags.scaly")

MASK = 0xFFFFFFFF          # the reference declares TypeFlags as uint32
PRIMITIVE = re.compile(r"^1\s*<<\s*(\d+)$")
# The threshold above which an `|` chain stops being readable. Twenty is
# gensymbolflags.py's number and it was chosen there by what it leaves symbolic
# rather than by line length; here it leaves every composite as a chain except
# the four widest masks, which is the same test applied to a different table.
CHAIN_LIMIT = 20

# The const block to read. types.go holds a dozen of them, so the block is
# identified by a member rather than by position — a new enum inserted above this
# one must not silently redirect the generator.
ANCHOR = "TypeFlagsNone"


def parse(path):
    """(entries, order) where entries maps name -> (value, expr, comment)."""
    with open(path, encoding="utf-8") as fh:
        lines = fh.read().splitlines()

    start = None
    for i, raw in enumerate(lines):
        if raw.strip() == "const (":
            for probe in lines[i + 1:]:
                if probe.strip() == ")":
                    break
                if probe.strip().startswith(ANCHOR):
                    start = i
                    break
        if start is not None:
            break
    if start is None:
        sys.exit(f"gentypeflags: no `const (` block declaring {ANCHOR} in {path}")

    env, order = {}, []
    for raw in lines[start + 1:]:
        line = raw.strip()
        if line == ")":
            break
        if not line or line.startswith("//"):
            continue
        code, _, comment = line.partition("//")
        comment = comment.strip()
        name, _, expr = code.partition("=")
        # `Name TypeFlags = expr` and `Name = expr` both occur.
        name = re.sub(r"\s+TypeFlags$", "", name.strip()).strip()
        expr = expr.strip()
        if not name or not expr:
            sys.exit(f"gentypeflags: cannot read line {raw!r}")
        env[name] = (evaluate(expr, env), expr, comment)
        order.append(name)
    if not order:
        sys.exit("gentypeflags: the const block is empty")
    return env, order


def evaluate(expr, env):
    """The Go expression's uint32 value, evaluated with GO's precedence.

    See the header: NOT `eval()`. Go's binary precedence, highest first:
    `<<`/`>>`, then `&` and `&^`, then `^` and `|`. Unary `^` is a complement.
    Every result is masked to 32 bits, so a complement answers what the
    reference's uint32 answers.
    """
    tokens = re.findall(r"[A-Za-z_]\w*|\d+|<<|>>|&\^|[|&^()~-]", expr)
    if "".join(tokens) != re.sub(r"\s+", "", expr):
        sys.exit(f"gentypeflags: cannot tokenize {expr!r} — a construct this "
                 "evaluator does not know would otherwise be silently dropped.")
    pos = [0]

    def peek():
        return tokens[pos[0]] if pos[0] < len(tokens) else None

    def take():
        t = peek()
        pos[0] += 1
        return t

    def primary():
        t = take()
        if t == "(":
            v = expr_or()
            if take() != ")":
                sys.exit(f"gentypeflags: unbalanced parentheses in {expr!r}")
            return v
        if t in ("^", "~"):
            return ~primary() & MASK
        if t == "-":
            return -primary() & MASK
        if t is None:
            sys.exit(f"gentypeflags: expression ends early: {expr!r}")
        if t.isdigit():
            return int(t)
        if t not in env:
            sys.exit(f"gentypeflags: {expr!r} names {t}, which is not defined "
                     "above it — the const block's order has changed.")
        return env[t][0]

    def shifts():
        v = primary()
        while peek() in ("<<", ">>"):
            op = take()
            r = primary()
            v = (v << r) if op == "<<" else (v >> r)
            v &= MASK
        return v

    def ands():
        v = shifts()
        while peek() in ("&", "&^"):
            op = take()
            r = shifts()
            v = (v & r) if op == "&" else (v & ~r)
            v &= MASK
        return v

    def expr_or():
        v = ands()
        while peek() in ("|", "^"):
            op = take()
            r = ands()
            # Every `^` in this block is a UNARY complement; a binary one is a
            # change in the source's conventions rather than something to guess
            # about. gensymbolflags.py refuses it for the same reason.
            if op == "^":
                sys.exit(f"gentypeflags: binary `^` in {expr!r} — decide what it "
                         "means before trusting a generated value.")
            v = (v | r) & MASK
        return v

    def top():
        v = expr_or()
        while peek() == "-":
            take()
            v = (v - expr_or()) & MASK
        return v

    value = top()
    if pos[0] != len(tokens):
        sys.exit(f"gentypeflags: trailing tokens in {expr!r}: {tokens[pos[0]:]}")
    return value


def decompose(value, primitives):
    """The primitive flag NAMES whose OR is exactly `value`, or None."""
    names, rest = [], value
    for name, bit in primitives:
        if value & bit:
            names.append(name)
            rest &= ~bit
    return names if rest == 0 else None


def verify(env, order):
    """Compare every value against what the GO COMPILER prints for it.

    ★ A second PRODUCER, which is what a claim about numbers needs (slice 27
    checked SymbolFlags this way and it is the reason that table is trusted). The
    program is generated into the submodule, built, run and removed; the
    submodule must be clean afterwards, which run.sh checks anyway.
    """
    # The constants are unexported, so the probe cannot name them from outside
    # the package; it is written INTO the package instead. `checker.TypeFlags` is
    # exported, its members are not.
    body = ["package checker", "", 'import "fmt"', "", 'import "testing"', "",
            "func TestPrintTypeFlagValues(t *testing.T) {"]
    for name in order:
        body.append(f'\tfmt.Printf("%s %d\\n", "{name}", uint32({name}))')
    body.append("}")
    probe = os.path.join(SUB, "internal/checker/zz_gentypeflags_probe_test.go")
    with open(probe, "w", encoding="utf-8") as fh:
        fh.write("\n".join(body) + "\n")
    try:
        r = subprocess.run(["go", "test", "-run", "TestPrintTypeFlagValues", "-v",
                            "./internal/checker"],
                           cwd=SUB, capture_output=True, text=True)
    finally:
        os.remove(probe)
    if r.returncode != 0:
        sys.exit("gentypeflags: the probe did not build:\n" + r.stdout + r.stderr)
    seen = {}
    for line in r.stdout.splitlines():
        parts = line.split()
        if len(parts) == 2 and parts[0] in env and parts[1].isdigit():
            seen[parts[0]] = int(parts[1])
    missing = [n for n in order if n not in seen]
    if missing:
        sys.exit(f"gentypeflags: the probe printed nothing for {missing}")
    bad = [(n, env[n][0], seen[n]) for n in order if env[n][0] != seen[n]]
    for n, ours, theirs in bad:
        print(f"gentypeflags: MISMATCH {n}: this script {ours}, go {theirs}")
    print(f"gentypeflags: verified {len(order)} values against the Go compiler, "
          f"{len(bad)} mismatches")
    return 1 if bad else 0


def main():
    if not os.path.isfile(SRC):
        sys.exit(f"gentypeflags: no reference source at {SRC}\n"
                 "  git submodule update --init packages/tscaly/_submodules/typescript-go\n"
                 "This is a missing input, not a result — the committed file stays valid.")
    env, order = parse(SRC)

    if "--verify" in sys.argv[1:]:
        return verify(env, order)

    primitives = []
    for name in order:
        value, expr, _ = env[name]
        m = PRIMITIVE.match(expr)
        if m:
            primitives.append((name, value))

    out = []
    w = out.append
    w("; SPDX-License-Identifier: Apache-2.0")
    w(";")
    w("; TypeFlags — GENERATED by packages/tscaly/tools/gentypeflags.py from the")
    w("; pinned reference's internal/checker/types.go. Do not edit; edit the")
    w("; generator.")
    w(";")
    w("; ★★★ The composites are what make this a generated file rather than a")
    w("; hand-ported one, exactly as with SymbolFlags: each derived value is a SET")
    w("; the checker tests a type's flags against to decide what the type IS")
    w("; (TypeFlagsPrimitive, TypeFlagsPossiblyFalsy, TypeFlagsNarrowable,")
    w("; TypeFlagsIncludesMask), so a slip does not fail to compile — it makes")
    w("; `void` falsy or `never` narrowable, and the corpus reports it in a type")
    w("; string far from this table. The reference writes them as `A | B` and")
    w("; `A & ^B`, and Scaly can spell neither across precedence levels, so every")
    w("; composite is resolved to the PRIMITIVE bits it contains and emitted as an")
    w("; `|` chain of their names, with the reference's own expression in the")
    w("; comment beside it.")
    w(";")
    w("; ★★ AND THE BIT POSITIONS ARE AN ORDER, not just a set of names. The")
    w("; reference's own comment above this block: *the numeric values of TypeFlags")
    w("; determine the order computed by the CompareTypes function and therefore the")
    w("; order of constituent types in union types* — so this table decides how a")
    w("; union PRINTS, which is what the fifth yardstick compares. Generating it is")
    w("; how that order stays the reference's.")
    w(";")
    w("; ★ Upstream declares this uint32; here it is int (i64), so a complement is")
    w("; masked to 32 bits exactly as the reference's is. Checked against the numbers")
    w("; the GO COMPILER prints for the same names: `gentypeflags.py --verify`.")
    w("")

    chains = 0
    decimals = 0
    for name in order:
        value, expr, comment = env[name]
        m = PRIMITIVE.match(expr)
        tail = f"   ; {comment}" if comment else ""
        if m:
            w(f"define {name}: int 1 << {m.group(1)}{tail}")
            continue
        if value == 0:
            w(f"define {name}: int 0{tail}")
            continue
        parts = decompose(value, primitives)
        w(f"; {expr}" + (f"   ; {comment}" if comment else ""))
        if parts is not None and len(parts) <= CHAIN_LIMIT:
            w(f"define {name}: int " + " | ".join(parts))
            chains += 1
        else:
            w(f"define {name}: int {value}")
            decimals += 1
        w("")

    text = "\n".join(out).rstrip("\n") + "\n"
    with open(DST, "w", encoding="utf-8") as fh:
        fh.write(text)
    print(f"gentypeflags: wrote {DST} — {len(order)} entries, "
          f"{len(primitives)} primitive bits, {chains} chains, {decimals} decimals")
    return 0


if __name__ == "__main__":
    sys.exit(main())
