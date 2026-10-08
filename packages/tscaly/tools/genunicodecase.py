#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
#
# genunicodecase.py — generate tscaly/UnicodeCase.scaly, the two Unicode case
# functions the spelling suggestion needs.
#
# ★★★ THE AUTHORITY HERE IS THE GO TOOLCHAIN, NOT THE SUBMODULE, and that is a
# statement about the reference rather than a shortcut. `GetSpellingSuggestion`
# calls `unicode.ToLower` and `strings.EqualFold` — Go's own simple case mapping
# and simple case folding — so what the reference ANSWERS is what the Go
# standard library's tables say. The submodule carries no copy of them
# (`stringutil`'s tables are the ECMAScript SPECIAL casing, a different function
# with multi-rune mappings, and JsCase.scaly is that one). Asking Go directly is
# therefore the only way to generate a table that agrees with the reference on
# every code point rather than on the ones a test happens to reach.
#
# ★ IT FOLLOWS THAT A GO TOOLCHAIN BUMP IS A PIN BUMP: re-run this generator
# after one, the same way a submodule bump re-runs genjscase.py. The header of
# the generated file records the Unicode version Go reports.
#
# ★★ THE TABLES ARE FLAT PAIR ARRAYS AND NOT RANGES, unlike genunicode.py's.
# Ranges there compress because an identifier property is a predicate over long
# spans; a case MAPPING is a function, and its deltas alternate every other code
# point through most of Latin Extended (the `UpperLower` pattern in Go's own
# CaseRanges). A range encoding would carry a stride AND a delta per row and buy
# little, while a wrong stride is the silent class genunicode.py's header warns
# about. 1 433 + 2 878 pairs is 8 622 integers; the search is the same binary
# search either way.
#
# ★★★ AND THE GENERATOR VERIFIES ITSELF OVER THE WHOLE CODE SPACE: after
# building the pairs it re-derives both functions from them and compares against
# Go's answer for all 1 114 112 code points. A table that is merely SORTED is not
# a table that is right.
#
# Usage (from the repo root, a Go toolchain on PATH):
#   packages/tscaly/tools/genunicodecase.py

import io
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
PKG = os.path.dirname(HERE)
REPO = os.path.dirname(os.path.dirname(PKG))
DST = os.path.join(PKG, "0.1.1", "tscaly", "UnicodeCase.scaly")

PROBE = r'''
package main

import (
	"bufio"
	"fmt"
	"os"
	"unicode"
)

func main() {
	w := bufio.NewWriter(os.Stdout)
	defer w.Flush()
	fmt.Fprintf(w, "V %s\n", unicode.Version)
	for r := rune(0); r <= 0x10FFFF; r++ {
		if l := unicode.ToLower(r); l != r {
			fmt.Fprintf(w, "L %d %d\n", r, l)
		}
		if f := unicode.SimpleFold(r); f != r {
			fmt.Fprintf(w, "F %d %d\n", r, f)
		}
	}
}
'''


def ask_go():
    """Run the probe under the host's Go toolchain and return (version, lower, fold)."""
    with tempfile.TemporaryDirectory(prefix="tscaly-unicase") as d:
        io.open(os.path.join(d, "main.go"), "w", encoding="utf-8").write(PROBE)
        io.open(os.path.join(d, "go.mod"), "w", encoding="utf-8").write(
            "module unicase\n\ngo 1.21\n")
        try:
            proc = subprocess.run(["go", "run", "."], cwd=d, check=False,
                                  stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        except OSError as e:
            sys.exit("genunicodecase: no Go toolchain on PATH (%s) — the tables' "
                     "authority is unicode.ToLower/unicode.SimpleFold and there is "
                     "no second source for them" % e)
        if proc.returncode != 0:
            sys.exit("genunicodecase: the probe did not run:\n%s"
                     % proc.stderr.decode("utf-8", "replace"))
    version = ""
    lower = []
    fold = []
    for line in proc.stdout.decode("ascii").split("\n"):
        if not line:
            continue
        parts = line.split()
        if parts[0] == "V":
            version = parts[1]
        elif parts[0] == "L":
            lower.append((int(parts[1]), int(parts[2])))
        elif parts[0] == "F":
            fold.append((int(parts[1]), int(parts[2])))
    if not version or not lower or not fold:
        sys.exit("genunicodecase: the probe answered nothing — Go's unicode package changed")
    return version, lower, fold


def check_sorted(name, pairs):
    for i in range(1, len(pairs)):
        if pairs[i][0] <= pairs[i - 1][0]:
            sys.exit("genunicodecase: %s is not ascending at 0x%X — binary search invalid"
                     % (name, pairs[i][0]))
    for cp, to in pairs:
        # A const array literal takes BARE integers only: a negative element folds
        # to several elements and shifts the tail.
        if cp < 0 or to < 0:
            sys.exit("genunicodecase: a negative element in %s" % name)


def verify(lower, fold):
    """Re-derive both functions from the pairs and compare against the probe."""
    lmap = dict(lower)
    fmap = dict(fold)

    def search(pairs, cp):
        lo, hi = 0, len(pairs) - 1
        while lo <= hi:
            mid = (lo + hi) // 2
            if cp < pairs[mid][0]:
                hi = mid - 1
            elif cp > pairs[mid][0]:
                lo = mid + 1
            else:
                return pairs[mid][1]
        return cp

    for cp in range(0x110000):
        if search(lower, cp) != lmap.get(cp, cp):
            sys.exit("genunicodecase: ToLower disagrees at 0x%X" % cp)
        if search(fold, cp) != fmap.get(cp, cp):
            sys.exit("genunicodecase: SimpleFold disagrees at 0x%X" % cp)


def emit_array(out, name, values):
    """One row of twelve, and EVERY row ends with a comma — the last one too.

    ★★★ THE TRAILING COMMA IS LOAD-BEARING AND ITS ABSENCE IS REPORTED AT THE
    OPENING BRACKET — a trap this generator's first draft walked
    into anyway. An LF separates constructs in Scaly, so an element followed by a
    newline ends the element list and the `]` on the next line is orphaned:
    `define X: int[] [` ... `0x37F` NEWLINE `]` fails as `expected ']'` at the
    line of the DEFINE, column of its `[`, which points at a bracket that is
    perfectly well formed.
    """
    out.append("define %s: int[] [" % name)
    row = []
    for v in values:
        row.append("0x%X" % v)
        if len(row) == 12:
            out.append("    " + ", ".join(row) + ",")
            row = []
    if row:
        out.append("    " + ", ".join(row) + ",")
    out.append("]")
    out.append("")


def emit_search(out, fn, prefix, comment):
    out.append(comment)
    out.append("function %s(cp: int) returns int" % fn)
    out.append("{")
    out.append("    var lo: int 0")
    out.append("    var hi: int %d" % (PREFIX_LEN[prefix] - 1))
    out.append("    while lo <= hi")
    out.append("    {")
    out.append("        let mid (lo + hi) / 2")
    out.append("        if cp < %s_CP[mid]" % prefix)
    out.append("            hi := mid - 1")
    out.append("        else")
    out.append("        {")
    out.append("            if cp > %s_CP[mid]" % prefix)
    out.append("                lo := mid + 1")
    out.append("            else")
    out.append("                return %s_TO[mid]" % prefix)
    out.append("        }")
    out.append("    }")
    out.append("    cp")
    out.append("}")
    out.append("")


PREFIX_LEN = {}


def main():
    version, lower, fold = ask_go()
    check_sorted("UCASE_LOWER", lower)
    check_sorted("UCASE_FOLD", fold)
    verify(lower, fold)
    PREFIX_LEN["UCASE_LOWER"] = len(lower)
    PREFIX_LEN["UCASE_FOLD"] = len(fold)

    out = []
    a = out.append
    a("; SPDX-License-Identifier: Apache-2.0")
    a(";")
    a("; UnicodeCase — `unicode.ToLower` and `unicode.SimpleFold`, the two Go")
    a("; standard-library functions core.GetSpellingSuggestion is written on:")
    a("; levenshteinWithMax charges a case-only substitution 0.1 instead of 2 and")
    a("; strings.EqualFold decides the candidates shorter than three bytes.")
    a(";")
    a("; GENERATED by packages/tscaly/tools/genunicodecase.py. Do not edit; edit the")
    a("; generator. Regenerate after a GO TOOLCHAIN bump — these tables come from the")
    a("; toolchain and not from the submodule, because the reference's answer is")
    a("; whatever Go's unicode package says. Unicode %s at generation time." % version)
    a(";")
    a("; ★★★ THIS IS NOT JsCase.scaly AND THE TWO MUST NOT BE SUBSTITUTED FOR EACH")
    a("; OTHER. That one is the ECMAScript SPECIAL casing the `Lowercase<T>`")
    a("; intrinsic is defined by — a different function, with multi-rune mappings")
    a("; and a Final_Sigma condition. These are the SIMPLE mappings, one rune to one")
    a("; rune, and they are what a spelling distance is measured with.")
    a(";")
    a("; ★ A pair array rather than ranges: a case mapping's delta alternates every")
    a("; other code point through Latin Extended, so a range encoding would carry a")
    a("; stride per row and buy little. The generator verifies both functions")
    a("; against Go over all 1 114 112 code points before writing.")
    a("")
    a("; %d code points whose simple lowercase differs from themselves." % len(lower))
    emit_array(out, "UCASE_LOWER_CP", [cp for cp, _ in lower])
    emit_array(out, "UCASE_LOWER_TO", [to for _, to in lower])
    a("; %d code points whose SimpleFold orbit successor differs from themselves." % len(fold))
    emit_array(out, "UCASE_FOLD_CP", [cp for cp, _ in fold])
    emit_array(out, "UCASE_FOLD_TO", [to for _, to in fold])
    emit_search(out, "unicode_to_lower", "UCASE_LOWER",
                "; unicode.ToLower — the simple lowercase mapping, identity where absent.")
    emit_search(out, "unicode_simple_fold", "UCASE_FOLD",
                "; unicode.SimpleFold — the NEXT code point of the case orbit, wrapping\n"
                "; back to the smallest; identity for a code point in no orbit.")

    io.open(DST, "w", encoding="utf-8").write("\n".join(out) + "\n")
    print("genunicodecase: Unicode %s, %d ToLower pairs, %d SimpleFold pairs"
          % (version, len(lower), len(fold)))
    print("                -> %s" % os.path.relpath(DST, REPO))


main()
