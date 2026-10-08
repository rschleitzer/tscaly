#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
#
# gensymbolflags.py — generate tscaly/SymbolFlags.scaly from the reference's
# internal/ast/symbolflags.go.
#
# ★★★ WHY THIS ONE IS GENERATED while NodeFlags, ModifierFlags and TokenFlags are
# hand-ported: it is not the SIZE of the table, it is the COMPOSITES. Half of this
# enum is derived — `SymbolFlagsValue & ^SymbolFlagsFunctionScopedVariable`,
# `(SymbolFlagsValue | SymbolFlagsType) & ^(SymbolFlagsValueModule | ... )`,
# `^SymbolFlagsExportSupportsDefaultModifier` — and every one of those expressions
# is an EXCLUDES set the binder tests a symbol's flags against to decide whether a
# declaration merges or reports TS2300. A transcription slip there does not fail to
# compile: it merges two declarations that should collide, or collides two that
# should merge, and the corpus reports it hundreds of units away from the table.
#
# ★ AND SCALY CANNOT SPELL THE EXPRESSIONS ANYWAY, which is the second half of the
# argument. A module-level `define` initializer folds constants only within ONE
# precedence level and has no bitwise complement, so `A & ^B`
# cannot be written. This script resolves each composite to the set of PRIMITIVE
# bits it contains and emits an `|` chain of their names — one precedence level,
# symbolic, so a moved bit position cannot leave a stale composite behind — and
# falls back to a decimal literal, with the reference's own expression in the
# comment, for the few values that contain bits no flag has a name for.
#
# Usage (from the repo root, submodule initialized):
#   packages/tscaly/tools/gensymbolflags.py
#
# The output is committed; with the submodule absent the committed file stays valid
# and this script simply cannot run — the arrangement genkind.py describes.

import os
import re
import sys

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
SRC = os.path.join(
    REPO, "packages/tscaly/_submodules/typescript-go/internal/ast/symbolflags.go")
DST = os.path.join(REPO, "packages/tscaly/0.1.1/tscaly/SymbolFlags.scaly")

MASK = 0xFFFFFFFF          # the reference declares SymbolFlags as uint32
# A primitive is a single-bit flag written as `1 << n`; everything else is derived.
PRIMITIVE = re.compile(r"^1\s*<<\s*(\d+)$")
# The threshold above which an `|` chain stops being readable and the value is
# emitted as a number instead. Twenty leaves exactly three entries as decimals —
# SymbolFlagsAll and the two complements — and those contain bits no flag names, so
# no chain could spell them anyway. ★It was 12 in the first draft and that made
# SymbolFlagsValue, the composite the binder tests most often, a magic number: a
# limit chosen for line length had quietly decided which values stay symbolic.
CHAIN_LIMIT = 20


def parse(path):
    """(entries, order) where entries maps name -> (value, expr, comment)."""
    with open(path, encoding="utf-8") as fh:
        lines = fh.read().splitlines()
    try:
        start = lines.index("const (")
    except ValueError:
        sys.exit(f"gensymbolflags: no `const (` block in {path}")

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
        name = name.replace("SymbolFlags ", " ").strip()
        # `Name SymbolFlags = expr` and `Name = expr` both occur.
        name = re.sub(r"\s+SymbolFlags$", "", name).strip()
        expr = expr.strip()
        if not name or not expr:
            sys.exit(f"gensymbolflags: cannot read line {raw!r}")
        value = evaluate(expr, env)
        env[name] = (value, expr, comment)
        order.append(name)
    if not order:
        sys.exit("gensymbolflags: the const block is empty")
    return env, order


def evaluate(expr, env):
    """The Go expression's uint32 value, evaluated with GO's precedence.

    ★★★ NOT `eval()`, and the first draft of this script proves why: Python binds
    `-` TIGHTER than `<<` while Go binds `<<` tighter, so `1<<30 - 1` — the
    reference's SymbolFlagsAll — came out as 1<<29, which is exactly
    SymbolFlagsReplaceableByMethod's bit. The generated file then said
    `define SymbolFlagsAll: int SymbolFlagsReplaceableByMethod`, a well-formed line
    naming a real flag, and nothing about it looks wrong. A borrowed evaluator
    brings its own grammar; this one implements Go's, so the class cannot recur.

    Go's binary precedence, highest first: `<<`/`>>`, then `&` and `&^`, then `^`
    and `|`. Unary `^` is a complement. Every result is masked to 32 bits, so a
    complement answers what the reference's uint32 answers.
    """
    tokens = re.findall(r"[A-Za-z_]\w*|\d+|<<|>>|&\^|[|&^()~-]", expr)
    if "".join(tokens) != re.sub(r"\s+", "", expr):
        sys.exit(f"gensymbolflags: cannot tokenize {expr!r} — a construct this "
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
                sys.exit(f"gensymbolflags: unbalanced parentheses in {expr!r}")
            return v
        if t in ("^", "~"):
            return ~primary() & MASK
        if t == "-":
            return -primary() & MASK
        if t is None:
            sys.exit(f"gensymbolflags: expression ends early: {expr!r}")
        if t.isdigit():
            return int(t)
        if t not in env:
            sys.exit(f"gensymbolflags: {expr!r} names {t}, which is not defined "
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
            # ★ The file's every `^` is a UNARY complement (checked at authoring
            # time), so a binary one here is a change in the source's conventions
            # rather than something to guess about.
            if op == "^":
                sys.exit(f"gensymbolflags: binary `^` in {expr!r} — the reference "
                         "used to have none; decide what it means before trusting "
                         "a generated value.")
            v = (v | r) & MASK
        return v

    # A `-` after a value is Go's binary subtraction (`1<<30 - 1`); handled here so
    # that the unary case above stays the only other reading.
    def top():
        v = expr_or()
        while peek() == "-":
            take()
            v = (v - expr_or()) & MASK
        return v

    value = top()
    if pos[0] != len(tokens):
        sys.exit(f"gensymbolflags: trailing tokens in {expr!r}: "
                 f"{tokens[pos[0]:]}")
    return value


def decompose(value, primitives):
    """The primitive flag NAMES whose OR is exactly `value`, or None."""
    names, rest = [], value
    for name, bit in primitives:
        if value & bit:
            names.append(name)
            rest &= ~bit
    return names if rest == 0 else None


def main():
    if not os.path.isfile(SRC):
        sys.exit(f"gensymbolflags: no reference source at {SRC}\n"
                 "  git submodule update --init packages/tscaly/_submodules/typescript-go\n"
                 "This is a missing input, not a result — the committed file stays valid.")
    env, order = parse(SRC)

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
    w("; SymbolFlags — GENERATED by packages/tscaly/tools/gensymbolflags.py from the")
    w("; pinned reference's internal/ast/symbolflags.go. Do not edit; edit the")
    w("; generator.")
    w(";")
    w("; ★★★ The composites are what make this a generated file rather than a")
    w("; hand-ported one. Every `Excludes` value is the set a declaration may NOT")
    w("; merge with, and the binder tests a symbol's flags against it to decide")
    w("; between merging and reporting TS2300 — so a transcription slip does not fail")
    w("; to compile, it merges what should collide. The reference writes them as")
    w("; `SymbolFlagsValue & ^SymbolFlagsMethod` and Scaly cannot: a module-level")
    w("; `define` initializer folds within ONE precedence level and has no bitwise")
    w("; complement. Each composite is therefore resolved here to the PRIMITIVE bits")
    w("; it contains and emitted as an `|` chain of their names — symbolic, so a moved")
    w("; bit position cannot leave a stale composite behind — with the reference's own")
    w("; expression kept in the comment beside it.")
    w(";")
    w("; ★ A few values contain bits no flag names (the two complements and")
    w("; SymbolFlagsAll, which is `1<<30 - 1`). Those are emitted as decimals, because")
    w("; there is no chain that spells them, and their reference expression is the")
    w("; comment. Upstream declares this uint32; here it is int (i64), and a")
    w("; complement is therefore masked to 32 bits exactly as the reference's is.")
    w("")

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
        if parts is not None and len(parts) <= CHAIN_LIMIT:
            chain = " | ".join(parts)
            w(f"; {expr}" + (f"   ; {comment}" if comment else ""))
            w(f"define {name}: int {chain}")
        else:
            w(f"; {expr}" + (f"   ; {comment}" if comment else ""))
            w(f"define {name}: int {value}")
        w("")

    text = "\n".join(out).rstrip("\n") + "\n"
    with open(DST, "w", encoding="utf-8") as fh:
        fh.write(text)
    print(f"gensymbolflags: wrote {DST} — {len(order)} entries, "
          f"{len(primitives)} primitive bits")
    return 0


if __name__ == "__main__":
    sys.exit(main())
