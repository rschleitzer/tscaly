#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
#
# casedriver.py — the DRIVER yardstick (phase (b)2): the reference's tsc, tsbuild,
# tscWatch and tsbuildWatch baselines (testdata/baselines/reference/{tsc,tsbuild,
# tscWatch,tsbuildWatch}), replayed.
#
# ★★★ THE BASELINES ARE THEIR OWN SCENARIO FILES. internal/execute/tsctests writes each
# one as the replay of a virtual file system: the tree before the first command
# (`Input::`), the command line (`tsgo …`), the exit status, the sanitized terminal
# output, the file-system DIFF after the command (fsbaselineutil.FSDiffer), the
# incremental program's `SemanticDiagnostics::`/`Signatures::`, a watch's
# registrations — and then, per `Edit [n]:: caption`, the diff the edit made before
# the next command ran. The scenario's Go closures are not needed: an edit's effect is
# its diff (a `*new*`/`*modified*` content is a write, `*deleted*` a removal,
# `*mTime changed*` a touch, `-> target *new*` a symlink), so the input side is read
# from the very file the answer is compared against.
#
# ★★ WHAT IS COMPARED is each step's whole text — initial command and every edit — as
# the reference harness prints it. The port answers the raw facts (exit status, the
# writer's text, the file tree with modification times and which files the program
# wrote or which default libs it read, the program baselines) and this file renders
# them through the harness's own rules (outputSanitizer, FSDiffer.addFsEntryDiff), so
# the rendering is shared by both sides and cannot be where they differ.
#
# Usage:
#   tests/casedriver.py [--filter S] [--selftest] [--binary tests/out/tscaly_exec]
import argparse, collections, os, re, subprocess, sys, tempfile

PKG = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
REF = os.path.join(PKG, "_submodules", "typescript-go", "testdata", "baselines", "reference")
FOLDERS = ("tsc", "tsbuild", "tscWatch", "tsbuildWatch")

ENTRY_RE = re.compile(r"^//// \[(.*?)\] (.*)$", re.M)
EDIT_RE = re.compile(r"\n\nEdit \[(\d+)\]:: ([^\n]*)\n")
COMMAND_RE = re.compile(r"\ntsgo ([^\n]*)\nExitStatus:: ")


def parse_fs_block(block):
    """a FSDiffer block (entries then "\\n") → [(path, marker, content or target)]"""
    entries = []
    heads = list(ENTRY_RE.finditer(block))
    for i, m in enumerate(heads):
        path, rest = m.group(1), m.group(2)
        end = heads[i + 1].start() if i + 1 < len(heads) else len(block) - 1
        body = block[m.end() + 1:end]
        if body.endswith("\n"):
            body = body[:-1]
        if rest.startswith("-> ") and rest.endswith(" *new*"):
            entries.append((path, "symlink", rest[3:-len(" *new*")]))
        elif rest == "*new* ":
            entries.append((path, "new", body))
        elif rest == "*modified* ":
            entries.append((path, "modified", body))
        elif rest == "*Lib*":
            entries.append((path, "lib", body))
        elif rest == "*deleted*":
            entries.append((path, "deleted", None))
        elif rest == "*mTime changed*":
            entries.append((path, "mtime", None))
        elif rest == "*rewrite with same content*":
            entries.append((path, "rewrite", None))
        else:
            raise ValueError("unknown fs entry marker %r at %s" % (rest, path))
    return entries


def render_fs_block(entries):
    """FSDiffer.BaselineFSwithDiff's text for [(path, marker, payload)], sorted by path"""
    out = []
    for path, marker, payload in sorted(entries, key=lambda e: e[0]):
        if marker == "symlink":
            diff = "-> " + payload + " *new*"
        elif marker == "new":
            diff = "*new* \n" + payload
        elif marker == "modified":
            diff = "*modified* \n" + payload
        elif marker == "lib":
            diff = "*Lib*\n" + payload
        elif marker == "deleted":
            diff = "*deleted*"
        elif marker == "mtime":
            diff = "*mTime changed*"
        else:
            diff = "*rewrite with same content*"
        out.append("//// [" + path + "] " + diff + "\n")
    return "".join(out) + "\n"


def parse_baseline(text):
    """a driver baseline → {cwd, case_sensitive, steps: [{caption, edits, args, watch_cycle,
    text, input_block}]}"""
    head = re.match(r"currentDirectory::([^\n]*)\nuseCaseSensitiveFileNames::(true|false)\nInput::\n", text)
    if not head:
        raise ValueError("no scenario header")
    scenario = {"cwd": head.group(1), "case_sensitive": head.group(2) == "true", "steps": []}
    body = text[head.end():]
    parts = EDIT_RE.split(body)
    segments = [(None, parts[0])]
    for i in range(1, len(parts), 3):
        segments.append((parts[i + 1], parts[i + 2]))
    for index, (caption, seg) in enumerate(segments):
        cm = COMMAND_RE.search("\n" + seg)
        om = seg.find("\nOutput::\n")
        if cm and (om < 0 or cm.start() <= om):
            block = seg[:cm.start()]
            args = cm.group(1)
            watch_cycle = False
        else:
            if om < 0:
                raise ValueError("step %d has neither a command nor an output" % index)
            block = seg[:om]
            args = None
            watch_cycle = True
        if not block.endswith("\n"):
            raise ValueError("step %d: the input block does not end in a newline" % index)
        edits = parse_fs_block(block)
        scenario["steps"].append({"caption": caption, "edits": edits, "args": args,
                                  "watch_cycle": watch_cycle, "text": seg, "input_block": block})
    return scenario


def baselines(filter_text=""):
    for folder in FOLDERS:
        base = os.path.join(REF, folder)
        for dirpath, _, names in sorted(os.walk(base)):
            for name in sorted(names):
                if not name.endswith(".js"):
                    continue
                path = os.path.join(dirpath, name)
                key = os.path.relpath(path, REF)[:-3]
                if filter_text and filter_text not in key:
                    continue
                yield key, path


def selftest(filter_text):
    """the parse is the oracle's input side: every step's input block must re-render to
    the very text it was read from, or a scenario would replay a different tree"""
    bad = 0
    count = 0
    for key, path in baselines(filter_text):
        text = open(path, encoding="utf-8", errors="surrogateescape").read()
        count += 1
        try:
            sc = parse_baseline(text)
        except ValueError as e:
            print("PARSE FAIL %s: %s" % (key, e))
            bad += 1
            continue
        for i, step in enumerate(sc["steps"]):
            again = render_fs_block(step["edits"])
            if again != step["input_block"]:
                print("RENDER FAIL %s step %d" % (key, i))
                bad += 1
                break
    print("selftest: %d baselines, %d failures" % (count, bad))
    return bad == 0


def inventory(filter_text):
    folders = collections.Counter()
    steps = collections.Counter()
    commands = collections.Counter()
    for key, path in baselines(filter_text):
        sc = parse_baseline(open(path, encoding="utf-8", errors="surrogateescape").read())
        folder = key.split(os.sep)[0]
        folders[folder] += 1
        steps[folder] += len(sc["steps"])
        for st in sc["steps"]:
            if st["args"] is not None:
                commands[" ".join(a for a in st["args"].split(" ") if a.startswith("-")) or "(no flags)"] += 1
    return folders, steps, commands


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--filter", default="")
    ap.add_argument("--selftest", action="store_true")
    ap.add_argument("--binary", default=os.path.join(PKG, "tests", "out", "tscaly_exec"))
    args = ap.parse_args()
    if args.selftest:
        sys.exit(0 if selftest(args.filter) else 1)
    folders, steps, commands = inventory(args.filter)
    print("driver yardstick — %d scenarios, %d steps" % (sum(folders.values()), sum(steps.values())))
    for f in FOLDERS:
        print("  %-13s %4d scenarios %5d steps" % (f, folders[f], steps[f]))
    if not os.path.exists(args.binary):
        print("  UNPORTED  %d (no %s: the driver is not ported)" % (sum(folders.values()), os.path.relpath(args.binary, PKG)))
    print("  command shapes:", commands.most_common(12))


if __name__ == "__main__":
    main()
