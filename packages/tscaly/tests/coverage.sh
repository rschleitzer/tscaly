#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# coverage.sh — HOW MUCH OF THE REFERENCE CHECKER IS PORTED, as a percentage.
#
# ★★★ IT ANSWERS A DIFFERENT QUESTION FROM frontier.sh. That one ranks what is LEFT by
# units it would complete; this one measures what is DONE against the reference. Neither
# is the other: a chapter can be 80 % ported and complete no unit.
#
# ★★★ THE DENOMINATOR IS THE ARGUMENT. `internal/checker` holds the declaration
# EMITTER's type-node builder, the language service's hover, node copying, symbol
# accessibility and tracing — about 8 600 lines this project is not porting and never
# will. They are excluded by name; the full-package figure is printed too, so the
# exclusion is visible rather than assumed.
#
# ★★★ AND LINES OF PORT ARE NOT A MEASURE. `checker.scaly` is ~42 700 lines against the
# reference's ~44 000 for the same package, and the port is roughly two thirds
# commentary — so a line ratio would read as 97 % done. What is counted here is which
# REFERENCE functions have a port, weighted by the reference's own line counts.
#
# ★★ THE ESTIMATE IS BRACKETED BECAUSE A NAME MATCH IS WRONG IN BOTH DIRECTIONS. It
# UNDER-counts a helper the port folded into its caller, which is why the figure is also
# sliced by function SIZE — the 50+-line bucket is nearly immune to folding. And the
# *named anywhere* upper bound is deliberately labelled WORTHLESS: a spot check of 18
# such names found 6 of them named as WALLS in a row's comment, not ported.
#
# Usage:  packages/tscaly/tests/coverage.sh        (needs the submodule; ~2 s)
set -u
cd "$(dirname "$0")/.."
TS=_submodules/typescript-go/internal/checker
[ -d "$TS" ] || { echo "submodule absent — nothing to measure against." >&2; exit 2; }
python3 - "$TS" <<'PY'
import re, os, glob, io, sys
TS = sys.argv[1]
NOT_A_GOAL = {'nodebuilderimpl.go','emitresolver.go','nodecopy.go','pseudotypenodebuilder.go',
              'nodebuilder_hover.go','symbolaccessibility.go','tracer.go','services.go'}
fn = re.compile(r'^func (?:\([^)]*\)\s*)?([A-Za-z_][A-Za-z0-9_]*)\(')
def scan(skip):
    out = []
    for p in sorted(glob.glob(os.path.join(TS, '*.go'))):
        b = os.path.basename(p)
        if p.endswith('_test.go') or (skip and b in NOT_A_GOAL): continue
        lines = io.open(p, encoding='utf-8', errors='replace').read().split('\n')
        cur, start = None, 0
        for i, l in enumerate(lines):
            m = fn.match(l)
            if m:
                if cur: out.append((b, cur, i - start))
                cur, start = m.group(1), i
            elif l == '}' and cur:
                out.append((b, cur, i - start + 1)); cur = None
        if cur: out.append((b, cur, len(lines) - start))
    return out
def snake(n):
    s = re.sub(r'(.)([A-Z][a-z]+)', r'\1_\2', n)
    return re.sub(r'([a-z0-9])([A-Z])', r'\1_\2', s).lower()
port = io.open('0.1.0/tscaly/checker.scaly', encoding='utf-8').read()
defined = set(re.findall(r'^\s*(?:function|procedure)\s+([a-z_][a-z0-9_]*)', port, re.M))
def pct(rows):
    tf, tl = len(rows), sum(l for _, _, l in rows)
    df = sum(1 for f, n, l in rows if snake(n) in defined)
    dl = sum(l for f, n, l in rows if snake(n) in defined)
    return tf, tl, df, dl
for skip, label in ((False, 'the WHOLE internal/checker package'),
                    (True,  'the CHECKER PROPER (emit/service/tracing removed)')):
    rows = scan(skip); tf, tl, df, dl = pct(rows)
    print("%-52s %4d/%4d functions = %3.0f%%   %6d/%6d ref lines = %3.0f%%" % (
        label, df, tf, 100.*df/tf, dl, tl, 100.*dl/tl))
print()
rows = scan(True)
print("the CHECKER PROPER by function SIZE — the big bucket is the honest signal:")
for lo, hi, lbl in ((0,9,'1-9 lines   (fold-in territory)'), (10,19,'10-19 lines'),
                    (20,49,'20-49 lines'), (50,10**9,'50+ lines   (real chapters)')):
    sub = [r for r in rows if lo <= r[2] <= hi]
    if not sub: continue
    tf, tl, df, dl = pct(sub)
    print("  %-34s %4d/%4d = %3.0f%%   %5d/%5d lines = %3.0f%%" % (lbl, df, tf, 100.*df/tf, dl, tl, 100.*dl/tl))
print()
print("per FILE, by reference lines — where the remaining mass is:")
per = {}
for f, n, l in rows:
    a = per.setdefault(f, [0, 0]); a[1] += l
    if snake(n) in defined: a[0] += l
for f, (d, t) in sorted(per.items(), key=lambda kv: -(kv[1][1] - kv[1][0])):
    if t < 300: continue
    print("  %-22s %3.0f%% ported, %5d reference lines still to go" % (f, 100.*d/t, t - d))
PY
