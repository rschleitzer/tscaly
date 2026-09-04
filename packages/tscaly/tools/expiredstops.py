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
# Usage:  packages/tscaly/tools/expiredstops.py [file.scaly]
#         (default: 0.1.0/tscaly/checker.scaly, relative to the package)

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


def main():
    root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
    path = sys.argv[1] if len(sys.argv) > 1 else os.path.join(root, "0.1.0/tscaly/checker.scaly")
    src = io.open(path, encoding="utf-8").read()
    lines = src.split("\n")
    defined = set(DEFN.findall(src))

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
