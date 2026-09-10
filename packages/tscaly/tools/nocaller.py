#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
#
# nocaller.py — WHICH PORTED FUNCTIONS HAVE NO CALL SITE.
#
# ★★★ WHY IT EXISTS (slice 180). `is_source_intersection_needing_extra_check` sat in
# checker.scaly with a header naming the one arm it gates — the optionals-only re-check at
# the tail of structuredTypeRelatedTo — while THAT arm's own header, three hundred lines
# away, said the arm had no input and was not written. A ported function whose header names
# its intended caller is a stronger refutation of *this arm is not reachable* than any
# measurement, and nothing in this directory looked for one: `frontier.sh` ranks what is
# LEFT, `coverage.sh` measures what is DONE against the reference, and neither can see a
# function that is done and unreachable.
#
# ★★ IT IS A LEAD LIST, NOT A DEFECT LIST. Four honest populations answer here and are
# labelled rather than filtered away, because filtering by name is how a scan starts lying:
#   ENTRY     a program's own entry point (0.1.0/tscaly_*.scaly drive them)
#   DUMP      an artifact writer selected by a flag rather than called by name
#   ARM       a helper written for an arm that is not written yet  ← the interesting one
#   DEAD      genuinely nothing
# Only reading decides which a row is, so the tool prints the definition's line for each.
#
# ★ A CALL IS TEXT HERE, and that is the conservative direction: an over-broad call
# pattern under-reports (a name that appears anywhere as `name(` counts as called), so a
# row that DOES appear is a claim worth checking and a row that does not appear proves
# nothing. Comment lines are excluded on both sides — a name discussed in prose is not a
# caller, which is the whole point.
#
# Usage:  packages/tscaly/tools/nocaller.py [file-substring ...]
import io, re, sys, glob, os

root = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '0.1.0')
files = sorted(glob.glob(os.path.join(root, 'tscaly', '*.scaly')) +
               glob.glob(os.path.join(root, '*.scaly')))
want = sys.argv[1:]

defs, calls = {}, set()
for p in files:
    for i, l in enumerate(io.open(p, encoding='utf-8').read().split('\n')):
        m = re.match(r'\s*(?:function|procedure)\s+([a-z_][a-z0-9_]*)\(', l)
        if m:
            defs.setdefault(m.group(1), []).append((p, i + 1))
            continue
        if l.lstrip().startswith(';'):
            continue
        for c in re.finditer(r'[.\s(\[,]([a-z_][a-z0-9_]*)\(', l):
            calls.add(c.group(1))

rows = []
for n in sorted(defs):
    if n in calls:
        continue
    for p, ln in defs[n]:
        b = os.path.basename(p)
        if want and not any(w in b or w in n for w in want):
            continue
        kind = 'ARM '
        if b.endswith('Dump.scaly'):
            kind = 'DUMP'
        elif b.startswith('tscaly'):
            kind = 'ENTRY'
        rows.append((kind, n, b, ln))

for kind, n, b, ln in sorted(rows):
    print("%-5s %-46s %s:%d" % (kind, n, b, ln))
print("\n%d definitions with no call site (%d in the checker's own files)" % (
    len(rows), sum(1 for r in rows if r[0] == 'ARM ')))
