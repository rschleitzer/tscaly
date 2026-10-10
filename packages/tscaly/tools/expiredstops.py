#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
#
# expiredstops.py — WHICH `record_unported` NOTES NAME A CALLEE THAT IS ALREADY HERE.
#
# ★★★ WHY IT EXISTS. §3.5eo: a stop's note is an ARGUMENT, its premises are facts
# about ANOTHER part of the file, and nothing in this apparatus re-checks a premise —
# `frontier.sh` ranks the row, `stops.sh` counts arrivals, `coverage.sh` measures the
# reference, and none of them READS the note. Five slices in a row found that the
# frontier's head was mostly notes whose argument had stopped being true, and the
# reading that found them was done by hand each time. This is that reading, mechanised
# for the one premise a machine can check: *this port does not have <callee>*.
#
# ★★★ WHAT IT IS NOT. A hit is not a defect and not a work item — it is a note to
# RE-READ. The premise may have been about something else the same name is attached
# to, the arm may be genuinely unreachable for a second reason the note also gives,
# and a name can be defined here with a narrower signature than the site needs (slice
# 139's `create_deferred_type_reference` had two of the reference's four parameters).
# The output is therefore ranked by nothing and says only: this claim mentions a
# function that exists.
#
# ★★★ AND ITS BLIND SPOT IS THE SHARPEST CASE OF ALL. Slice 139 retired two stops
# whose note named `getOptionalExpressionType` as absent — and the PORT of it sat four
# thousand lines below, so this scan finds those. It does NOT find a note whose premise
# is about a TYPE, a FLAG, a producer ("nothing here mints an intersection") or a
# reachability claim; those still need the reading. Of the seven premises slice 139
# expired, this scan named five.
#
# ★★★ THE `tags` MODE IS THE OTHER HALF OF THAT BLIND SPOT, AND SLICE 142 PAID FOR IT.
# `mark-node-assignments` sat at +77 units on frontier.sh with a note calling the walk
# behind it *"a slice of its own"* — and the whole family (markNodeAssignments,
# ensureAssignmentsMarked, extendAssignmentPosition, the per-symbol link) had been in
# the file since slice 100, four thousand lines above. The mode above cannot see it:
# the note names no absent CALLEE, it names an amount of WORK, and there is no camel
# case in it to test. What IS testable is the stop's own TAG — a tag is written as the
# name of the thing that is missing, so `<tag>` snake-cased is a function name, and a
# tag naming a function DEFINED SOMEWHERE ELSE IN THE FILE is a claim to re-read.
#
# ★★ IT IS NOISIER THAN THE FIRST MODE BY CONSTRUCTION and that is not a defect: the
# ordinary shape is a stop INSIDE a partly-ported function tagged with that function's
# own name, so only stops whose enclosing function DIFFERS from the tag are printed —
# and even then the callee named is usually present but incomplete. 75 rows on
# 2026-09-04, of which `mark-node-assignments` was one. A hit is a note to re-read.
#
# Usage:  packages/tscaly/tools/expiredstops.py [file.scaly] [tags]
#         (default: 0.1.2/tscaly/checker.scaly, relative to the package;
#          the second argument selects the TAG mode instead of the claim mode)

import io
import os
import re
import sys

CLAIM = re.compile(
    r"unreachable|is DEAD|dead here|has no subject|nothing in this port"
    r"|this port (?:does not have|has no)|not ported|no producer|no writer"
    r"|does not exist|neither of which exists|has none of",
    re.I,
)
CAMEL = re.compile(r"\b([a-z][a-zA-Z0-9]{4,})\b")
DEFN = re.compile(r"^\s*(?:function|procedure)\s+([a-z_][a-z0-9_]*)", re.M)
STOP = re.compile(r'record_unported\("([^"]+)"')


def snake(name):
    s = re.sub(r"(.)([A-Z][a-z]+)", r"\1_\2", name)
    return re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", s).lower()


def tag_mode(root, path, src, lines):
    """The stop's TAG, read as the name of the thing that is missing."""
    at, cur = {}, None
    enclosing = []
    for line in lines:
        m = re.match(r"^\s*(?:function|procedure)\s+([a-z_][a-z0-9_]*)", line)
        if m:
            cur = m.group(1)
            at.setdefault(cur, len(enclosing) + 1)
        enclosing.append(cur)
    hits = []
    for i, line in enumerate(lines):
        m = STOP.search(line)
        if not m:
            continue
        name = m.group(1).replace("-", "_")
        if name in at and enclosing[i] != name:
            hits.append((i + 1, m.group(1), enclosing[i] or "?", at[name]))
    rel = os.path.relpath(path, root)
    print("expiredstops (tags) — stops whose TAG names a function defined ELSEWHERE")
    print("  file            %s" % rel)
    print("  stops           %d" % len(STOP.findall(src)))
    print("  TO RE-READ      %d" % len(hits))
    print()
    for ln, tag, enc, d in hits:
        print("  %s:%d  %-44s in %-44s (defined at %d)" % (rel, ln, tag, enc, d))
    print()
    print("  ★ A hit is a note to RE-READ, never a work item — the named function is")
    print("    usually present but INCOMPLETE, which is a legitimate stop. What the")
    print("    mode exists for is the other case: the callee is whole and the note")
    print("    aged (slice 142's `mark-node-assignments`, ported forty slices earlier).")


def main():
    root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
    args = [a for a in sys.argv[1:]]
    mode = "claims"
    if args and args[-1] in ("tags", "claims"):
        mode = args.pop()
    path = args[0] if args else os.path.join(root, "0.1.2/tscaly/checker.scaly")
    src = io.open(path, encoding="utf-8").read()
    lines = src.split("\n")
    defined = set(DEFN.findall(src))

    if mode == "tags":
        tag_mode(root, path, src, lines)
        return

    hits = []
    for i, line in enumerate(lines):
        m = STOP.search(line)
        if not m:
            continue
        # The note is the comment block immediately above the stop.
        j, buf = i - 1, []
        while j >= 0 and (lines[j].strip().startswith(";") or lines[j].strip() == ""):
            buf.append(lines[j])
            j -= 1
            if len(buf) > 20:
                break
        note = "\n".join(reversed(buf))
        if not CLAIM.search(note):
            continue
        named = set()
        for cand in CAMEL.findall(note):
            if not any(ch.isupper() for ch in cand):
                continue  # a plain word, not a Go identifier
            if snake(cand) in defined:
                named.add(cand)
        if named:
            hits.append((i + 1, m.group(1), sorted(named)))

    print("expiredstops — stops whose CLAIM names a callee this file DEFINES")
    print("  file            %s" % os.path.relpath(path, root))
    print("  stops           %d" % len(STOP.findall(src)))
    print("  claim-shaped    %d" % sum(
        1 for i, l in enumerate(lines) if STOP.search(l)
        and CLAIM.search("\n".join(lines[max(0, i - 20):i]))))
    print("  TO RE-READ      %d" % len(hits))
    print()
    for ln, tag, named in hits:
        print("  %s:%d  %-46s %s" % (os.path.relpath(path, root), ln, tag, ", ".join(named)))
    print()
    print("  ★ A hit is a note to RE-READ, never a work item: read the note, then the")
    print("    reference, then the port's signature. See the header for the blind spot.")


if __name__ == "__main__":
    main()
