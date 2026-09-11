#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
#
# literalview.py — an UNTYPED binding to a string literal, read as a VIEW.
#
# ★★★ WHY THIS EXISTS. A Scaly string literal materialises into a `Slice[char]`
# only where a DECLARED TARGET TYPE is in hand — a typed binding, a `set`, a call
# argument, a return — and the exception is SILENT: `let suffix "Element"` binds a
# `String`, whose buffer carries a varint LENGTH PREFIX. Walk that with
# `*(suffix + i)` or `suffix[i]` and every byte is off by the prefix, at rc 0.
#
# Slice 186 found one: `has_common_dom_type_name`'s HasSuffix, which made every
# `HTML…Element` type name answer false and `missingDomElements` report TS2339
# where the reference reports TS2812 on three of its four sites. `Element` alone
# kept working, because it takes the plain name test above the suffix walk — which
# is why the defect survived: the shape that fails is the one nobody spot-checks.
#
# ★The exit is a PARAMETER: `name_bytes_start_with(name, "HTML")` materialises the
# literal because the parameter declares `Slice[char]`. So the fix is never a cast,
# it is a helper.
#
# Usage:  python3 packages/tscaly/tools/literalview.py
#         Prints one row per suspect binding. Zero is the expected answer, and a
#         zero AGES — re-run it after writing byte-comparison code.

import glob
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
ROOTS = sorted(glob.glob(os.path.join(HERE, "..", "0.1.0", "*.scaly")) +
               glob.glob(os.path.join(HERE, "..", "0.1.0", "tscaly", "*.scaly")))

# An untyped binding — no `:` annotation — whose initializer is a string literal.
BIND = re.compile(r'\s*(?:let|var)\s+([a-z_0-9]+)\s+"')
WINDOW = 40


def main():
    hits = 0
    for path in ROOTS:
        lines = open(path, encoding="utf8").read().splitlines()
        for i, line in enumerate(lines):
            m = BIND.match(line)
            if not m:
                continue
            v = re.escape(m.group(1))
            for k in range(i + 1, min(i + WINDOW, len(lines))):
                use = (re.search(r"\*\(\s*" + v + r"\s*\+", lines[k])
                       or re.search(r"\b" + v + r"\[", lines[k])
                       or re.search(r"\b" + v + r"\.(length|data)\b", lines[k]))
                if use:
                    rel = os.path.relpath(path, os.path.join(HERE, "..", ".."))
                    print("%s:%d: %s" % (rel, i + 1, line.strip()))
                    print("        %d: %s" % (k + 1, lines[k].strip()))
                    hits += 1
                    break
    print("%d untyped string-literal bindings read as a view" % hits)


if __name__ == "__main__":
    main()
