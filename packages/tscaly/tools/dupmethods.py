#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
#
# dupmethods.py — TWO FUNCTIONS OF ONE CONCEPT WITH THE SAME NAME.
#
# ★★★ WHY IT EXISTS. This is a known compiler trap: a method
# and a static of one concept with the same name and the same parameter list mangle to ONE
# Itanium symbol, the emitter keeps ONE body, the linker has nothing to object to because
# only one definition exists, and the other call form then passes its first argument into
# the wrong slot. §3.5fo cost a slice 470 lines that already existed; §3.5fw found a
# duplicate whose SECOND body was the richer one, invisible because both types PRINT the
# same; §3.5gc took 28 stage-2 units down the day a `record_unported` stopped hiding one.
#
# ★★★ AND THE CHECK HAS BEEN PROSE SINCE SLICE 134. Every one of those entries ends with
# *run the one-line duplicate grep as the LAST step of every slice that added a helper*,
# and `tests/run.sh`'s own scan covers only TOP-LEVEL `define`s — which is the population
# that never collided. This is the one that does.
#
# ★★ THE SCOPE IS THE CONCEPT, NOT THE FILE, and that is the whole difficulty: `scanner.scaly`
# declares several concepts and a name repeating across two of them is ordinary. Scoping by
# file reports two dozen rows that are all fine and trains a reader to skip the output.
#
# ★ `this` vs STATIC is printed rather than filtered on: the two forms are the DANGEROUS
# pair (neither the receiver nor the implicit caller page is in the mangled name), so a row
# mixing them is the sharper finding, not an exemption.
#
# Usage:  packages/tscaly/tools/dupmethods.py      (exit 1 if any row)
import io, re, sys, glob, os, collections

root = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '0.1.1')
seen = collections.defaultdict(list)
for p in sorted(glob.glob(os.path.join(root, 'tscaly', '*.scaly')) +
                glob.glob(os.path.join(root, '*.scaly'))):
    concept = '<top level>'
    for i, l in enumerate(io.open(p, encoding='utf-8').read().split('\n')):
        m = re.match(r'define\s+([A-Za-z_][A-Za-z0-9_]*)', l)
        if m:
            concept = m.group(1)
            continue
        f = re.match(r'\s*(?:function|procedure)\s+([a-z_][a-z0-9_]*)\(([^)]*)', l)
        if f:
            form = 'this' if f.group(2).strip().startswith('this') else 'static'
            seen[(os.path.basename(p), concept, f.group(1))].append((i + 1, form))

rows = sorted((k, v) for k, v in seen.items() if len(v) > 1)
for (b, concept, name), sites in rows:
    forms = {f for _, f in sites}
    mark = ' ★ MIXED this/static' if len(forms) > 1 else ''
    print("%-16s %-10s %-48s %s%s" % (
        b, concept, name, ', '.join("%d (%s)" % s for s in sites), mark))
print("\n%d names defined more than once in one concept" % len(rows))
sys.exit(1 if rows else 0)
