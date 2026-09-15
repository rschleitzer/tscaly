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
        text = open(path, encoding="utf-8", errors="surrogateescape", newline="").read()
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
        sc = parse_baseline(open(path, encoding="utf-8", errors="surrogateescape", newline="").read())
        folder = key.split(os.sep)[0]
        folders[folder] += 1
        steps[folder] += len(sc["steps"])
        for st in sc["steps"]:
            if st["args"] is not None:
                commands[" ".join(a for a in st["args"].split(" ") if a.startswith("-")) or "(no flags)"] += 1
    return folders, steps, commands


# ── the scenario's settings the baseline does not print (tsctests' Go literals) ──

GO_TESTS = os.path.join(PKG, "_submodules", "typescript-go", "internal", "execute", "tsctests")


def scenario_settings():
    """subScenario (as its baseline file name) → {env, windows_root, ignore_case}: the
    tscInput fields no baseline line shows"""
    out = {}
    for name in ("tsc_test.go", "tscbuild_test.go", "tscwatch_test.go"):
        path = os.path.join(GO_TESTS, name)
        if not os.path.exists(path):
            continue
        src = open(path, encoding="utf-8").read()
        heads = list(re.finditer(r'subScenario:\s*"((?:[^"\\]|\\.)*)"', src))
        for i, m in enumerate(heads):
            end = heads[i + 1].start() if i + 1 < len(heads) else len(src)
            window = src[m.end():end]
            settings = {}
            em = re.search(r'env:\s*map\[string\]string\{(.*?)\}', window, re.S)
            if em:
                settings["env"] = dict(re.findall(r'"([^"]*)":\s*"([^"]*)"', em.group(1)))
            wm = re.search(r'windowsStyleRoot:\s*"([^"]*)"', window)
            if wm:
                settings["windows_root"] = wm.group(1)
            if settings:
                out[m.group(1).replace(" ", "-")] = settings
    return out


# ── the harness's rendering of the port's facts ─────────────────────────────

BUILD_STARTING_AT = "build starting at "
BUILD_FINISHED_IN = "build finished in "
SKIPPED_BLOCKS = [("!!! List files start", "!!! List files end", False, False),
                  ("!!! Statistics start", "!!! Statistics end", True, False),
                  ("!!! Trace start", "!!! Trace end", False, False),
                  ("!!! Build Status Report Start", "!!! Build Status Report End", False, True),
                  ("!!! Watch Status Report Start", "!!! Watch Status Report End", False, True)]
# core.Version() of the binary the baselines were written with (see help.scaly)
TS_VERSION = "7.0.0-dev"
INTERNAL_SYMBOL_RE = re.compile("�@[^@]+@[0-9]+")


def sanitize_internal_symbol_names(s):
    if "�@" not in s:
        return s
    return INTERNAL_SYMBOL_RE.sub(lambda m: m.group(0)[:m.group(0).rindex("@")] + "@<symbolId>", s)


def sanitize_output(text):
    """tsctests' outputSanitizer.transformLines, forComparing false"""
    lines = text.split("\n")
    out = []

    def add(line):
        line = line.replace("'%s'" % TS_VERSION, "'FakeTSVersion'")
        line = line.replace("Version " + TS_VERSION, "Version FakeTSVersion")
        out.append(sanitize_internal_symbol_names(line))

    i = 0
    while i < len(lines):
        line = lines[i]
        if line.startswith(BUILD_STARTING_AT):
            add(BUILD_STARTING_AT + "HH:MM:SS AM")
            i += 1
            continue
        if line.startswith(BUILD_FINISHED_IN):
            add(BUILD_FINISHED_IN + "d.ddds")
            i += 1
            continue
        handled = False
        for start, end, skip_always, stamp in SKIPPED_BLOCKS:
            if line != start:
                continue
            handled = True
            i += 1
            first = True
            while i < len(lines) and lines[i] != end:
                if not skip_always:
                    l = lines[i]
                    if first and stamp:
                        colon = l.find(":")
                        l = l[:colon - 2] + "HH:MM:SS AM" + l[colon + len("HH:MM:SS AM") - 2:]
                        first = False
                    add(l)
                i += 1
            break
        if not handled:
            add(line)
        i += 1
    return "\n".join(out)


def fs_diff(old, old_libs, new, new_libs):
    """FSDiffer.addFsEntryDiff over two snapshots {path: (kind, content or target, mtime,
    written)} → the block text"""
    entries = []
    for path, (kind, payload, mtime, written) in new.items():
        before = old.get(path) if old is not None else None
        if before is None:
            if path not in new_libs:
                if kind == "S":
                    entries.append((path, "symlink", payload))
                else:
                    entries.append((path, "new", payload))
        elif kind == "S" or before[0] == "S":
            continue
        elif payload != before[1]:
            entries.append((path, "modified", payload))
        elif written:
            entries.append((path, "rewrite", None))
        elif mtime != before[2]:
            entries.append((path, "mtime", None))
        elif old_libs is not None and path in old_libs and path not in new_libs:
            entries.append((path, "lib", payload))
    if old is not None:
        for path in old:
            if path not in new:
                entries.append((path, "deleted", None))
    return render_fs_block(entries)


# ── the scenario file the port reads, and its answer ────────────────────────

def default_lib_content():
    """tsctests' tscDefaultLibContent, through stringtestutil.Dedent"""
    src = open(os.path.join(GO_TESTS, "sys.go"), encoding="utf-8").read()
    raw = re.search(r"var tscDefaultLibContent = stringtestutil\.Dedent\(`(.*?)`\)", src, re.S).group(1)
    lines = raw.replace("\t", "    ").split("\n")
    nonblank = [i for i, l in enumerate(lines) if l.strip()]
    lines = lines[nonblank[0]:nonblank[-1] + 1]
    indent = min(len(l) - len(l.lstrip(" ")) for l in lines if l.strip())
    return "\n".join(l[indent:] if len(l) > indent else "" for l in lines)


DEFLIB = None


def scenario_input(key, sc, settings):
    global DEFLIB
    if DEFLIB is None:
        DEFLIB = default_lib_content()
    out = []
    w = out.append
    w("==== TSCALY-SCENARIO %s\n" % key)
    w("cwd %s\n" % sc["cwd"])
    w("case %d\n" % (1 if sc["case_sensitive"] else 0))
    if settings.get("windows_root"):
        w("root %s\n" % settings["windows_root"])
    for k, v in sorted(settings.get("env", {}).items()):
        w("env %s\t%s\n" % (k, v))
    w("deflib %d\n%s\n" % (len(DEFLIB.encode("utf-8")), DEFLIB))
    for i, step in enumerate(sc["steps"]):
        w("step %d\n" % i)
        for path, marker, payload in step["edits"]:
            if marker in ("new", "modified"):
                data = payload.encode("utf-8", "surrogateescape")
                w("write %d %s\n" % (len(data), path))
                out.append(data.decode("utf-8", "surrogateescape"))
                w("\n")
            elif marker == "deleted":
                w("delete %s\n" % path)
            elif marker == "mtime":
                w("touch %s\n" % path)
            elif marker == "symlink":
                w("link %s\t%s\n" % (path, payload))
            else:
                w("unsupported %s %s\n" % (marker, path))
        if step["watch_cycle"]:
            w("cycle\n")
        else:
            w("run %s\n" % "\x1f".join(step["args"].split(" ")))
    w("==== TSCALY-END\n")
    return "".join(out)


def parse_snapshot(lines, i):
    """`F <mtime> <written> <len> <path>` + content, `S <path>\\t<target>`, `L <path>`
    until `==== ` → (snapshot, libs, next index)"""
    snap, libs = {}, set()
    while i < len(lines) and not lines[i].startswith("==== "):
        line = lines[i]
        if line.startswith("F "):
            _, mtime, written, length, path = line.split(" ", 4)
            n = int(length)
            data = "\n".join(lines[i + 1:])
            content = data.encode("utf-8", "surrogateescape")[:n].decode("utf-8", "surrogateescape")
            consumed = content.count("\n") + 1
            # FSDiffer sanitizes every regular file's content
            snap[path] = ("F", sanitize_internal_symbol_names(content), int(mtime), written == "1")
            i += 1 + consumed
            continue
        if line.startswith("S "):
            path, target = line[2:].split("\t", 1)
            snap[path] = ("S", target, 0, False)
        elif line.startswith("L "):
            _, mtime, path = line.split(" ", 2)
            libs.add(path)
            snap[path] = ("F", DEFLIB, int(mtime), False)
        i += 1
    return snap, libs, i


def parse_answer(text):
    """the port's answer for one scenario → [step dict]"""
    lines = text.split("\n")
    steps = []
    cur = None
    i = 0
    while i < len(lines):
        line = lines[i]
        if line.startswith("==== TSCALY-STEP "):
            cur = {"index": int(line.split()[2])}
            steps.append(cur)
            i += 1
            continue
        if cur is None:
            i += 1
            continue
        if line in ("==== PRE", "==== POST"):
            snap, libs, i = parse_snapshot(lines, i + 1)
            cur[line[5:].lower()] = (snap, libs)
            continue
        m = re.match(r"==== (OUTPUT|PROGRAMS|WATCH) (\d+)$", line)
        if m:
            n = int(m.group(2))
            data = "\n".join(lines[i + 1:]).encode("utf-8", "surrogateescape")[:n].decode("utf-8", "surrogateescape")
            cur[m.group(1).lower()] = data
            i += 1 + data.count("\n") + 1
            continue
        if line.startswith("==== EXIT "):
            cur["exit"] = line[len("==== EXIT "):]
        elif line.startswith("==== UNPORTED "):
            cur["unported"] = line[len("==== UNPORTED "):]
        i += 1
    return steps


def render_step(sc_step, ours, prev_post):
    """→ (input block, rest) as the harness would print this step"""
    pre_snap, pre_libs = ours["pre"]
    old_snap, old_libs = prev_post if prev_post is not None else (None, None)
    block = fs_diff(old_snap, old_libs, pre_snap, pre_libs)
    post_snap, post_libs = ours["post"]
    rest = []
    if not sc_step["watch_cycle"]:
        rest.append("tsgo " + sc_step["args"] + "\n")
        rest.append("ExitStatus:: " + ours.get("exit", "?"))
    rest.append("\nOutput::\n")
    rest.append(sanitize_output(ours.get("output", "")))
    rest.append(fs_diff(pre_snap, pre_libs, post_snap, post_libs))
    rest.append(ours.get("programs", ""))
    rest.append(ours.get("watch", ""))
    return block, "".join(rest)


def run(args):
    settings = scenario_settings()
    items = []
    for key, path in baselines(args.filter):
        sc = parse_baseline(open(path, encoding="utf-8", errors="surrogateescape", newline="").read())
        items.append((key, sc))
    counts = collections.Counter()
    step_counts = collections.Counter()
    unported = collections.Counter()
    fails = []
    all_verdicts = []
    input_counts = collections.Counter()
    input_fails = []
    batch = "".join(scenario_input(key, sc, settings.get(os.path.basename(key), {})) for key, sc in items)
    with tempfile.NamedTemporaryFile("w", suffix=".scenarios", delete=False, encoding="utf-8", errors="surrogateescape") as fh:
        fh.write(batch)
        batch_path = fh.name
    proc = subprocess.run(["bash", "-c", 'ulimit -s 65520 2>/dev/null; exec "$0" --batch "$1"', args.binary, batch_path],
                          capture_output=True, timeout=args.timeout)
    os.unlink(batch_path)
    answer = proc.stdout.decode("utf-8", "surrogateescape")
    parts = re.split(r"^==== TSCALY-SCENARIO (.*)$", answer, flags=re.M)
    by_key = {parts[i]: parts[i + 1] for i in range(1, len(parts), 2)}
    for key, sc in items:
        body = by_key.get(key)
        if body is None:
            counts["CRASH"] += 1
            fails.append((key, "no answer (rc %d)" % proc.returncode))
            continue
        ours_steps = parse_answer(body)
        verdict = "MATCH"
        detail = ""
        prev_post = None
        for index, step in enumerate(sc["steps"]):
            ours = ours_steps[index] if index < len(ours_steps) else None
            if ours is None:
                verdict = "CRASH"
                step_counts["CRASH"] += 1
                break
            if "pre" in ours:
                pre_snap, pre_libs = ours["pre"]
                old_snap, old_libs = prev_post if prev_post is not None else (None, None)
                if fs_diff(old_snap, old_libs, pre_snap, pre_libs) == step["input_block"]:
                    input_counts["MATCH"] += 1
                else:
                    input_counts["FAIL"] += 1
                    input_fails.append((key, index))
            if "unported" in ours:
                verdict = "UNPORTED" if verdict == "MATCH" else verdict
                unported[ours["unported"].split(" ")[0]] += 1
                detail = "step %d %s" % (index, ours["unported"])
                step_counts["UNPORTED"] += 1
                break
            if "post" not in ours:
                verdict = "CRASH"
                step_counts["CRASH"] += 1
                fails.append((key, "step %d crashed (rc %d)" % (index, proc.returncode)))
                detail = "step %d crash" % index
                break
            block, rest = render_step(step, ours, prev_post)
            expected_rest = step["text"][len(step["input_block"]):]
            if block != step["input_block"] or rest != expected_rest:
                verdict = "FAIL"
                step_counts["FAIL"] += 1
                fails.append((key, "step %d" % index, block, step["input_block"], rest, expected_rest))
                detail = "step %d" % index
                break
            step_counts["MATCH"] += 1
            prev_post = ours["post"]
        counts[verdict] += 1
        all_verdicts.append((key, verdict, detail))
    print("driver yardstick — %d scenarios" % len(items))
    for k in ("MATCH", "UNPORTED", "FAIL", "CRASH"):
        print("  %-9s %d" % (k, counts[k]))
    print("  steps:", dict(step_counts))
    print("  input trees (the replayed Input/edit block): MATCH %d FAIL %d %s" % (input_counts["MATCH"], input_counts["FAIL"], input_fails[:5]))
    if unported:
        print("  stops by tag:", unported.most_common(15))
    if args.show:
        for f in fails:
            if args.show in f[0]:
                print("==== %s %s" % (f[0], f[1]))
                if len(f) > 2:
                    import difflib
                    print("".join(difflib.unified_diff((f[3] + f[5]).splitlines(True), (f[2] + f[4]).splitlines(True), "expected", "ours")))
    if args.verdicts:
        with open(args.verdicts, "w") as fh:
            for key, verdict, detail in all_verdicts:
                fh.write("%s\t%s\t%s\n" % (key, verdict, detail))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--filter", default="")
    ap.add_argument("--selftest", action="store_true")
    ap.add_argument("--binary", default=os.path.join(PKG, "tests", "out", "tscaly_exec"))
    ap.add_argument("--timeout", type=int, default=1200)
    ap.add_argument("--show", default="")
    ap.add_argument("--verdicts", default="")
    args = ap.parse_args()
    if args.selftest:
        sys.exit(0 if selftest(args.filter) else 1)
    if os.path.exists(args.binary):
        run(args)
        return
    folders, steps, commands = inventory(args.filter)
    print("driver yardstick — %d scenarios, %d steps" % (sum(folders.values()), sum(steps.values())))
    for f in FOLDERS:
        print("  %-13s %4d scenarios %5d steps" % (f, folders[f], steps[f]))
    print("  UNPORTED  %d (no %s: the driver is not ported)" % (sum(folders.values()), os.path.relpath(args.binary, PKG)))
    print("  command shapes:", commands.most_common(12))


if __name__ == "__main__":
    main()
