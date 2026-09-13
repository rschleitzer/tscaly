#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""
casejs.py — THE DRIVER CHAPTER'S YARDSTICK (slice 243): the JavaScript the port emits
for a whole CASE under the case's own `// @option:` directives, against the reference's
own `.js` baseline per case — the TypeScript submodule's tests/baselines/reference,
which typescript-go's compiler runner reproduces byte for byte except for the ten
cases it records a `.js.diff` for (testdata/baselines/reference/submodule).

The seventh yardstick (tests/oracle/batch.go, dumpEmit) compares one UNIT under the
DEFAULT options; its header names this one as the driver chapter's. What this one
measures that it cannot: the transformers only a non-default target or module reaches
(ES2016–ES2021 downlevel, legacy decorators, JSX, CommonJS for a `.ts` file), the
per-case configuration variations (`// @target: esnext, es2015`), and the declaration
and source-map emitters once they exist.

What it does, per submodule case of the store (tests/out/run.db):
  1. the settings — the reference's optionRegex over the case text, names lower-cased;
  2. the configurations — harnessutil.GetFileBasedTestConfigurations: every option in
     the vary-by set with a comma list multiplies; the baseline is named
     `<stem>(<k=v,...>).js` with the varied options sorted; an es5 target is skipped
     (the reference skips it: SkipUnsupportedCompilerOptions), so are outFile, baseUrl
     and the three `=false` options it refuses;
  3. the reference answer — the baseline's output sections (`//// [name.js]`) after
     the input sections (one per unit), CRLF normalized;
  4. our answer — `tscaly_dump --emit=<options> --batch` over the case's emitted units
     (a `.d.ts` and a `.json` are not emitted; a `.js`/`.jsx` only under allowJs),
     each unit's output named by the reference's extension rule;
  5. the verdict — MATCH, UNPORTED (a unit stopped; the tag is kept), FAIL (a diff),
     SKIP (no baseline, an unsupported configuration, a recorded reference diff).

Usage:
  tests/casejs.py [--store tests/out/run.db] [--binary tests/out/tscaly_dump]
                  [--filter SUBSTR] [--jobs N] [--verdicts FILE] [--show CASE[:CONFIG]]
"""
import argparse, os, re, sqlite3, sys, itertools, collections, difflib

HERE = os.path.dirname(os.path.abspath(__file__))
PKG = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import harness  # noqa: E402  (write_units_file, run_batch, parse_dump_stream)

TS = os.path.join(PKG, "_submodules", "typescript-go", "_submodules", "TypeScript")
BASELINES = os.path.join(TS, "tests", "baselines", "reference")
TSGO_DIFFS = os.path.join(PKG, "_submodules", "typescript-go", "testdata", "baselines", "reference", "submodule")

OPTION_RE = re.compile(r"^//\s*@(\w+)\s*:\s*([^\r\n]*)", re.M)

# harnessutil.getCompilerVaryByMap: the boolean and enum options that affect the
# program, the emit, module resolution, a diagnostic class or the source file — plus
# noEmit and isolatedModules. The list is the reference's tsoptions declarations
# filtered by those flags; spelled out here so the runner needs no Go.
VARY_BY = {
    "allowarbitraryextensions", "allowimportingtsextensions", "allowjs", "allowsyntheticdefaultimports",
    "allowumdglobalaccess", "allowunreachablecode", "allowunusedlabels", "alwaysstrict", "checkjs",
    "composite", "declaration", "declarationmap", "downleveliteration", "emitbom", "emitdeclarationonly",
    "emitdecoratormetadata", "erasablesyntaxonly", "esmoduleinterop", "exactoptionalpropertytypes",
    "experimentaldecorators", "forceconsistentcasinginfilenames", "importhelpers", "incremental",
    "inlinesourcemap", "inlinesources", "isolateddeclarations", "isolatedmodules", "jsx", "libreplacement",
    "module", "moduledetection", "moduleresolution", "newline", "nocheck", "noemit", "noemithelpers",
    "noemitonerror", "noerrortruncation", "nofallthroughcasesinswitch", "noimplicitany",
    "noimplicitoverride", "noimplicitreturns", "noimplicitthis", "nolib", "nopropertyaccessfromindexsignature",
    "noresolve", "nouncheckedindexedaccess", "nouncheckedsideeffectimports", "nounusedlocals",
    "nounusedparameters", "preserveconstenums", "preservesymlinks", "removecomments",
    "resolvejsonmodule", "resolvepackagejsonexports", "resolvepackagejsonimports",
    "rewriterelativeimportextensions", "skipdefaultlibcheck", "skiplibcheck", "sourcemap", "strict",
    "strictbindcallapply", "strictbuiltiniteratorreturn", "strictfunctiontypes", "strictnullchecks",
    "strictpropertyinitialization", "stripinternal", "target", "usedefineforclassfields",
    "useunknownincatchvariables", "verbatimmodulesyntax",
}
BOOLEAN_STAR = ["true", "false"]
ENUM_VALUES = {
    "target": ["es5", "es6", "es2015", "es2016", "es2017", "es2018", "es2019", "es2020", "es2021", "es2022", "es2023", "es2024", "es2025", "esnext"],
    "module": ["commonjs", "amd", "system", "umd", "es6", "es2015", "es2020", "es2022", "esnext", "node16", "node18", "node20", "nodenext", "preserve"],
    "jsx": ["preserve", "react-native", "react-jsx", "react-jsxdev", "react"],
    "moduledetection": ["auto", "legacy", "force"],
    "newline": ["crlf", "lf"],
}

# compiler_runner.go: skippedTests (built typescript.d.ts) and skippedEmitTests
SKIPPED_TESTS = {"APILibCheck.ts", "APISample_Watch.ts", "APISample_WatchWithDefaults.ts", "APISample_WatchWithOwnWatchHost.ts",
                 "APISample_compile.ts", "APISample_jsdoc.ts", "APISample_linter.ts", "APISample_parseConfig.ts",
                 "APISample_transform.ts", "APISample_watcher.ts"}
SKIPPED_EMIT = {"filesEmittingIntoSameOutput.ts", "jsFileCompilationWithJsEmitPathSameAsInput.ts", "grammarErrors.ts",
                "jsFileCompilationEmitBlockedCorrectly.ts", "jsDeclarationsReexportAliasesEsModuleInterop.ts",
                "jsFileCompilationWithoutJsExtensions.ts", "typeOnlyMerge2.ts", "typeOnlyMerge3.ts"}


def split_option_values(value, option):
    """harnessutil.splitOptionValues: a comma list, `*` for every value, `-x`/`!x` excludes."""
    if not value:
        return []
    star, includes, excludes = False, [], []
    for s in value.split(","):
        s = s.strip()
        if not s:
            continue
        if s == "*":
            star = True
        elif s[0] in "-!":
            excludes.append(s[1:])
        else:
            includes.append(s)
    variations = list(includes)
    if star:
        allv = ENUM_VALUES.get(option, BOOLEAN_STAR)
        for v in allv:
            if v not in variations:
                variations.append(v)
    out = []
    for v in variations:
        if v.lower() in [e.lower() for e in excludes]:
            continue
        out.append(v)
    return out


def configurations(settings):
    """→ [(name, {option: value})]; name "" when nothing varies."""
    entries, nonvarying = [], {}
    for option, value in settings.items():
        if option in VARY_BY:
            vals = split_option_values(value, option)
            if len(vals) > 1:
                entries.append((option, vals))
            elif len(vals) == 1:
                nonvarying[option] = vals[0]
        else:
            nonvarying[option] = value
    if not entries:
        return [("", dict(nonvarying))]
    entries.sort()
    configs = []
    for combo in itertools.product(*[vals for _, vals in entries]):
        varying = {opt: val for (opt, _), val in zip(entries, combo)}
        name = ",".join("%s=%s" % (k, varying[k].lower()) for k in sorted(varying))
        cfg = dict(varying)
        cfg.update(nonvarying)
        configs.append((name, cfg))
    return configs


def unsupported(cfg):
    """harnessutil.SkipUnsupportedCompilerOptions"""
    t = cfg.get("target", "").lower()
    if t == "es5":
        return "target es5"
    m = cfg.get("module", "").lower()
    if m in ("amd", "umd", "system"):
        return "module " + m
    mr = cfg.get("moduleresolution", "").lower()
    if mr in ("node", "node10", "classic"):
        return "moduleResolution " + mr
    if cfg.get("esmoduleinterop", "").lower() == "false":
        return "esModuleInterop=false"
    if cfg.get("allowsyntheticdefaultimports", "").lower() == "false":
        return "allowSyntheticDefaultImports=false"
    if cfg.get("baseurl"):
        return "baseUrl"
    if cfg.get("outfile") or cfg.get("out"):
        return "outFile"
    if cfg.get("alwaysstrict", "").lower() == "false":
        return "alwaysStrict=false"
    return None


def output_name(unit_name, cfg):
    base = os.path.basename(unit_name)
    stem, ext = os.path.splitext(base)
    jsx = cfg.get("jsx", "").lower()
    if ext == ".ts":
        return stem + ".js"
    if ext == ".tsx":
        return stem + (".jsx" if jsx in ("preserve", "react-native") else ".js")
    if ext == ".mts":
        return stem + ".mjs"
    if ext == ".cts":
        return stem + ".cjs"
    if ext == ".js":
        return base
    if ext == ".jsx":
        return stem + (".jsx" if jsx in ("preserve", "react-native") else ".js")
    return None


def allow_js(cfg):
    return cfg.get("allowjs", "").lower() == "true" or cfg.get("checkjs", "").lower() == "true"


def emitted(unit_name, cfg):
    base = os.path.basename(unit_name)
    low = base.lower()
    if low.endswith(".d.ts") or low.endswith(".d.mts") or low.endswith(".d.cts") or re.search(r"\.d\.[^./]+\.ts$", low):
        return False
    # a file under node_modules is an external library: never emitted
    if "/node_modules/" in ("/" + unit_name.replace("\\", "/").lower()):
        return False
    ext = os.path.splitext(low)[1]
    if ext in (".ts", ".tsx", ".mts", ".cts"):
        return True
    if ext in (".js", ".jsx", ".mjs", ".cjs"):
        return allow_js(cfg)
    return False


def parse_baseline(text):
    """→ (header, [(name, content)]) of a `.js` baseline, CRLF normalized."""
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    parts = re.split(r"^//// \[([^\]\n]*)\]( ////)?\n", text, flags=re.M)
    # parts: [pre, name1, marker1, body1, name2, marker2, body2, ...]
    sections = []
    header = None
    i = 1
    while i + 2 < len(parts) + 1 and i < len(parts):
        name, marker, body = parts[i], parts[i + 1], parts[i + 2] if i + 2 < len(parts) else ""
        if marker:
            header = name
        else:
            sections.append((name, body))
        i += 3
    return header, sections


def decode_case(raw):
    """A case file as the reference's vfs reads it: the byte order mark decoded away."""
    if raw.startswith(b"\xef\xbb\xbf"):
        return raw[3:].decode("utf-8", "replace")
    if raw.startswith(b"\xff\xfe"):
        return raw[2:].decode("utf-16-le", "replace")
    if raw.startswith(b"\xfe\xff"):
        return raw[2:].decode("utf-16-be", "replace")
    return raw.decode("utf-8", "replace")


def strip_directives(content):
    """The store's splitter keeps a `// @option:` line the byte order mark hid from its
    regex (line one of a BOM-led case, UTF-8 or UTF-16); the reference's vfs read decodes
    the mark first. The unit is handed on decoded, as the reference hands it to its parser."""
    if not (content.startswith(b"\xef\xbb\xbf") or content.startswith(b"\xff\xfe") or content.startswith(b"\xfe\xff")):
        return content
    text = decode_case(content)
    while True:
        nl = text.find("\n")
        first = text if nl < 0 else text[:nl]
        if OPTION_RE.match(first):
            text = "" if nl < 0 else text[nl + 1:]
        else:
            break
    return text.encode("utf-8")


def options_string(cfg):
    items = dict(cfg)
    if allow_js(cfg):
        items["allowjs"] = "true"     # GetAllowJS: checkJs implies allowJs
    return ";".join("%s=%s" % (k, str(v).strip().lower()) for k, v in sorted(items.items()))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--store", default=os.path.join(PKG, "tests", "out", "run.db"))
    ap.add_argument("--binary", default=os.path.join(PKG, "tests", "out", "tscaly_dump"))
    ap.add_argument("--filter", default="")
    ap.add_argument("--jobs", type=int, default=8)
    ap.add_argument("--timeout", type=int, default=120)
    ap.add_argument("--verdicts", default="")
    ap.add_argument("--show", default="")
    ap.add_argument("--scratch", default=os.path.join(PKG, "tests", "out", "casejs"))
    ap.add_argument("--refute", action="store_true", help="the negative control: every reference section gets one byte appended, so a MATCH is impossible and the count must read 0")
    args = ap.parse_args()

    db = sqlite3.connect(args.store)
    cases = db.execute("SELECT ci, name, case_file FROM cases WHERE name LIKE 'submodule_%' ORDER BY ci").fetchall()
    diff_names = set()
    for sub in ("compiler", "conformance"):
        d = os.path.join(TSGO_DIFFS, sub)
        if os.path.isdir(d):
            diff_names.update(n[:-len(".diff")] for n in os.listdir(d) if n.endswith(".js.diff"))

    # ── plan: (case, config) → the units to emit and the expected sections ──
    plans = []            # dicts
    skips = collections.Counter()
    groups = collections.defaultdict(list)   # options string → [(vpath, content)]
    for ci, name, case_file in cases:
        if args.filter and args.filter not in name:
            continue
        base = os.path.basename(case_file)
        stem = os.path.splitext(base)[0]
        if base in SKIPPED_TESTS or base in SKIPPED_EMIT:
            skips["skipped by the reference"] += 1
            continue
        try:
            with open(case_file, "rb") as fh:
                text = fh.read().decode("utf-8", "replace")
        except OSError:
            skips["case file unreadable"] += 1
            continue
        # the reference reads the case through its vfs, which decodes a byte order mark
        # (UTF-8 or UTF-16); a directive on a BOM-led first line is a directive there and
        # a comment in the store's raw bytes
        text = decode_case(open(case_file, "rb").read())
        settings = {m.group(1).lower(): m.group(2).strip().rstrip(";") for m in OPTION_RE.finditer(text)}
        units = db.execute("SELECT name, content FROM units WHERE ci=? ORDER BY idx", (ci,)).fetchall()
        units = [(n, strip_directives(c)) for n, c in units]
        units = [(n, c) for n, c in units if not os.path.basename(n).lower() in ("tsconfig.json", "jsconfig.json")]
        # a name declared twice is ONE file to the reference (a map by path; the last content wins)
        last = {}
        for i, (n, c) in enumerate(units):
            last[n] = i
        units = [(n, c) for i, (n, c) in enumerate(units) if last[n] == i]
        for cname, cfg in configurations(settings):
            bname = stem + ("(%s)" % cname if cname else "") + ".js"
            key = (name, cname)
            reason = unsupported(cfg)
            if reason:
                skips["unsupported: " + reason] += 1
                continue
            bpath = os.path.join(BASELINES, bname)
            if not os.path.exists(bpath):
                skips["no baseline"] += 1
                continue
            if bname in diff_names:
                skips["reference records a diff"] += 1
                continue
            if cfg.get("noemit", "").lower() == "true":
                skips["noEmit"] += 1
                continue
            if cfg.get("emitdeclarationonly", "").lower() == "true":
                skips["emitDeclarationOnly (the declaration chapter)"] += 1
                continue
            with open(bpath, "rb") as fh:
                btext = fh.read().decode("utf-8", "replace")
            header, sections = parse_baseline(btext)
            n_inputs = len(units)
            outputs = sections[n_inputs:]
            if args.refute:
                outputs = [(n, b + "x") for n, b in outputs]
            if any(n == "DtsFileErrors" or n.startswith("!!!!") for n, _ in outputs) or "\n!!!! File " in btext:
                skips["baseline carries declaration errors / noCheck notes"] += 1
                continue
            to_emit = [(n, c) for n, c in units if emitted(n, cfg)]
            opts = options_string(cfg)
            plan = {"case": name, "config": cname, "opts": opts, "units": [], "outputs": outputs, "baseline": bname}
            for ui, (un, content) in enumerate(to_emit):
                # one answer per (case, configuration, unit) — a case may declare a name twice
                vpath = "/cases/%s/%s/u%d/%s" % (name, cname or "default", ui, un)
                groups[opts].append((vpath, content))
                plan["units"].append((vpath, un, output_name(un, cfg)))
            plans.append(plan)

    # ── run: one batch per configuration string ──
    answers = {}
    os.makedirs(args.scratch, exist_ok=True)
    # the port's parser recurses: the dump runs under the stack tests/run.sh sets
    # (a 40 KB binary-expression chain is a SIGSEGV at the default 8 MB)
    wrapper = os.path.join(args.scratch, "dump-with-stack.sh")
    with open(wrapper, "w") as fh:
        fh.write("#!/bin/sh\nulimit -s 65520 2>/dev/null\nexec %s \"$@\"\n" % os.path.abspath(args.binary))
    os.chmod(wrapper, 0o755)
    binary = wrapper
    total_units = sum(len(v) for v in groups.values())
    print("cases planned %d, configurations skipped %d, units to emit %d in %d option groups" % (
        len(plans), sum(skips.values()), total_units, len(groups)), flush=True)
    for gi, (opts, units) in enumerate(sorted(groups.items(), key=lambda kv: -len(kv[1]))):
        res = harness.run_batch(binary, "--emit=" + opts, units, os.path.join(args.scratch, "g%d" % gi), args.jobs, args.timeout)
        answers.update(res)

    # ── verdicts ──
    verdicts = []
    counts = collections.Counter()
    stops = collections.Counter()
    for plan in plans:
        verdict, detail = "MATCH", ""
        used = collections.Counter()
        for vpath, un, oname in plan["units"]:
            rc, body, err = answers.get(vpath, (None, b"", b""))
            if rc is None:
                verdict, detail = "CRASH", "no answer for %s" % un
                break
            if rc != 0:
                verdict, detail = "CRASH", "rc %s on %s" % (rc, un)
                break
            ours = body.decode("utf-8", "replace")
            if ours.startswith("UNPORTED "):
                verdict, detail = "UNPORTED", ours.split("\n")[0]
                break
            # the k-th output section of that name
            k = used[oname]
            used[oname] += 1
            matches = [b for n, b in plan["outputs"] if n == oname]
            if not matches:
                verdict, detail = "FAIL", "no output section %s in the baseline" % oname
                break
            expected = matches[min(k, len(matches) - 1)]
            if expected.rstrip("\n") != ours.replace("\r\n", "\n").rstrip("\n"):
                verdict, detail = "FAIL", oname
                break
        if verdict == "MATCH" and any(n.endswith(".d.ts") or n.endswith(".d.mts") or n.endswith(".d.cts") for n, _ in plan["outputs"]):
            # the JavaScript matched; the declaration files beside it are a chapter of their own
            verdict, detail = "UNPORTED", "UNPORTED 1 emit-declaration 0"
        counts[verdict] += 1
        if verdict == "UNPORTED":
            stops[" ".join(detail.split()[2:3])] += 1
        verdicts.append((plan["case"], plan["config"], verdict, detail))

    print()
    print("casejs yardstick — %d (case, configuration) pairs against the reference baselines" % len(plans))
    for k in ("MATCH", "UNPORTED", "FAIL", "CRASH"):
        print("  %-9s %d" % (k, counts[k]))
    print("  skipped   %d" % sum(skips.values()))
    for k, v in sorted(skips.items(), key=lambda kv: -kv[1]):
        print("    %-50s %d" % (k, v))
    if stops:
        print("  stops by tag:")
        for k, v in stops.most_common():
            print("    %-45s %d" % (k, v))
    fails = [v for v in verdicts if v[2] in ("FAIL", "CRASH")]
    if fails:
        print("  failures (first 40):")
        for c, cfg, v, d in fails[:40]:
            print("    %s %s%s: %s" % (v, c, ("(%s)" % cfg) if cfg else "", d))
    if args.verdicts:
        with open(args.verdicts, "w") as fh:
            for c, cfg, v, d in verdicts:
                fh.write("%s\t%s\t%s\t%s\n" % (c, cfg, v, d))
        print("wrote %d verdicts to %s" % (len(verdicts), args.verdicts))
    if args.show:
        want_case, _, want_cfg = args.show.partition(":")
        for plan in plans:
            if plan["case"] == want_case and plan["config"] == want_cfg:
                for vpath, un, oname in plan["units"]:
                    rc, body, err = answers.get(vpath, (None, b"", b""))
                    ours = body.decode("utf-8", "replace").replace("\r\n", "\n")
                    matches = [b for n, b in plan["outputs"] if n == oname]
                    expected = matches[0] if matches else ""
                    print("==== %s -> %s (options %s)" % (un, oname, plan["opts"]))
                    for line in difflib.unified_diff(expected.rstrip("\n").split("\n"), ours.rstrip("\n").split("\n"), "reference", "ours", lineterm=""):
                        print(line)
    return 0


if __name__ == "__main__":
    sys.exit(main())
