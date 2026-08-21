#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
#
# triage.py — read a run's ARTIFACT TREE and say what the next slice is.
#
# ★★★ WHY THIS EXISTS. Stage 1's report is a verdict: 834/834/834 and OK. Stage 2's
# is a work list — 17 604 units, and a count of failures is not a plan. This script
# turns the tree `run.sh` left behind into two histograms:
#
#   the UNPORTED histogram   which of the eleven `unported` markers the corpus
#                            actually reaches, and how often. CLAUDE.md's §3.5
#                            entries say the next slice is READ off this column;
#                            until stage 2 there was nothing to read.
#   the MISMATCH histogram   for every failing artifact, the FIRST line where our
#                            dump and the reference's disagree, named by the
#                            reference's own kind NAME. A hundred failures with one
#                            signature are one defect.
#
# ★ IT READS THE TREE, NOT A SIDE CHANNEL. Everything here comes out of
# `tests/out/cases/<case>/<idx>/<art>.{ours,ref,ref.cut}` plus `failures.txt`, which
# are the artifacts the runner already writes. So triage cannot disagree with the
# run: there is no second copy of the comparison to drift.
#
# ★★★ AND IT MAKES ITS OWN COMPARISON RATHER THAN READING `<art>.diff`. That file is
# `diff <art>.ref <art>.ours` — the ref UNCUT, so its every line carries the kind
# NAME column our side does not emit and the whole file is one hunk (`1,20c1,19`).
# It is the right artifact for a human, who wants the names, and useless for
# grouping. Here the comparison is `.ref.cut` against `.ours`, which is exactly what
# the runner's verdict rests on, and the NAME is then looked up at that line in
# `.ref`. Reading the hunk header instead would have grouped by line number.
#
# Usage:  packages/tscaly/tests/triage.py [--out DIR] [--top N] [--examples N]

import collections
import os
import sys

ARTS = ("tokens", "ast", "jsdoc", "symbols", "types")

# ★ The symbols dump has NO trailing name column, so "the last field" would answer
# an escaped symbol NAME on some lines and a bare number on others — the very trap
# kind_name's docstring records. Its records are self-naming instead: the first
# field says which of them a line is.
_SYMBOL_RECORDS = {
    b"n": "node with a symbol or locals",
    b"s": "symbol",
    b"d": "declaration of a symbol",
    b"x": "export symbol",
    b"t": "symbol table",
    b"e": "symbol table entry",
    b"f": "file totals (symbolCount/classifiable)",
    b"c": "classifiable name",
}


def read(path):
    try:
        with open(path, "rb") as fh:
            return fh.read()
    except OSError:
        return None


def lines(data):
    if not data:
        return []
    return data.split(b"\n")[:-1] if data.endswith(b"\n") else data.split(b"\n")


def kind_name(ref_lines, i, art="ast"):
    """The reference's own name for whatever sits on its line i.

    The dump is `depth kind pos end flags name` for ast/jsdoc and
    `kind start end flags name` for tokens — in both the name is the LAST field,
    which is why this does not need to know which yardstick it is reading.

    ★ EXCEPT FOR THE DIAGNOSTICS, and reading them as tree lines is what the first
    draft did: a `D <pos> <end> <code>` line has no name column, so "the last
    field" answered the CODE and the histogram grew classes called `1084` and
    `1472`. Those are TS error numbers, i.e. the most identifying thing in the
    whole dump — a signature that prints a number where it promised a name is a
    signature that has stopped describing its own subject.
    """
    if i >= len(ref_lines):
        return "<past end of the reference dump>"
    parts = ref_lines[i].split(b" ")
    if art == "symbols":
        if parts and parts[0] == b"B":
            code = parts[-1].decode("utf-8", "replace")
            return f"bind diagnostic TS{code}"
        return _SYMBOL_RECORDS.get(parts[0] if parts else b"", "<unknown record>")
    # ★ The types dump is self-naming the same way and for the same reason: a `C`
    # line ends in an error NUMBER and a `T` line in a type NAME, so "the last
    # field" would mean two different things. The record letter decides, and a
    # diagnostic keeps its code because that is the identifying half of it.
    if art == "types":
        if parts and parts[0] == b"C":
            code = parts[-1].decode("utf-8", "replace")
            return f"check diagnostic TS{code}"
        if parts and parts[0] == b"T":
            return "type of a node"
        return "<unknown record>"
    if parts and parts[0] == b"D":
        code = parts[-1].decode("utf-8", "replace")
        return f"diagnostic TS{code}"
    return parts[-1].decode("utf-8", "replace") if len(parts) >= 2 else "<no name column>"


def first_difference(ref_cut, ours, ref, art="ast"):
    """A signature for the first line where the two dumps disagree.

    The DIRECTION is part of the signature and is the half that names the defect:
    a line the reference has and we do not is a construct we drop, the reverse is
    one we invent, and a line both have with different numbers is a span or a flag.
    """
    a, b = lines(ref_cut), lines(ours)
    rl = lines(ref)
    n = min(len(a), len(b))
    # ★ THE LINE NUMBER IS DELIBERATELY NOT IN THE SIGNATURE. It is per-unit, so
    # including it would give every failure its own class and turn the histogram
    # back into the list it exists to summarise. The unit is in the examples.
    for i in range(n):
        if a[i] != b[i]:
            name = kind_name(rl, i, art)
            fa, fb = a[i].split(b" "), b[i].split(b" ")
            if len(fa) != len(fb):
                return f"malformed line at {name} — {len(fb)} fields, expected {len(fa)}"
            if fa[:2] == fb[:2]:
                return f"same node, different span or flags: {name}"
            return f"different node where the reference has {name}"
    if len(a) > len(b):
        return f"ours ENDS EARLY — the reference continues with {kind_name(rl, n, art)}"
    if len(b) > len(a):
        return "ours has EXTRA lines past the reference's end"
    return "<no difference found — the runner and this script disagree, which is a bug>"


def histogram(title, counts, examples, top, nex):
    total = sum(counts.values())
    print(f"\n{title} — {total} in {len(counts)} classes")
    if not counts:
        return
    for sig, n in counts.most_common(top):
        print(f"  {n:6d}  {sig}")
        for ex in examples[sig][:nex]:
            print(f"          {ex}")
    rest = len(counts) - top
    if rest > 0:
        print(f"  … {rest} further classes, {total - sum(n for _, n in counts.most_common(top))} entries")


def main(argv):
    out = "packages/tscaly/tests/out"
    top, nex = 25, 2
    i = 1
    while i < len(argv):
        if argv[i] == "--out":
            out = argv[i + 1]; i += 2
        elif argv[i] == "--top":
            top = int(argv[i + 1]); i += 2
        elif argv[i] == "--examples":
            nex = int(argv[i + 1]); i += 2
        else:
            print(f"triage.py: unknown argument {argv[i]!r}", file=sys.stderr)
            return 2
    cases_dir = os.path.join(out, "cases")
    if not os.path.isdir(cases_dir):
        print(f"triage.py: no artifact tree at {cases_dir} — run tests/run.sh first.",
              file=sys.stderr)
        return 2

    counters = {}
    cpath = os.path.join(out, "counters.sh")
    if os.path.isfile(cpath):
        for ln in open(cpath):
            k, _, v = ln.strip().partition("=")
            if v.isdigit():
                counters[k] = int(v)

    print("=" * 78)
    print("triage of", cases_dir)
    if counters:
        print("  a run of {} cases: matched {}/{}/{}/{}/{}  unported {}/{}/{}/{}/{}"
              "  UNEXPLAINED {}/{}/{}/{}/{}   (tokens/ast/jsdoc/symbols/types)".format(
                  counters.get("cases_seen", 0),
                  counters.get("matched_tokens", 0), counters.get("matched_ast", 0),
                  counters.get("matched_jsdoc", 0), counters.get("matched_symbols", 0),
                  counters.get("matched_types", 0),
                  counters.get("unported_tokens", 0), counters.get("unported_ast", 0),
                  counters.get("unported_jsdoc", 0), counters.get("unported_symbols", 0),
                  counters.get("unported_types", 0),
                  counters.get("failed_tokens", 0), counters.get("failed_ast", 0),
                  counters.get("failed_jsdoc", 0), counters.get("failed_symbols", 0),
                  counters.get("failed_types", 0)))
    print("=" * 78)

    unported = {a: collections.Counter() for a in ARTS}
    un_ex = {a: collections.defaultdict(list) for a in ARTS}
    mismatch = {a: collections.Counter() for a in ARTS}
    mm_ex = {a: collections.defaultdict(list) for a in ARTS}
    crash = collections.Counter()
    crash_ex = collections.defaultdict(list)

    for case in sorted(os.listdir(cases_dir)):
        cdir = os.path.join(cases_dir, case)
        if not os.path.isdir(cdir):
            continue
        for idx in sorted(os.listdir(cdir)):
            udir = os.path.join(cdir, idx)
            if not idx.isdigit() or not os.path.isdir(udir):
                continue
            where = case if idx == "0" else f"{case}[{idx}]"
            for art in ARTS:
                ours = read(os.path.join(udir, f"{art}.ours"))
                if ours is None:
                    continue
                if ours.startswith(b"UNPORTED "):
                    # `UNPORTED <pos> <tag> <detail>` — the TAG is the class and the
                    # DETAIL is usually a kind number, which is the construct.
                    parts = ours.split(b"\n", 1)[0].split(b" ")
                    tag = parts[2].decode() if len(parts) > 2 else "<no tag>"
                    detail = parts[3].decode() if len(parts) > 3 else ""
                    sig = f"{tag} (detail {detail})" if detail not in ("", "0") else tag
                    unported[art][sig] += 1
                    un_ex[art][sig].append(where)
                    continue
                if not os.path.exists(os.path.join(udir, f"{art}.diff")):
                    continue          # matched, accepted, or reported through failures.txt
                ref_cut = read(os.path.join(udir, f"{art}.ref.cut"))
                ref = read(os.path.join(udir, f"{art}.ref"))
                sig = first_difference(ref_cut, ours, ref, art)
                mismatch[art][sig] += 1
                mm_ex[art][sig].append(where)

    # The classes that never produce a `.diff` — a dumper that exited, a splitter
    # that failed, a timeout — exist only in the runner's own failure list. They are
    # separated by SHAPE, with the case key stripped off so the shape can group.
    fpath = os.path.join(out, "failures.txt")
    for ln in (open(fpath, errors="surrogateescape") if os.path.isfile(fpath) else []):
        ln = ln.rstrip("\n")
        if not ln:
            continue
        head, _, msg = ln.partition(": ")
        art = head.split("/", 1)[0]
        if "exited" in msg or "timed out" in msg or "no-tree" in msg:
            crash[f"{art}: {msg}"] += 1
            crash_ex[f"{art}: {msg}"].append(head.split("/", 1)[-1])

    for art in ARTS:
        histogram(f"UNPORTED — {art} yardstick", unported[art], un_ex[art], top, nex)
    for art in ARTS:
        histogram(f"MISMATCH — {art} yardstick", mismatch[art], mm_ex[art], top, nex)
    histogram("DUMPER/SPLITTER failures (no diff artifact exists for these)",
              crash, crash_ex, top, nex)
    print()
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
