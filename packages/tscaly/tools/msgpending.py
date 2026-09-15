#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""
msgpending.py [--file checker.scaly] [--member NAME] [--codes 1,2] — phase (b)1's worklist:
the port's report sites naming a message with placeholders whose line passes no argument
after the code (`Diag…)` closes the call, or the code is stored into a variable), each
beside the reference's calls in the same-named function (snake_case → camelCase) that name
a message of that function. Heuristic by design: a site whose arguments are computed on the
line before, or passed through a variable code, still shows and is judged by reading.
"""
import argparse, glob, os, re, collections

HERE = os.path.dirname(os.path.abspath(__file__))
PKG = os.path.dirname(HERE)
REF = os.path.join(PKG, "_submodules", "typescript-go", "internal")

gen = open(os.path.join(REF, "diagnostics", "diagnostics_generated.go")).read()
texts = {}
codes = {}
for m in re.finditer(r'^var (\w+) = &Message\{code: (\d+),.*?text: "((?:[^"\\]|\\.)*)"', gen, re.M):
    texts[m.group(1)] = m.group(3)
    codes[m.group(1)] = int(m.group(2))

DEF_RE = re.compile(r"^    (?:function|procedure) ([A-Za-z_0-9]+)\(")
GODEF_RE = re.compile(r"^func (?:\([^)]*\) )?(\w+)\(")


def camel(name):
    parts = name.split("_")
    return parts[0] + "".join(p[:1].upper() + p[1:] for p in parts[1:])


def ref_functions():
    out = collections.defaultdict(list)
    for f in sorted(glob.glob(os.path.join(REF, "*", "*.go"))):
        if f.endswith("_test.go") or "diagnostics_generated" in f or "/ls/" in f or "/lsp/" in f or "/fourslash/" in f:
            continue
        lines = open(f).read().split("\n")
        func = None
        for i, line in enumerate(lines):
            m = GODEF_RE.match(line)
            if m:
                func = m.group(1)
            if func and re.search(r"(?<!\.)\bdiagnostics\.\w+", line):
                out[func.lower()].append("%s:%d | %s" % (os.path.relpath(f, REF), i + 1, line.strip()))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--file", default="")
    ap.add_argument("--member", default="")
    ap.add_argument("--codes", default="")
    ap.add_argument("--summary", action="store_true")
    args = ap.parse_args()
    want = set(int(c) for c in args.codes.split(",") if c)
    refs = ref_functions()
    files = sorted(glob.glob(os.path.join(PKG, "0.1.0", "tscaly", "*.scaly")))
    per_member = collections.OrderedDict()
    for f in files:
        base = os.path.basename(f)
        if base == "DiagnosticCodes.scaly" or (args.file and base != args.file):
            continue
        member = "?"
        for i, line in enumerate(open(f).read().split("\n")):
            m = DEF_RE.match(line)
            if m:
                member = m.group(1)
            code = line.split(";")[0]
            for dm in re.finditer(r"\bDiag([A-Z]\w*)\b(\s*\))?", code):
                name = dm.group(1)
                if name not in texts or "{0}" not in texts[name]:
                    continue
                closes = dm.group(2) is not None
                stored = re.search(r"\bset \w+: Diag%s\b|\bvar \w+ Diag%s\b" % (name, name), code) is not None
                if not closes and not stored:
                    continue
                if want and codes[name] not in want:
                    continue
                if args.member and member != args.member:
                    continue
                per_member.setdefault((base, member), []).append((i + 1, name, line.strip()))
    total = 0
    for (base, member), sites in per_member.items():
        total += len(sites)
        if args.summary:
            continue
        print("=== %s %s" % (base, member))
        for ln, name, text in sites:
            print("  %d TS%d | %s" % (ln, codes[name], text))
        for r in refs.get(camel(member).lower(), []):
            print("    ref " + r)
    print("pending sites:", total, "members:", len(per_member))


if __name__ == "__main__":
    main()
