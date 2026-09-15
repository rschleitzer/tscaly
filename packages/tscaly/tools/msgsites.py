#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""
msgsites.py CODE... — for each diagnostic code, the port's report sites (file:line, the
enclosing member, the line) beside the reference's calls naming the same message with the
arguments it passes. Phase (b)1's worklist tool: a site whose line carries fewer arguments
than the message has placeholders is the one to port.
"""
import glob, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
PKG = os.path.dirname(HERE)
REF = os.path.join(PKG, "_submodules", "typescript-go", "internal")

gen = open(os.path.join(REF, "diagnostics", "diagnostics_generated.go")).read()
by_code = {}
for m in re.finditer(r'^var (\w+) = &Message\{code: (\d+),.*?text: "((?:[^"\\]|\\.)*)"', gen, re.M):
    by_code.setdefault(int(m.group(2)), []).append((m.group(1), m.group(3)))

DEF_RE = re.compile(r"^    (?:function|procedure) ([A-Za-z_0-9]+)\(")
GODEF_RE = re.compile(r"^func (?:\([^)]*\) )?(\w+)\(")


def port_sites(name):
    out = []
    for f in sorted(glob.glob(os.path.join(PKG, "0.1.0", "tscaly", "*.scaly"))) + [os.path.join(PKG, "0.1.0", "tscaly_dump.scaly")]:
        if f.endswith("DiagnosticCodes.scaly"):
            continue
        lines = open(f).read().split("\n")
        member = "?"
        for i, line in enumerate(lines):
            m = DEF_RE.match(line)
            if m:
                member = m.group(1)
            code = line.split(";")[0]
            if re.search(r"\bDiag%s\b" % re.escape(name), code):
                out.append("%s:%d %s | %s" % (os.path.basename(f), i + 1, member, line.strip()))
    return out


def ref_sites(name):
    out = []
    for f in sorted(glob.glob(os.path.join(REF, "*", "*.go"))):
        if f.endswith("_test.go") or "diagnostics_generated" in f:
            continue
        src = open(f).read()
        if "diagnostics." + name not in src:
            continue
        lines = src.split("\n")
        func = "?"
        for i, line in enumerate(lines):
            m = GODEF_RE.match(line)
            if m:
                func = m.group(1)
            if re.search(r"(?<!\.)\bdiagnostics\.%s\b" % re.escape(name), line):
                out.append("%s:%d %s | %s" % (os.path.relpath(f, REF), i + 1, func, line.strip()))
    return out


for arg in sys.argv[1:]:
    for name, text in by_code.get(int(arg), []):
        print("=== TS%s %s: %s" % (arg, name, text))
        print("  port:")
        for s in port_sites(name):
            print("    " + s)
        print("  reference:")
        for s in ref_sites(name):
            print("    " + s)
