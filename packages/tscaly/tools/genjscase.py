#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
#
# genjscase.py — generate tscaly/JsCase.scaly from the reference's JS casing
# tables (internal/stringutil/js_case_generated.go).
#
# Those tables are themselves generated upstream from @unicode/unicode-15.1.0
# ("DO NOT EDIT") and they are the WHOLE of the case mapping: ToUpperJS and
# ToLowerJS write a rune UNCHANGED when it is not in specialCasingMappings, so
# there is no `unicode.ToUpper` fallback to fall back to. A hand-written table
# would therefore not be an approximation of the reference, it would be a
# different function.
#
# ── Three structural facts, MEASURED rather than assumed:
#
# (1) 5751 of the 5854 mappings are ONE rune; 87 are two and 16 are three. So a
#     mapping is stored as its rune where it is one, and as `0 - (index + 1)`
#     into a flattened multi-rune pool where it is not. The generator refuses to
#     emit if a mapping ever exceeds MULTI_MAX runes.
# (2) Exactly ONE entry carries a condition (U+03A3, the Final_Sigma sigma). It
#     is still emitted as a PAIR OF ARRAYS rather than as two constants, so a pin
#     bump that adds a second conditional mapping needs no code change here — but
#     the generator prints the count, because a silent growth from one to many
#     would change how expensive `js_case_conditional_lower` is.
# (3) unicodeCasedRanges and unicodeCaseIgnorableRanges are Go RangeTables in the
#     same R16/R32 shape genunicode.py already reads, with the same two
#     properties it checks: each half sorted, the halves disjoint. They are
#     concatenated into one ascending array and searched once.
#
# ★ The Final_Sigma context is what makes the lower-case direction more than a
# table lookup: a sigma preceded by a cased code point and not followed by one
# lowercases to U+03C2 rather than U+03C3. Both range tables exist only for that
# question.

import io
import os
import re
import sys

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
SRC = os.path.join(
    REPO,
    "packages/tscaly/_submodules/typescript-go/internal/stringutil/"
    "js_case_generated.go",
)
DST = os.path.join(REPO, "packages/tscaly/0.1.1/tscaly/JsCase.scaly")

MULTI_MAX = 4

# ★★★ THE POOL INDEX IS BIASED ABOVE THE LAST CODE POINT INSTEAD OF NEGATED, AND
# IT HAS TO BE: a NEGATIVE element in a const array literal is not one element.
# `define T: int[] [0x10, 0 - 0x5, 0x30]` emits `[3 x i64] [16, 0, 5]` — the
# `0 - 0x5` becomes TWO elements and the tail is dropped to keep the declared
# width — at rc 0 with no diagnostic. Every mapping after the first multi-rune one
# was shifted by one, so `Lowercase<"Ο">` answered `ξ`; the first version of this
# generator emitted exactly that and only the corpus said so. Minimal repro in the
# slice-171 narrative.
MULTI_BASE = 0x200000

ENTRY = re.compile(r'^\t0x([0-9A-Fa-f]+):\s*\{(.*)\},\s*$', re.M)
FIELD = re.compile(r'(\w+):\s*"((?:[^"\\]|\\.)*)"')
COND = re.compile(r'condition:\s*specialCasingCondition(\w+)')
RANGE = re.compile(r"\{0x([0-9A-Fa-f]+), 0x([0-9A-Fa-f]+), (\d+)\}")

RANGE_TABLES = [
    ("unicodeCasedRanges", "JSCASE_CASED", "js_case_is_cased"),
    ("unicodeCaseIgnorableRanges", "JSCASE_IGNORABLE", "js_case_is_case_ignorable"),
]


def read_mappings(text):
    rows = []
    for m in ENTRY.finditer(text):
        cp = int(m.group(1), 16)
        body = m.group(2)
        d = {k: eval('"%s"' % v) for k, v in FIELD.findall(body)}
        c = COND.search(body)
        if not c:
            sys.exit("genjscase: entry 0x%X has no condition field" % cp)
        rows.append((cp, d.get("lower", ""), d.get("upper", ""),
                     d.get("conditionalLower", ""), c.group(1)))
    if not rows:
        sys.exit("genjscase: specialCasingMappings parsed as empty — the reference changed")
    rows.sort(key=lambda r: r[0])
    return rows


def read_range_table(text, var):
    try:
        i = text.index("var %s = &unicode.RangeTable{" % var)
    except ValueError:
        sys.exit("genjscase: table %s not found — the reference changed" % var)
    j = text.index("\n}\n", i)
    body = text[i:j]
    out = []
    for section, width in (("R16", "16"), ("R32", "32")):
        m = re.search(r"%s: \[\]unicode\.Range%s\{(.*?)\n\t\}," % (section, width), body, re.S)
        if not m:
            continue
        part = [(int(a, 16), int(b, 16), int(s)) for a, b, s in RANGE.findall(m.group(1))]
        if not part:
            continue
        if any(part[k][0] > part[k + 1][0] for k in range(len(part) - 1)):
            sys.exit("genjscase: %s.%s is not sorted — binary search invalid" % (var, section))
        if out and part[0][0] <= out[-1][1]:
            sys.exit(
                "genjscase: %s R16/R32 overlap (last Hi 0x%X, first Lo 0x%X) — "
                "merging them is no longer equivalent to unicode.Is"
                % (var, out[-1][1], part[0][0]))
        out.extend(part)
    if not out:
        sys.exit("genjscase: %s parsed as empty" % var)
    return out


def array(name, values):
    # `int[]` — a const array global is an [N x T] VALUE and is indexed in place;
    # the trailing comma after the last element is REQUIRED for a multi-line
    # literal (genunicode.py carries the same note and the measurement behind it).
    lines = ["define %s: int[] [" % name]
    row = []
    for v in values:
        if v < 0:
            sys.exit("genjscase: a negative element in a const array literal is "
                     "silently TWO elements — see MULTI_BASE")
        row.append("0x%X" % v)
        if len(row) == 12:
            lines.append("    " + ", ".join(row) + ",")
            row = []
    if row:
        lines.append("    " + ", ".join(row) + ",")
    lines.append("]")
    return lines


def encode(s, pool):
    """One rune as itself; anything longer as 0 - (pool index + 1)."""
    runes = [ord(ch) for ch in s]
    if len(runes) == 0:
        return 0
    if len(runes) == 1:
        if runes[0] == 0:
            sys.exit("genjscase: a mapping is U+0000, which collides with the empty encoding")
        if runes[0] >= MULTI_BASE:
            sys.exit("genjscase: a code point at or above the pool bias 0x%X" % MULTI_BASE)
        return runes[0]
    if len(runes) > MULTI_MAX:
        sys.exit("genjscase: a mapping is %d runes, over MULTI_MAX %d" % (len(runes), MULTI_MAX))
    start = len(pool)
    pool.append(len(runes))
    pool.extend(runes)
    return MULTI_BASE + start


def main():
    if not os.path.exists(SRC):
        sys.exit(
            "genjscase: reference not found at\n  %s\n"
            "Initialize the submodule:\n"
            "  git submodule update --init packages/tscaly/_submodules/typescript-go"
            % SRC)
    text = io.open(SRC, encoding="utf-8").read()

    rows = read_mappings(text)
    pool = []
    cps, lowers, uppers = [], [], []
    cond_cps, cond_lowers = [], []
    for cp, lo, up, clo, cond in rows:
        cps.append(cp)
        lowers.append(encode(lo, pool))
        uppers.append(encode(up, pool))
        if cond == "None":
            if clo:
                sys.exit("genjscase: 0x%X has a conditionalLower with no condition" % cp)
            continue
        if cond != "FinalSigma":
            sys.exit("genjscase: 0x%X carries condition %s, which this port does not "
                     "implement — the reference grew a second casing condition" % (cp, cond))
        cond_cps.append(cp)
        cond_lowers.append(encode(clo, pool))
    if any(cps[k] >= cps[k + 1] for k in range(len(cps) - 1)):
        sys.exit("genjscase: the mapping table is not strictly ascending")

    ranges = {}
    for var, prefix, _ in RANGE_TABLES:
        ranges[prefix] = read_range_table(text, var)

    out = []
    a = out.append
    a("; SPDX-License-Identifier: Apache-2.0")
    a(";")
    a("; JsCase — the ECMAScript case-mapping tables, ported from the reference's")
    a("; internal/stringutil/js_case_generated.go (itself generated from")
    a("; @unicode/unicode-15.1.0) and the two range tables its Final_Sigma context")
    a("; needs.")
    a(";")
    a("; GENERATED by packages/tscaly/tools/genjscase.py. Do not edit; edit the")
    a("; generator. Regenerate after a submodule pin bump.")
    a(";")
    a("; ★★★ THE TABLE IS THE WHOLE MAPPING, NOT A SPECIAL CASE. ToUpperJS and")
    a("; ToLowerJS write a rune UNCHANGED when it is absent from it — there is no")
    a("; library fallback underneath — so `Uppercase<T>` is exactly this table and")
    a("; a hand-written approximation would be a different function.")
    a(";")
    a("; ★ A mapping is stored as its RUNE where it is one code point (%d of %d)"
      % (sum(1 for v in lowers + uppers if v > 0), len(lowers) + len(uppers)))
    a("; and as `0x%X + index` into JSCASE_MULTI otherwise, where the pool holds" % MULTI_BASE)
    a("; a length followed by that many runes. The generator refuses to emit a")
    a("; mapping longer than %d runes." % MULTI_MAX)
    a(";")
    a("; ★ %d of the %d entries carry the Final_Sigma condition; they are a pair of"
      % (len(cond_cps), len(cps)))
    a("; arrays rather than constants so a pin bump that adds one needs no change.")
    a(";")
    a("; ★ THE STRIDE IS LOAD-BEARING in the two range tables, for genunicode.py's")
    a("; own reason: a range with stride N holds every Nth code point of its span")
    a("; and nothing else.")
    a("")
    a("; %d mappings." % len(cps))
    out.extend(array("JSCASE_CP", cps))
    a("")
    out.extend(array("JSCASE_LOWER", lowers))
    a("")
    out.extend(array("JSCASE_UPPER", uppers))
    a("")
    a("; The multi-rune pool: a length, then that many runes.")
    out.extend(array("JSCASE_MULTI", pool))
    a("")
    a("; The conditional (Final_Sigma) mappings.")
    out.extend(array("JSCASE_COND_CP", cond_cps))
    a("")
    out.extend(array("JSCASE_COND_LOWER", cond_lowers))
    a("")

    n = len(cps)
    a("; The index of `c` in JSCASE_CP, or 0 - 1 when it is not mapped.")
    a("function js_case_index(c: int) returns int")
    a("{")
    a("    var lo: int 0")
    a("    var hi: int %d" % (n - 1))
    a("    while lo <= hi")
    a("    {")
    a("        let mid (lo + hi) / 2")
    a("        let k JSCASE_CP[mid]")
    a("        if c < k")
    a("            hi := mid - 1")
    a("        else")
    a("        {")
    a("            if c > k")
    a("                lo := mid + 1")
    a("            else")
    a("                return mid")
    a("        }")
    a("    }")
    a("    0 - 1")
    a("}")
    a("")
    a("; The two mapping columns and the multi-rune pool, read through functions")
    a("; rather than indexed by the caller: a const array global is an [N x T]")
    a("; VALUE and has to be indexed IN PLACE, so every reader of a table lives in")
    a("; the module that declares it (genunicode.py carries the same note).")
    a("function js_case_lower(i: int) returns int")
    a("    JSCASE_LOWER[i]")
    a("")
    a("function js_case_upper(i: int) returns int")
    a("    JSCASE_UPPER[i]")
    a("")
    a("; A mapping code is a RUNE below JSCASE_MULTI_BASE and `JSCASE_MULTI_BASE +")
    a("; start` into JSCASE_MULTI at or above it, where the pool holds a length then")
    a("; that many runes. ★★★THE BIAS IS NOT A NEGATION BECAUSE A NEGATIVE ELEMENT")
    a("; IN A CONST ARRAY LITERAL IS SILENTLY TWO ELEMENTS — see the generator.")
    a("function js_case_multi_base() returns int")
    a("    0x%X" % MULTI_BASE)
    a("")
    a("function js_case_multi_length(start: int) returns int")
    a("    JSCASE_MULTI[start]")
    a("")
    a("function js_case_multi_at(start: int, i: int) returns int")
    a("    JSCASE_MULTI[(start + 1) + i]")
    a("")
    a("; The conditional lower mapping of `c`, or 0 when it has none. A LINEAR scan")
    a("; over %d entries, which is what the measurement above licenses." % len(cond_cps))
    a("function js_case_conditional_lower(c: int) returns int")
    a("{")
    a("    var i: int 0")
    a("    while i < %d" % max(len(cond_cps), 1))
    a("    {")
    if cond_cps:
        a("        if JSCASE_COND_CP[i] = c")
        a("            return JSCASE_COND_LOWER[i]")
    a("        i := i + 1")
    a("    }")
    a("    0")
    a("}")
    a("")

    for var, prefix, fn in RANGE_TABLES:
        rows = ranges[prefix]
        a("; %s — %d ranges." % (var, len(rows)))
        out.extend(array(prefix + "_LO", [r[0] for r in rows]))
        a("")
        out.extend(array(prefix + "_HI", [r[1] for r in rows]))
        a("")
        out.extend(array(prefix + "_STRIDE", [r[2] for r in rows]))
        a("")
        a("function %s(c: int) returns bool" % fn)
        a("{")
        a("    var lo: int 0")
        a("    var hi: int %d" % (len(rows) - 1))
        a("    while lo <= hi")
        a("    {")
        a("        let mid (lo + hi) / 2")
        a("        if c < %s_LO[mid]" % prefix)
        a("            hi := mid - 1")
        a("        else")
        a("        {")
        a("            if c > %s_HI[mid]" % prefix)
        a("                lo := mid + 1")
        a("            else")
        a("            {")
        a("                let st %s_STRIDE[mid]" % prefix)
        a("                if st = 1")
        a("                    return true")
        a("                return ((c - %s_LO[mid]) %% st) = 0" % prefix)
        a("            }")
        a("        }")
        a("    }")
        a("    false")
        a("}")
        a("")

    io.open(DST, "w", encoding="utf-8").write("\n".join(out))
    print("genjscase: %d mappings (%d multi-rune runes pooled), %d conditional, %s"
          % (len(cps), len(pool), len(cond_cps),
             ", ".join("%s %d ranges" % (p, len(ranges[p])) for _, p, _ in RANGE_TABLES)))
    print("           -> %s" % os.path.relpath(DST, REPO))


main()
