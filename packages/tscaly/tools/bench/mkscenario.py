#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""
mkscenario.py — a whole TypeScript project as ONE tscaly_exec scenario, so the
port's driver can be measured on a real workload (the Hejlsberg demo: VS Code).

tscaly_exec has no OS file system; it replays a virtual tree. This writes that
tree: the project's package.json files and every `.ts` under the source root,
every declaration file and package.json under node_modules, the tsconfig files,
and the reference's REAL default libraries under the harness's lib path (so
ensure_default_libs does not substitute its one-line stand-in), then one `run`.

Usage:
  mkscenario.py <project dir> <out file> [--src src] [--tsconfig src/tsconfig.json]
                [--extra-config src/tsconfig.base.json ...] [--paths-only]

--paths-only writes the file NAMES and no text: `file <path>` for a project file
(read from disk by tscaly_exec the first time something asks for its text) and
`file-as <virtual path>\t<disk path>` for a default library. The scenario shrinks
from the whole text of the tree to its paths, and a file nothing reads is never read.

Measured 2026-09-16 on VS Code: 17 677 files, 187 MB of text.
"""
import argparse, os

PKG = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
LIBS = os.path.join(PKG, "_submodules", "typescript-go", "internal", "bundled", "libs")
LIB_PATH = "/home/src/tslibs/TS/Lib"
DECL = (".d.ts", ".d.mts", ".d.cts")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("project")
    ap.add_argument("out")
    ap.add_argument("--src", default="src")
    ap.add_argument("--tsconfig", default="src/tsconfig.json")
    ap.add_argument("--extra-config", action="append", default=["src/tsconfig.base.json"])
    ap.add_argument("--paths-only", action="store_true")
    args = ap.parse_args()
    project = os.path.abspath(args.project)
    entries = []

    def add(path, disk):
        if args.paths_only:
            entries.append((path, disk))
            return
        with open(disk, "rb") as f:
            entries.append((path, f.read()))

    for name in sorted(os.listdir(LIBS)):
        if name.endswith(".d.ts"):
            add(LIB_PATH + "/" + name, os.path.join(LIBS, name))
    configs = [args.tsconfig] + args.extra_config
    for rel in ["package.json"] + configs:
        p = os.path.join(project, rel)
        if os.path.isfile(p):
            add(p, p)
    config_paths = {os.path.join(project, rel) for rel in configs}
    for root, dirs, files in os.walk(os.path.join(project, args.src)):
        dirs.sort()
        for f in sorted(files):
            p = os.path.join(root, f)
            if p in config_paths:
                continue
            if f.endswith(".ts") or f.endswith(".json"):
                add(p, p)
    # JSON modules imported from outside the source root (VS Code's component
    # fixtures import the theme files under extensions/): tsgo reads them from
    # disk, so the scenario has to name them or the port reports TS2307
    extensions = os.path.join(project, "extensions")
    for root, dirs, files in os.walk(extensions):
        dirs[:] = sorted(d for d in dirs if d != "node_modules")
        for f in sorted(files):
            if f.endswith(".json"):
                add(os.path.join(root, f), os.path.join(root, f))
    for root, dirs, files in os.walk(os.path.join(project, "node_modules")):
        dirs.sort()
        for f in sorted(files):
            if f.endswith(DECL) or f == "package.json":
                p = os.path.join(root, f)
                if os.path.islink(p) or not os.path.isfile(p):
                    continue
                add(p, p)

    with open(args.out, "wb") as o:
        o.write(b"==== TSCALY-SCENARIO " + os.path.basename(project).encode() + b"\n")
        o.write(("cwd " + project + "\n").encode())
        o.write(b"case 1\n")
        deflib = b"/// <reference no-default-lib=\"true\"/>\n"
        o.write(b"deflib %d\n" % len(deflib) + deflib + b"\n")
        o.write(b"step 0\n")
        for path, text in entries:
            if args.paths_only:
                if path == text:
                    o.write(b"file " + path.encode() + b"\n")
                else:
                    o.write(b"file-as " + path.encode() + b"\t" + text.encode() + b"\n")
                continue
            o.write(b"write %d %s\n" % (len(text), path.encode()))
            o.write(text + b"\n")
        o.write(("run -p\x1f" + args.tsconfig + "\x1f--noEmit\n").encode())
        o.write(b"==== TSCALY-END\n")
    if args.paths_only:
        print("files %d (paths only)" % len(entries))
    else:
        print("files %d, bytes %d" % (len(entries), sum(len(t) for _, t in entries)))


if __name__ == "__main__":
    main()
