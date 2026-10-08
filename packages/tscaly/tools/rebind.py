#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
#
# rebind.py — the NORMALISATION PREAMBLE, and the arm that kept the old name.
#
# ★★★ WHY THIS EXISTS. Go rebinds a parameter. `getTypeFactsWorker` opens with
#
#     if t.flags&(TypeFlagsIntersection|TypeFlagsInstantiable) != 0 {
#         t = c.getBaseConstraintOfType(t)
#         if t == nil { t = c.unknownType }
#     }
#
# and all twenty arms below read the CONSTRAINT, because `t` now holds it. Scaly
# cannot rebind a parameter, so the port gives the normalised value a name of its
# own — `var base: ref[Type]? t` … `let ty base as ref[Type]` — and every arm has
# to be rewritten to say `ty`. Slice 185 found TWO arms of that function still
# saying `t`: the union arm asked `union_types_of(t)` of a TYPE PARAMETER, got
# null and answered TypeFactsNone, so EVERY narrowing of a type parameter whose
# constraint is a union came out `never`. Six stage-2 units, one character each.
#
# ★★★ AND IT IS INVISIBLE TO EVERY OTHER INSTRUMENT: it records no stop, so
# `frontier.sh` cannot see it; it compiles, so no gate fires; and the arms that
# WERE rewritten are the large majority, so the function reads right.
#
# ★★★ THE SHAPE IT KEYS ON IS THE MAJORITY, NOT THE REBIND. A first version
# reported every parameter read after any `set` of a local seeded from it — 8 622
# rows, which is not a work list. What separates a defect from a deliberate
# forward is the RATIO: the normalised name is what the rest of the function
# speaks, so it is read many times and the original a handful. This reports only
# where the port has committed to the new name — an `let <alias> <local> as …`
# line, the idiom for *from here on use this* — and ranks by how lopsided the two
# counts are.
#
# ★ It stays a HEURISTIC and says so: forwarding the ORIGINAL is legitimate (an
# error node, the pre-normalisation type in a report). The output is a work list.
#
# Usage:  packages/tscaly/tools/rebind.py [--all] [FILE ...]

import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
PKG = os.path.join(os.path.dirname(HERE), "0.1.1", "tscaly")

FUNC = re.compile(r"^    (function|procedure) ([a-z_0-9]+)\(([^)]*)\)")
SEED = re.compile(r"^\s*var ([a-z_][a-z_0-9]*)(?::\s*\S+)?\s+([a-z_][a-z_0-9]*)\s*$")
SETQ = re.compile(r"^\s*set ([a-z_][a-z_0-9]*):")
ALIAS = re.compile(r"^\s*let ([a-z_][a-z_0-9]*)\s+([a-z_][a-z_0-9]*) as ")


def split_params(sig):
    out, depth, cur = [], 0, ""
    for ch in sig:
        if ch == "[":
            depth += 1
        elif ch == "]":
            depth -= 1
        if ch == "," and depth == 0:
            out.append(cur)
            cur = ""
        else:
            cur += ch
    out.append(cur)
    return [p.strip().split(":")[0].strip() for p in out
            if p.strip() and p.strip() != "this"]


def strip_comment(line):
    out, in_str, i = [], False, 0
    while i < len(line):
        c = line[i]
        if c == '"':
            in_str = not in_str
        elif c == ";" and not in_str:
            break
        out.append(c)
        i += 1
    return "".join(out)


def word(n):
    return re.compile(r"(?<![A-Za-z0-9_])%s(?![A-Za-z0-9_])" % re.escape(n))


def scan_body(fname, fline, pnames, body):
    code = [(i, strip_comment(raw), raw) for i, raw in body]
    out = []
    for p in pnames:
        # a local seeded from the parameter, and rebound later
        seed = None
        for i, c, _ in code:
            m = SEED.match(c)
            if m and m.group(2) == p:
                seed = (m.group(1), i)
                break
        if seed is None:
            continue
        q, seed_at = seed
        rebound = next((i for i, c, _ in code
                        if i > seed_at and SETQ.match(c) and SETQ.match(c).group(1) == q), None)
        if rebound is None:
            continue
        # the port has COMMITTED to a name: `let <alias> <q> as …`
        alias = next(((m.group(1), i) for i, c, _ in code
                      for m in [ALIAS.match(c)] if m and m.group(2) == q and i > rebound), None)
        if alias is None:
            continue
        aname, aline = alias
        wp, wa = word(p), word(aname)
        after = [(i, c, raw) for i, c, raw in code if i > aline]
        n_alias = sum(1 for _, c, _ in after if wa.search(c))
        hits = [(i, raw) for i, c, raw in after if wp.search(c)]
        if not hits or n_alias <= len(hits):
            continue
        out.append((fline, fname, p, aname, n_alias, hits))
    return out


def scan(path):
    lines = open(path, encoding="utf-8").read().split("\n")
    res, fname, fline, pnames, body = [], None, 0, [], []
    for i, raw in enumerate(lines, 1):
        m = FUNC.match(raw)
        if m:
            if fname:
                res += scan_body(fname, fline, pnames, body)
            fname, fline, pnames, body = m.group(2), i, split_params(m.group(3)), []
            continue
        if fname:
            body.append((i, raw))
    if fname:
        res += scan_body(fname, fline, pnames, body)
    return res


def main():
    args = [a for a in sys.argv[1:] if a != "--all"]
    files = args or sorted(os.path.join(PKG, f) for f in os.listdir(PKG) if f.endswith(".scaly"))
    total = 0
    rows = []
    for path in files:
        rel = os.path.relpath(path, os.path.dirname(HERE))
        for fline, fname, p, aname, n_alias, hits in scan(path):
            rows.append((n_alias / len(hits), rel, fline, fname, p, aname, n_alias, hits))
            total += len(hits)
    rows.sort(key=lambda r: -r[0])
    for ratio, rel, fline, fname, p, aname, n_alias, hits in rows:
        print("%s:%d  %s — `%s` (the parameter) read %d× after the port committed to"
              " `%s` (%d×)" % (rel, fline, fname, p, len(hits), aname, n_alias))
        for i, raw in hits[:6]:
            print("      %d: %s" % (i, raw.strip()[:110]))
        if len(hits) > 6:
            print("      … %d more" % (len(hits) - 6))
    print()
    print("%d functions, %d suspect reads. A forward of the ORIGINAL is legitimate"
          " — read each one." % (len(rows), total))


main()
