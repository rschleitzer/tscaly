#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""
casejs.py — THE DRIVER CHAPTER'S YARDSTICK (slice 243): the JavaScript the port emits
for a whole CASE under the case's own `// @option:` directives, against the reference's
OWN `.js` baseline per case — typescript-go's testdata/baselines/reference/submodule
(compiler/ and conformance/), the output its compiler runner accepted. The TypeScript
submodule's tests/baselines/reference are Strada's, and the `.js.diff` files beside the
reference's record where the two disagree (slice 244, §3.5jq 1).

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
import argparse, os, re, sqlite3, sys, itertools, collections, difflib, posixpath

HERE = os.path.dirname(os.path.abspath(__file__))
PKG = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import harness  # noqa: E402  (write_units_file, run_batch, parse_dump_stream)

TS = os.path.join(PKG, "_submodules", "typescript-go", "_submodules", "TypeScript")
# the reference keeps its OWN emitted baselines (compiler/ and conformance/ by case
# category); the TypeScript submodule's baselines are Strada's, and the `.js.diff`
# files there record where the two disagree. The port follows the reference.
TSGO_BASELINES = os.path.join(PKG, "_submodules", "typescript-go", "testdata", "baselines", "reference", "submodule")
TSGO_DIFFS = TSGO_BASELINES

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
    # the resolver's optional settings the port does not read (slice 248)
    for key in ("paths", "rootdirs", "modulesuffixes"):
        if cfg.get(key):
            return key
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
    if ext == ".json":
        return base
    if ext in (".mjs", ".cjs"):
        return base
    return None


def allow_js(cfg):
    """core.CompilerOptions.GetAllowJS: allowJs when set, else checkJs"""
    if cfg.get("allowjs", "").strip() != "":
        return cfg.get("allowjs", "").strip().lower() == "true"
    return cfg.get("checkjs", "").lower() == "true"


def declaration_on(cfg):
    """declaration, or composite (which implies it)"""
    return cfg.get("declaration", "").lower() == "true" or cfg.get("composite", "").lower() == "true"


def dts_output_name(unit_name, cfg):
    """GetDeclarationEmitOutputFilePath's name: `.mts` → `.d.mts`, `.cts` → `.d.cts`, else `.d.ts`;
    a JSON unit has none (slice 250)"""
    base = os.path.basename(unit_name)
    stem, ext = os.path.splitext(base)
    ext = ext.lower()
    if ext in (".ts", ".tsx", ".js", ".jsx"):
        return stem + ".d.ts"
    if ext in (".mts", ".mjs"):
        return stem + ".d.mts"
    if ext in (".cts", ".cjs"):
        return stem + ".d.cts"
    return None


def dts_program_path(ppath):
    """the dump's section name for a unit's declaration file: the program path with the
    extension replaced (Emitter.dts_name_of)"""
    stem, ext = posixpath.splitext(ppath)
    ext = ext.lower()
    if ext in (".mts", ".mjs"):
        return stem + ".d.mts"
    if ext in (".cts", ".cjs"):
        return stem + ".d.cts"
    return stem + ".d.ts"


def emitted(unit_name, cfg, all_roots=True):
    base = os.path.basename(unit_name)
    low = base.lower()
    if low.endswith(".d.ts") or low.endswith(".d.mts") or low.endswith(".d.cts") or re.search(r"\.d\.[^./]+\.ts$", low):
        return False
    # a unit under node_modules is an external library unless it is a ROOT file: the
    # runner passes every unit as a root (compiler_runner.go) unless the last unit makes
    # the rest non-root, and a root's lowest include depth is 0, so it is never
    # IsSourceFileFromExternalLibrary (slice 253; until then it was never emitted)
    if "/node_modules/" in ("/" + unit_name.replace("\\", "/").lower()) and not all_roots:
        return False
    ext = os.path.splitext(low)[1]
    if ext in (".ts", ".tsx", ".mts", ".cts"):
        return True
    if ext in (".js", ".jsx", ".mjs", ".cjs"):
        return allow_js(cfg)
    # a JSON module is emitted (copied) only into an outDir (compiler/emitter.go sourceFileMayBeEmitted)
    if ext == ".json":
        return bool(cfg.get("outdir"))
    return False


def parse_baseline(text):
    """→ (header, [(name, content)]) of a `.js` baseline, CRLF normalized."""
    text = text.replace("\r\n", "\n")
    # js_emit_baseline.go appends the declaration files with NO separator, so a
    # `.d.ts` ending in its map comment runs into the next header (slice 254)
    text = re.sub(r"(//# sourceMappingURL=[^\n]*?)(//// \[)", r"\1\n\2", text)
    # a name may carry `]` (sourceMapPercentEncoded): the shortest name the line's end accepts
    parts = re.split(r"^//// \[([^\n]*?)\]( ////)?\n", text, flags=re.M)
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


def input_section_count(sections, units):
    """how many of the split sections the input files take: one each, unless a file's
    own text carries `//// [name]` lines, which the split cut at (the section is joined
    back until it is the file's text)"""
    contents = []
    for _, c in units:
        text = c.decode("utf-8", "replace") if isinstance(c, bytes) else c
        contents.append(text.replace("\r\n", "\n").rstrip("\n"))
    i = 0
    for _ in units:
        if i >= len(sections):
            break
        body = sections[i][1]
        j = i
        while body.rstrip("\n") not in contents and j + 1 < len(sections):
            probe = body + "//// [%s]\n" % sections[j + 1][0] + sections[j + 1][1]
            if not any(c.startswith(probe.rstrip("\n")) for c in contents):
                break
            j += 1
            body = probe
        if body.rstrip("\n") not in contents:
            return len(units)
        i = j + 1
    return i


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
    while text:
        nl = text.find("\n")
        first = text if nl < 0 else text[:nl]
        # a blank line before the first content line is dropped too (test_case_parser.go
        # writes a newline only once the file has content)
        if OPTION_RE.match(first) or first.rstrip("\r") == "":
            text = "" if nl < 0 else text[nl + 1:]
        else:
            break
    return text.encode("utf-8")


def common_source_directory(units, cfg):
    """outputpaths.GetCommonSourceDirectory: rootDir, else the longest common directory of the
    non-declaration source units (a single file's directory when there is one)"""
    if cfg.get("rootdir"):
        return posixpath.normpath(posixpath.join(ROOT, cfg["rootdir"].replace("\\", "/")))
    # a config file's directory (slice 261)
    if cfg.get("configfilepath"):
        return posixpath.dirname(cfg["configfilepath"])
    dirs = []
    for n, _ in units:
        low = n.lower()
        if low.endswith(".d.ts") or low.endswith(".d.mts") or low.endswith(".d.cts") or low.endswith(".json"):
            continue
        dirs.append(posixpath.dirname(program_path(n)))
    if not dirs:
        return ROOT
    common = dirs[0]
    for d in dirs[1:]:
        while not (d == common or d.startswith(common.rstrip("/") + "/")):
            up = posixpath.dirname(common)
            if up == common or up in ("", "/"):
                # no common directory (a drive-letter unit beside a rooted one): the root
                return "/"
            common = up
    return common


def remove_test_path_prefixes(text):
    """tsbaseline.removeTestPathPrefixes (a strings.Replacer: the leftmost match wins)"""
    pairs = [("/.ts/", ""), ("/.lib/", ""), ("/.src/", ""), ("bundled:///libs/", ""),
             ("file:///./ts/", "file:///"), ("file:///./lib/", "file:///"), ("file:///./src/", "file:///")]
    out, i = [], 0
    while i < len(text):
        for old, repl in pairs:
            if text.startswith(old, i):
                out.append(repl)
                i += len(old)
                break
        else:
            out.append(text[i])
            i += 1
    return "".join(out)


def section_name(unit_name, cfg, common, oname, out_dir):
    """the baseline's section name: the bare output name, or under @fullEmitPaths the
    emitted file's full path without the test prefixes (js_emit_baseline.go fileOutput;
    the path by outputpaths.GetSourceFilePathInNewDir)"""
    if cfg.get("fullemitpaths", "").lower() != "true":
        return oname
    out_dir = (out_dir or "").replace("\\", "/")
    if out_dir:
        rel = posixpath.relpath(posixpath.dirname(program_path(unit_name)), common) if common else "."
        full = posixpath.normpath(posixpath.join(ROOT, out_dir, rel, os.path.basename(oname)))
    else:
        full = posixpath.normpath(posixpath.join(posixpath.dirname(program_path(unit_name)), os.path.basename(oname)))
    return remove_test_path_prefixes(full)


def output_path(unit_name, cfg, common):
    oname = output_name(unit_name, cfg)
    if oname is None:
        return None
    return section_name(unit_name, cfg, common, oname, cfg.get("outdir"))


def dts_output_path(unit_name, cfg, common):
    """the declaration file's section name: under declarationDir, else outDir"""
    oname = dts_output_name(unit_name, cfg)
    if oname is None:
        return None
    return section_name(unit_name, cfg, common, oname, cfg.get("declarationdir") or cfg.get("outdir"))


# the runner's current directory (`@currentDirectory`, default /.src), set per
# configuration before a plan is built (slice 260)
ROOT = "/.src"


def program_path_at(default_root, settings, unit_name):
    """a unit's program path under the case's own current directory"""
    root = posixpath.normpath(posixpath.join(default_root, settings.get("currentdirectory", "").strip()))
    name = unit_name.replace("\\", "/")
    if name.startswith("/") or re.match(r"^[A-Za-z]:/", name):
        return posixpath.normpath(name)
    return posixpath.normpath(posixpath.join(root, name))


def program_path(unit_name):
    """the unit's path in the program: ROOT/<unit>, an absolute name standing"""
    name = unit_name.replace("\\", "/")
    # a rooted name stands (tspath.GetNormalizedAbsolutePath: `/x.ts`, `A:/x.ts`)
    if name.startswith("/") or re.match(r"^[A-Za-z]:/", name):
        return posixpath.normpath(name)
    return posixpath.normpath(posixpath.join(ROOT, name))


NOCHECK_MISSING_RE = re.compile(r"\r?\n\r?\n!!!! File ([^\r\n]*?) missing from original emit, but present in noCheck emit\r?\n")

BUNDLE_HEAD = b"==== TSCALY-FILE "


def split_bundle_answer(body):
    """the dump's answer for a bundle → {program path: that unit's bytes}"""
    out = {}
    parts = body.split(BUNDLE_HEAD)
    for part in parts[1:]:
        nl = part.find(b"\n")
        if nl < 0:
            continue
        out[part[:nl].decode("utf-8", "surrogateescape")] = part[nl + 1:]
    return out


# option VALUES that are text, not an enum: the case decides (`jsxFactory: h`, `reactNamespace: myReactLib`)
TEXT_OPTIONS = {"configfilepath", "maproot", "sourceroot", "jsxfactory", "jsxfragmentfactory", "reactnamespace", "jsximportsource", "emitfilename", "currentdirectory", "customconditions", "typeroots"}

# test_case_parser.go's linkRegex: `// @link: <target> -> <symlink>`
LINK_RE = re.compile(r"^/{2}\s*@link\s*:\s*([^\r\n]*?)\s*->\s*([^\r\n]*)", re.M | re.I)
FILENAME_RE = re.compile(r"^//\s*@filename\s*:\s*([^\r\n]*)", re.I)
SYMLINK_RE = re.compile(r"^//\s*@symlink\s*:\s*([^\r\n]*)", re.I)


def case_links(text):
    """[(symlink, target)] of a case: `@link: target -> symlink`, and a file's own
    `@symlink: a, b` naming symlinks to the file declared above it"""
    links = []
    current = ""
    for line in text.splitlines():
        m = FILENAME_RE.match(line)
        if m:
            current = m.group(1).strip()
            continue
        m = LINK_RE.match(line)
        if m:
            links.append((m.group(2).strip(), m.group(1).strip()))
            continue
        m = SYMLINK_RE.match(line)
        if m and current:
            for link in m.group(1).split(","):
                if link.strip():
                    links.append((link.strip(), current))
    return links


def options_string(cfg):
    items = dict(cfg)
    if allow_js(cfg) and "allowjs" not in items:
        items["allowjs"] = "true"     # GetAllowJS: checkJs implies an unset allowJs
    return ";".join("%s=%s" % (k, str(v).strip() if k in TEXT_OPTIONS else str(v).strip().lower()) for k, v in sorted(items.items()))


def n_is_json(unit_name):
    return unit_name.lower().endswith(".json")


def is_config_unit(unit_name):
    """harnessutil.GetConfigNameFromFileName"""
    return os.path.basename(unit_name.replace("\\", "/")).lower() in ("tsconfig.json", "jsconfig.json")


def stack_wrapper(args):
    """the dump under the stack tests/run.sh sets (a 40 KB binary-expression chain is a
    SIGSEGV at the default 8 MB): raised once in THIS process, which every dump inherits
    — a shell wrapper per chunk was a script file and a second exec per process"""
    import resource
    soft, hard = resource.getrlimit(resource.RLIMIT_STACK)
    want = 65520 * 1024
    if hard != resource.RLIM_INFINITY:
        want = min(want, hard)
    if soft == resource.RLIM_INFINITY or soft < want:
        resource.setrlimit(resource.RLIMIT_STACK, (want, hard))
    return os.path.abspath(args.binary)


def read_tsconfigs(args, case_rows):
    """test_case_parser.go's tsconfig read for every case carrying one, answered by
    `tscaly_dump --tsconfig=` (slice 261) → {case: (options {lower name: value}, [root
    file names])} or {case: ("STOP", detail)}"""
    groups = collections.defaultdict(list)
    for ci, name, case_file, stem, text, settings, links, units in case_rows:
        if not any(is_config_unit(n) for n, _ in units):
            continue
        parts = []
        for un, content in units:
            body = content if isinstance(content, bytes) else content.encode("utf-8", "surrogateescape")
            parts.append(b"==== TSCALY-FILE %d 0 %s\n" % (len(body), un.encode("utf-8", "surrogateescape")))
            parts.append(body)
            parts.append(b"\n")
        groups[settings.get("currentdirectory", "").strip()].append(("/tsconfig/" + name, b"".join(parts)))
    out = {}
    binary = stack_wrapper(args)
    ordered = sorted(groups.items())
    res = harness.run_batch_groups(binary, [("--tsconfig=" + (("currentdirectory=" + cwd) if cwd else ""), items, os.path.join(args.scratch, "t%d" % gi))
                                            for gi, (cwd, items) in enumerate(ordered)], args.jobs, args.timeout)
    for cwd, items in ordered:
        for vpath, _ in items:
            name = vpath[len("/tsconfig/"):]
            rc, body, err = res.get(vpath, (None, b"", b""))
            text = body.decode("utf-8", "replace")
            if rc != 0:
                out[name] = ("STOP", "tsconfig reader rc %s" % rc)
                continue
            if text.startswith("UNPORTED "):
                out[name] = ("STOP", text.split("\n")[0])
                continue
            options, files = {}, []
            for line in text.split("\n"):
                if line.startswith("TSCONFIG-OPTION "):
                    k, _, v = line[len("TSCONFIG-OPTION "):].partition("\t")
                    options[k.lower()] = v
                elif line.startswith("TSCONFIG-FILE "):
                    files.append(line[len("TSCONFIG-FILE "):])
            out[name] = (options, files)
    return out


def main():
    global ROOT
    ap = argparse.ArgumentParser()
    ap.add_argument("--store", default=os.path.join(PKG, "tests", "out", "run.db"))
    ap.add_argument("--binary", default=os.path.join(PKG, "tests", "out", "tscaly_dump"))
    ap.add_argument("--filter", default="")
    ap.add_argument("--only", default="", help="a file naming one case per line: run those cases alone (a probe run, seconds instead of minutes)")
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
    groups = collections.defaultdict(list)
    dts_error_pairs = [0]   # options string → [(vpath, content)]
    only = None
    if args.only:
        only = set(l.strip() for l in open(args.only) if l.strip())
    case_rows = []
    for ci, name, case_file in cases:
        if args.filter and args.filter not in name:
            continue
        if only is not None and name not in only:
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
        settings.pop("link", None)
        settings.pop("symlink", None)
        links = case_links(text)
        units = db.execute("SELECT name, content FROM units WHERE ci=? ORDER BY idx", (ci,)).fetchall()
        units = [(n, strip_directives(c)) for n, c in units]
        case_rows.append((ci, name, case_file, stem, text, settings, links, units))
    # test_case_parser.go: a case with a tsconfig.json takes its options and its root
    # files from the config (slice 261)
    tsconfigs = read_tsconfigs(args, case_rows)
    for ci, name, case_file, stem, text, settings, links, units in case_rows:
        config = tsconfigs.get(name)
        if config is not None and config[0] == "STOP":
            skips["tsconfig reader: " + config[1][:60]] += 1
            continue
        # a name declared twice is ONE file to the reference (a map by path; the last content wins)
        last = {}
        for i, (n, c) in enumerate(units):
            last[n] = i
        # ★ harnessutil.CompileFilesEx writes toBeCompiled, then otherFiles, into the map:
        # when the last unit is the only root (a `require(` or a reference in it) an
        # earlier unit of its name is an OTHER file and its content is the one read
        # (augmentExportEquals2)
        content_of = {}
        # the root rule reads the last unit AS WRITTEN
        tail_units = units[-1:]
        if units and config is None:
            tail_text = units[-1][1].decode("utf-8", "replace") if isinstance(units[-1][1], bytes) else units[-1][1]
            if re.search(r"require\(", tail_text) or re.search(r"reference\s+path", tail_text):
                tail_name = units[-1][0]
                earlier = [c for n, c in units[:-1] if n == tail_name]
                if earlier:
                    content_of[tail_name] = earlier[-1]
        units = [(n, content_of.get(n, c)) for i, (n, c) in enumerate(units) if last[n] == i]
        # the config's unit is not a file of the program, nor an input section of the
        # JS baseline (compiler_runner.go: toBeCompiled + otherFiles); its first match
        # is the config
        config_index = next((i for i, (n, _) in enumerate(units) if is_config_unit(n)), None) if config is not None else None
        program_units = [u for i, u in enumerate(units) if i != config_index]
        for cname, cfg in configurations(settings):
            if config is not None:
                # harnessutil.CompileFiles: the config's options, the case's settings over them
                merged = dict(config[0])
                merged["configfilepath"] = program_path_at("/.src", settings, units[config_index][0])
                merged.update(cfg)
                cfg = merged
            bname = stem + ("(%s)" % cname if cname else "") + ".js"
            key = (name, cname)
            reason = unsupported(cfg)
            if reason:
                skips["unsupported: " + reason] += 1
                continue
            # GetNormalizedAbsolutePath(currentDirectory, "/.src")
            ROOT = posixpath.normpath(posixpath.join("/.src", cfg.get("currentdirectory", "").strip()))
            category = "conformance" if name.startswith("submodule_conformance_") else "compiler"
            bpath = os.path.join(TSGO_BASELINES, category, bname)
            if not os.path.exists(bpath):
                skips["no baseline"] += 1
                continue
            if bname in diff_names:
                skips["(reference differs from Strada here; its own baseline is compared)"] += 1
            if cfg.get("noemit", "").lower() == "true":
                skips["noEmit"] += 1
                continue
            with open(bpath, "rb") as fh:
                btext = fh.read().decode("utf-8", "replace")
            # js_emit_baseline.go's noCheck comparison: a file the emit did not write
            # (noEmitOnError) but the noCheck emit did is baselined after a note; the
            # notes are read off and the sections compared as outputs (slice 262)
            nocheck_missing = set(os.path.basename(m) for m in NOCHECK_MISSING_RE.findall(btext))
            btext = NOCHECK_MISSING_RE.sub("", btext)
            header, sections = parse_baseline(btext)
            n_inputs = len(program_units)
            outputs = sections[input_section_count(sections, program_units):]
            if args.refute:
                outputs = [(n, b + "x") for n, b in outputs]
            if any(n.startswith("!!!!") for n, _ in outputs) or "\n!!!! File " in btext:
                skips["baseline carries a noCheck emit difference"] += 1
                continue
            # the declaration files' own type check (`//// [DtsFileErrors]`, the runner
            # re-checking the emitted .d.ts): the sections before it are compared, the
            # errors themselves are not (slice 260)
            dts_errors = [i for i, (n, _) in enumerate(outputs) if n == "DtsFileErrors"]
            if dts_errors:
                outputs = outputs[:dts_errors[0]]
                dts_error_pairs[0] += 1
            last_content0 = tail_units[-1][1] if tail_units else b""
            last_text0 = last_content0.decode("utf-8", "replace") if isinstance(last_content0, bytes) else last_content0
            all_roots = not bool(re.search(r"require\(", last_text0) or re.search(r"reference\s+path", last_text0) or cfg.get("noimplicitreferences"))
            config_roots = set(config[1]) if config is not None else None

            def is_root(un):
                if config_roots is not None:
                    return program_path(un) in config_roots
                return all_roots
            to_emit = [(n, c) for n, c in program_units if emitted(n, cfg, is_root(n))]
            # compiler_runner.go: when the LAST unit carries a `require(` or a triple-slash
            # reference, it is the only root file and the rest reach the program through
            # references — a unit the reference did not emit was not in the program; and a
            # JSON unit is never a root file (harnessutil), it is emitted only when imported.
            # Both are read off the baseline's section list (WHICH files, never their content).
            section_names = set(n for n, _ in outputs)
            last_content = tail_units[-1][1] if tail_units else b""
            last_text = last_content.decode("utf-8", "replace") if isinstance(last_content, bytes) else last_content
            last_is_root_only = bool(re.search(r"require\(", last_text) or re.search(r"reference\s+path", last_text) or cfg.get("noimplicitreferences"))
            common = common_source_directory(program_units, cfg)

            def planned_without_section(un):
                if n_is_json(un):
                    return False
                if config_roots is not None:
                    return program_path(un) in config_roots
                return not last_is_root_only
            # ★ a declaration section counts as well: under emitDeclarationOnly the baseline
            # has no JS section at all (slice 258)
            to_emit = [(n, c) for n, c in to_emit if (output_path(n, cfg, common) in section_names) or (declaration_on(cfg) and dts_output_path(n, cfg, common) in section_names) or planned_without_section(n)]
            opts = options_string(cfg)
            # one BUNDLE per (case, configuration): every unit, rooted at /.src as the
            # reference's runner roots them, the emitted ones flagged (slice 248)
            vpath = "/cases/%s/%s" % (name, cname or "default")
            plan = {"case": name, "config": cname, "opts": opts, "vpath": vpath, "units": [], "outputs": outputs, "baseline": bname, "nocheck_missing": nocheck_missing}
            parts = []
            for un, content in program_units:
                body = content if isinstance(content, bytes) else content.encode("utf-8", "surrogateescape")
                parts.append(b"==== TSCALY-FILE %d %d %s\n" % (len(body), 1 if emitted(un, cfg, is_root(un)) else 0, un.encode("utf-8", "surrogateescape")))
                parts.append(body)
                parts.append(b"\n")
            for symlink, target in links:
                parts.append(b"==== TSCALY-LINK %s\t%s\n" % (program_path(symlink).encode("utf-8", "surrogateescape"), program_path(target).encode("utf-8", "surrogateescape")))
            groups[opts].append((vpath, b"".join(parts)))
            common = common_source_directory(program_units, cfg)
            # the JS outputs, unless emitDeclarationOnly; the declaration outputs under
            # declaration/composite (slice 250) — each entry carries its KIND
            if cfg.get("emitdeclarationonly", "").lower() != "true":
                input_paths = set(program_path(n) for n, _ in program_units)

                def js_full_path(un):
                    oname = output_name(un, cfg)
                    if oname is None:
                        return None
                    js_out_dir = (cfg.get("outdir") or "").replace("\\", "/")
                    if js_out_dir:
                        rel = posixpath.relpath(posixpath.dirname(program_path(un)), common) if common else "."
                        return posixpath.normpath(posixpath.join(ROOT, js_out_dir, rel, os.path.basename(oname)))
                    return posixpath.normpath(posixpath.join(posixpath.dirname(program_path(un)), os.path.basename(oname)))
                js_targets = collections.Counter(js_full_path(un) for un, _ in to_emit)
                for un, content in to_emit:
                    js_full = js_full_path(un)
                    # a JS output that would overwrite an input (TS5055: a `.js` unit
                    # without outDir) or that several inputs would write (TS5056) is
                    # not written (slice 257)
                    if js_full is not None and (js_full in input_paths or js_targets[js_full] > 1):
                        continue
                    plan["units"].append((program_path(un), un, output_path(un, cfg, common), "js"))
            if declaration_on(cfg):
                # the program's files: under a config its roots and what the plan emits
                # (a unit outside `include` is not an input a declaration overwrites)
                if config_roots is not None:
                    unit_paths = set(config_roots) | set(program_path(n) for n, _ in to_emit)
                else:
                    unit_paths = set(program_path(n) for n, _ in program_units)
                for un, content in to_emit:
                    dname = dts_output_path(un, cfg, common)
                    # a declaration output that would overwrite an input is not written
                    # (the driver's overwrite error) — compared as FULL paths (slice 253:
                    # by base name, `index.d.ts` beside `node_modules/inner/index.d.ts` was
                    # never planned)
                    if dname is None:
                        continue
                    out_dir = (cfg.get("declarationdir") or cfg.get("outdir") or "").replace("\\", "/")
                    if out_dir:
                        rel = posixpath.relpath(posixpath.dirname(program_path(un)), common) if common else "."
                        full = posixpath.normpath(posixpath.join(ROOT, out_dir, rel, os.path.basename(dname)))
                    else:
                        full = dts_program_path(program_path(un))
                    if full not in unit_paths:
                        plan["units"].append((dts_program_path(program_path(un)), un, dname, "dts"))
            plans.append(plan)

    # ── run: one batch per configuration string ──
    answers = {}
    binary = stack_wrapper(args)
    total_units = sum(len(v) for v in groups.values())
    print("pairs whose DtsFileErrors section is not compared: %d" % dts_error_pairs[0])
    print("cases planned %d, configurations skipped %d, units to emit %d in %d option groups" % (
        len(plans), sum(skips.values()), total_units, len(groups)), flush=True)
    answers.update(harness.run_batch_groups(binary, [("--emit=" + opts, units, os.path.join(args.scratch, "g%d" % gi))
                                                     for gi, (opts, units) in enumerate(sorted(groups.items()))], args.jobs, args.timeout))

    # ── verdicts ──
    verdicts = []
    counts = collections.Counter()
    stops = collections.Counter()
    for plan in plans:
        verdict, detail = "MATCH", ""
        used = {}
        rc, body, err = answers.get(plan["vpath"], (None, b"", b""))
        sections = split_bundle_answer(body)
        for ppath, un, oname, okind in plan["units"]:
            if rc is None:
                verdict, detail = "CRASH", "no answer for %s" % un
                break
            if rc != 0:
                # the last line of stderr names the trap (an exit 21 names its symbol)
                last = err.decode("utf-8", "replace").strip().split("\n")[-1][:160] if err else ""
                verdict, detail = "CRASH", "rc %s on %s: %s" % (rc, un, last)
                break
            skipped_on_error = "TSCALY-NOEMITONERROR" in sections
            if skipped_on_error != bool(plan["nocheck_missing"]) or (skipped_on_error and os.path.basename(oname) not in plan["nocheck_missing"]):
                verdict, detail = "FAIL", ("emit skipped on error here, not by the reference" if skipped_on_error else "the reference skipped the emit on error (noEmitOnError)")
                break
            if body.startswith(b"UNPORTED "):
                verdict, detail = "UNPORTED", body.decode("utf-8", "replace").split("\n")[0]
                break
            if ppath not in sections:
                verdict, detail = "CRASH", "no answer for %s" % un
                break
            ours = sections[ppath].decode("utf-8", "replace")
            if ours.startswith("UNPORTED "):
                verdict, detail = "UNPORTED", ours.split("\n")[0]
                break
            if okind == "dts" and ours.startswith("TSCALY-DECLARATION-BLOCKED"):
                # the file's declaration emit reported: the reference writes no .d.ts
                # for it, so the baseline must carry no section of that name
                # ★ another planned output of the same name (a node_modules unit's
                # `index.d.ts` beside a root `index.d.ts`) owns one such section each
                same_named = sum(1 for n, _ in plan["outputs"] if n == oname)
                others = sum(1 for p2, u2, o2, k2 in plan["units"] if o2 == oname and u2 != un)
                if same_named > others:
                    verdict, detail = "FAIL", "%s: declaration emit blocked here, emitted by the reference" % oname
                    break
                continue
            # the output sections of that name: the reference writes them in ITS program
            # order (an imported file before its importer), so a same-named section is
            # matched by content — any not-yet-taken section that equals ours (slice 248)
            matches = [(i, b) for i, (n, b) in enumerate(plan["outputs"]) if n == oname and i not in used]
            if not matches:
                verdict, detail = "FAIL", "no output section %s in the baseline" % oname
                break
            ours_text = ours.replace("\r\n", "\n").rstrip("\n")
            hit = [i for i, b in matches if b.rstrip("\n") == ours_text]
            if not hit:
                # an output whose own text carries `//// [name]` lines was split there
                # (scannerNonAsciiHorizontalWhitespace): a run of sections joined back
                for i, _ in matches:
                    run = plan["outputs"][i][1]
                    for j in range(i + 1, len(plan["outputs"])):
                        n2, b2 = plan["outputs"][j]
                        run = run + "//// [%s]\n" % n2 + b2
                        if run.rstrip("\n") == ours_text:
                            hit = [i]
                            for k in range(i + 1, j + 1):
                                used[k] = True
                            break
                    if hit:
                        break
            if not hit:
                used[matches[0][0]] = True
                verdict, detail = "FAIL", oname
                break
            used[hit[0]] = True
        if verdict == "MATCH":
            # a declaration section the plan did not cover (a case whose baseline carries
            # one under a directive the planner does not read) is not a match
            planned = set(oname for _, _, oname, okind in plan["units"] if okind == "dts")
            stray = [n for n, _ in plan["outputs"] if (n.endswith(".d.ts") or n.endswith(".d.mts") or n.endswith(".d.cts")) and n not in planned]
            if stray:
                verdict, detail = "UNPORTED", "UNPORTED 1 emit-declaration-unplanned 0"
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
                rc, body, err = answers.get(plan["vpath"], (None, b"", b""))
                sections = split_bundle_answer(body)
                shown = {}
                for ppath, un, oname, okind in plan["units"]:
                    ours = sections.get(ppath, body).decode("utf-8", "replace").replace("\r\n", "\n")
                    matches = [(i, b) for i, (n, b) in enumerate(plan["outputs"]) if n == oname and i not in shown]
                    hit = [(i, b) for i, b in matches if b.rstrip("\n") == ours.rstrip("\n")]
                    pick = hit[0] if hit else (matches[0] if matches else (None, ""))
                    if pick[0] is not None:
                        shown[pick[0]] = True
                    expected = pick[1]
                    print("==== %s -> %s (options %s)" % (un, oname, plan["opts"]))
                    for line in difflib.unified_diff(expected.rstrip("\n").split("\n"), ours.rstrip("\n").split("\n"), "reference", "ours", lineterm=""):
                        print(line)
    return 0


if __name__ == "__main__":
    sys.exit(main())
