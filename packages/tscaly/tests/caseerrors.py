#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""
caseerrors.py — THE CASE DIAGNOSTICS YARDSTICK (slice 263): the diagnostics the port
reports for a whole CASE under the case's own configuration, against the reference's
`.errors.txt` baseline per case and configuration (testdata/baselines/reference/
submodule/{compiler,conformance}) — its header lines `file(line,col): error TSn: …` and
`error TSn: …`.

casejs.py's sibling: the same cases, configurations, skips, tsconfig reading and bundles,
answered by `tscaly_dump --errors=<options> --batch`, which prints each program file's
raw diagnostics (D parse, J JS-only parse, B bind, C checker, K the file's checkJs
directive). The program's composition — compiler/program.go's GetSyntacticDiagnostics and
getBindAndCheckDiagnosticsWithChecker (SkipTypeChecking, the plain-JS filter) — is applied
here until the port carries it. A diagnostic is compared as (file, line, column, code): the
port has no message text. A configuration whose test ran (a `.js`, `.types`, `.symbols` or
`.errors.txt` baseline exists) and has no `.errors.txt` expects none.

Usage:
  tests/caseerrors.py [--binary tests/out/tscaly_dump] [--filter S] [--only FILE]
                      [--jobs N] [--verdicts FILE] [--show CASE[:CONFIG]]
"""
import argparse, bisect, collections, os, re, sqlite3, sys

HERE = os.path.dirname(os.path.abspath(__file__))
PKG = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import casejs  # noqa: E402
import harness  # noqa: E402

HEADER_RE = re.compile(r"^(.+?)\((\d+),(\d+)\): (error|warning|message) TS(\d+): ")
GLOBAL_RE = re.compile(r"^(error|warning|message) TS(\d+): ")
ANSI_RE = re.compile(r"\x1b\[[0-9;]*m")
PRETTY_RE = re.compile(r"^(\S.*?):(\d+):(\d+) - (error|warning|message) TS(\d+): ")
PRETTY_GLOBAL_RE = re.compile(r"^(error|warning|message) TS(\d+): ")

# compiler/program.go plainJSErrors, read in place: the message names mapped to their codes through
# diagnostics_generated.go (a hand-copied list had lost 23 of the 91)
def plain_js_errors():
    ref = os.path.join(PKG, "_submodules", "typescript-go", "internal")
    src = open(os.path.join(ref, "compiler", "program.go")).read()
    block = src[src.index("var plainJSErrors = collections.NewSetFromItems("):]
    block = block[:block.index("\n)")]
    gen = open(os.path.join(ref, "diagnostics", "diagnostics_generated.go")).read()
    codes = {m.group(1): int(m.group(2)) for m in re.finditer(r"^var (\w+) = &Message\{code: (\d+)", gen, re.M)}
    return {codes[n] for n in re.findall(r"diagnostics\.(\w+)\.Code\(\)", block)}


PLAIN_JS_ERRORS = plain_js_errors()


def message_templates():
    """code → message text, from diagnostics_generated.go (phase (b)1: the dump prints arguments)"""
    gen = open(os.path.join(PKG, "_submodules", "typescript-go", "internal", "diagnostics", "diagnostics_generated.go")).read()
    out = {}
    for m in re.finditer(r'^var \w+ = &Message\{code: (\d+),.*?text: "((?:[^"\\]|\\.)*)"', gen, re.M):
        out[int(m.group(1))] = bytes(m.group(2), "utf-8").decode("unicode_escape").encode("latin-1").decode("utf-8")
    return out


TEMPLATES = message_templates()
PLACEHOLDER_RE = re.compile(r"{(\d+)}")


def format_message(code, args):
    """diagnostics.Format (no arguments leaves the text as it is), then the baseline's
    removeTestPathPrefixes over the summary text"""
    text = TEMPLATES.get(code, "")
    if args:
        text = PLACEHOLDER_RE.sub(lambda m: args[int(m.group(1))] if int(m.group(1)) < len(args) else m.group(0), text)
    return casejs.remove_test_path_prefixes(text)


class Args(tuple):
    """a diagnostic's message arguments, carrying its message chain: [(level, code, args)]
    and its related information: [[path, pos, code, args]]"""
    chain = ()
    related = ()


RELATED_RE = re.compile(r"^!!! related TS(\d+)(?: ([^:]+:(?:\d+|--):(?:\d+|--)))?: (.*)$")


def expected_related(path):
    """the error baseline's `!!! related` lines → Counter of (code, location, first message
    line); the harness's own pre/post-emit count report (TS-1) and its lines are left out"""
    out = collections.Counter()
    if not os.path.exists(path):
        return out
    with open(path, "rb") as fh:
        text = fh.read().decode("utf-8", "replace").replace("\r\n", "\n")
    harness = False
    for line in text.split("\n"):
        if line.startswith("!!! error TS"):
            harness = line.startswith("!!! error TS-1:")
            continue
        m = RELATED_RE.match(line)
        if m and not harness:
            out[(int(m.group(1)), m.group(2) or "", m.group(3))] += 1
    return out


def related_location(plan, path, pos):
    """formatLocation after removeTestPathPrefixes, a default lib's line and column hidden"""
    if not path:
        return ""
    base = path.rsplit("/", 1)[-1]
    if base.lower().startswith("lib.") and base.lower().endswith(".d.ts"):
        return base + ":--:--"
    text = plan["texts"].get(path)
    if text is None and path.startswith("/.lib/"):
        disk = os.path.join(PKG, "_submodules", "typescript-go", "_submodules", "TypeScript", "tests", "lib", path[len("/.lib/"):])
        if os.path.exists(disk):
            text = open(disk, "rb").read()
            plan["texts"][path] = text
    if text is None:
        return casejs.remove_test_path_prefixes(path) + ":?:?"
    line, col = line_col(text, pos)
    return "%s:%d:%d" % (casejs.remove_test_path_prefixes(path), line, col)


def full_message(code, margs):
    """the head message and its chain, as WriteFlattenedDiagnosticMessage writes them"""
    text = format_message(code, margs)
    for level, ccode, cargs in getattr(margs, "chain", ()):
        text += "\n" + "  " * level + format_message(ccode, cargs)
    return text


def unescape_args(field):
    out = []
    for a in field.split("\x1f"):
        b, i = [], 0
        while i < len(a):
            if a[i] == "\\" and i + 1 < len(a):
                b.append({"n": "\n", "r": "\r", "t": "\t"}.get(a[i + 1], a[i + 1]))
                i += 2
            else:
                b.append(a[i])
                i += 1
        out.append("".join(b))
    return tuple(out)


def expected_errors(path, messages=None, chains=None):
    """→ Counter of (file, line, col, code); file "" for a global diagnostic. With `messages`
    (a Counter) also the (key, head message text) pairs, with `chains` the (key, head and
    chain text) pairs — None for a pretty baseline, whose chain lines sit among excerpts"""
    out = collections.Counter()
    if messages is None:
        messages = collections.Counter()
    if chains is None:
        chains = collections.Counter()
    if not os.path.exists(path):
        return out
    with open(path, "rb") as fh:
        text = fh.read().decode("utf-8", "replace").replace("\r\n", "\n")
    current = []
    def flush():
        if current:
            chains[(current[0], "\n".join(current[1:]))] += 1
            del current[:]
    for line in text.split("\n"):
        if line.startswith("==== "):
            break
        if current and line.startswith("  "):
            current.append(line)
            continue
        flush()
        # `@pretty: true`: `file:line:col - error TSn:` in ANSI colours (slice 269)
        plain = ANSI_RE.sub("", line)
        m = PRETTY_RE.match(plain)
        if m:
            key = (m.group(1), int(m.group(2)), int(m.group(3)), int(m.group(5)))
            out[key] += 1
            messages[(key, plain[m.end():])] += 1
            continue
        m = PRETTY_GLOBAL_RE.match(plain) if plain != line else None
        if m:
            key = ("", 0, 0, int(m.group(2)))
            out[key] += 1
            messages[(key, plain[m.end():])] += 1
            continue
        m = HEADER_RE.match(line)
        if m:
            key = (m.group(1), int(m.group(2)), int(m.group(3)), int(m.group(5)))
            out[key] += 1
            messages[(key, line[m.end():])] += 1
            current[:] = [key, line[m.end():]]
            continue
        m = GLOBAL_RE.match(line)
        if m:
            key = ("", 0, 0, int(m.group(2)))
            out[key] += 1
            messages[(key, line[m.end():])] += 1
            current[:] = [key, line[m.end():]]
    flush()
    return out


def line_col(text_bytes, pos):
    """scanner.GetECMALineAndCharacterOfPosition, 1-based: ECMA line breaks, UTF-16 columns"""
    head = text_bytes[:max(pos, 0)].decode("utf-8", "replace")
    line, start = 0, 0
    i = 0
    while i < len(head):
        ch = head[i]
        if ch == "\r":
            if i + 1 < len(head) and head[i + 1] == "\n":
                i += 1
            line += 1
            start = i + 1
        elif ch in "\n\u2028\u2029":
            line += 1
            start = i + 1
        i += 1
    col = len(head[start:].encode("utf-16-le")) // 2
    return line + 1, col + 1


def parse_answer(body):
    """the dump's answer → {path: {"K": int, "D": [...], "J": [...], "B": [...], "C": [...]}}"""
    files = {}
    cur = None
    last = None
    for line in body.decode("utf-8", "replace").split("\n"):
        if line.startswith("==== TSCALY-FILE "):
            cur = {"K": 0, "D": [], "J": [], "B": [], "C": [], "R": [], "S": [], "P": [], "G": [], "X": []}
            files[line[len("==== TSCALY-FILE "):]] = cur
            last = None
            continue
        if cur is None or len(line) < 2:
            continue
        head, _, argfield = line[2:].partition("\t")
        tag, rest = line[0], head.split()
        if tag == "K":
            cur["K"] = int(rest[0])
        elif tag in "DJBCRSPGX" and len(rest) == 3:
            args = Args(unescape_args(argfield) if _ else ())
            cur[tag].append(tuple(int(x) for x in rest) + (args,))
            last = args
        elif tag == "L" and len(head.split(" ", 3)) >= 3 and last is not None:
            fields = head.split(" ", 3)
            last.related = tuple(last.related) + ([fields[3] if len(fields) > 3 else "", int(fields[0]), int(fields[2]), unescape_args(argfield) if _ else ()],)
        elif tag == "N" and len(rest) == 2 and last is not None and last.related:
            pass
        elif tag == "M" and len(rest) == 2 and last is not None:
            # a chain line of the diagnostic before it: `M <level> <code>\targs`
            last.chain = tuple(last.chain) + ((int(rest[0]), int(rest[1]), unescape_args(argfield) if _ else ()),)
    return files


def ecma_line_starts(text):
    """scanner.GetECMALineStarts over the UTF-8 bytes: CR LF, CR, LF, U+2028, U+2029"""
    starts, i, n = [0], 0, len(text)
    while i < n:
        b = text[i]
        if b == 13:
            if i + 1 < n and text[i + 1] == 10:
                i += 1
            starts.append(i + 1)
        elif b == 10:
            starts.append(i + 1)
        elif b == 0xE2 and text[i + 1:i + 3] in (b"\x80\xa8", b"\x80\xa9"):
            i += 2
            starts.append(i + 1)
        i += 1
    return starts


def is_comment_or_blank_line(text, pos):
    while pos < len(text) and text[pos] in (32, 9):
        pos += 1
    return pos == len(text) or text[pos] in (13, 10) or (pos + 1 < len(text) and text[pos] == 47 and text[pos + 1] == 47)


def with_preceding_directives(text, directives, diags, report_unused=True):
    """program.go getDiagnosticsWithPrecedingDirectives, then the unused @ts-expect-error reports (TS2578)"""
    if not directives:
        return diags
    starts = ecma_line_starts(text)
    by_line = {}
    for start, end, kind, _a in directives:
        by_line[bisect.bisect_right(starts, start) - 1] = [start, end, kind]
    out = []
    for d in diags:
        ignore = False
        line = bisect.bisect_right(starts, d[0]) - 2
        while line >= 0:
            if line in by_line:
                ignore = True
                by_line[line][2] = 0
                break
            if not is_comment_or_blank_line(text, starts[line]):
                break
            line -= 1
        if not ignore:
            out.append(d)
    for start, end, kind in by_line.values():
        if kind == 1 and report_unused:
            out.append((start, end, 2578, None))
    return out


def compose(path, entry, cfg, text=b""):
    """program.go's per-file composition over the raw sections → [(pos, end, code)]"""
    low = path.lower()
    is_js = low.endswith(".js") or low.endswith(".jsx") or low.endswith(".mjs") or low.endswith(".cjs")
    is_dts = bool(re.search(r"\.d\.([^./]+\.)?[mc]?ts$", low))
    diags = list(entry["D"]) + list(entry["J"])
    checkjs = cfg.get("checkjs", "").lower()
    directive = entry["K"]
    # SkipTypeChecking
    skip = cfg.get("nocheck", "").lower() == "true"
    if cfg.get("skiplibcheck", "").lower() == "true" and is_dts:
        skip = True
    if directive == 2:
        skip = True
    plain_js = is_js and directive == 0 and checkjs == ""
    check_js = is_js and (directive == 1 or (directive == 0 and checkjs == "true"))
    if is_js and not plain_js and not check_js:
        skip = True
    if not skip:
        semantic = list(entry["B"]) + list(entry["C"])
        if plain_js:
            semantic = [d for d in semantic if d[2] in PLAIN_JS_ERRORS]
        else:
            if check_js:
                semantic += list(entry["S"])
            semantic = with_preceding_directives(text, entry["R"], semantic)
        diags += semantic
        # GetIncludeProcessorDiagnostics: the loader's diagnostics located in the file
        diags += with_preceding_directives(text, entry["R"], list(entry["P"]), report_unused=False)
    return diags


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--store", default=os.path.join(PKG, "tests", "out", "run.db"))
    ap.add_argument("--binary", default=os.path.join(PKG, "tests", "out", "tscaly_dump"))
    ap.add_argument("--filter", default="")
    ap.add_argument("--only", default="")
    ap.add_argument("--jobs", type=int, default=8)
    ap.add_argument("--timeout", type=int, default=120)
    ap.add_argument("--verdicts", default="")
    ap.add_argument("--show", default="")
    ap.add_argument("--messages", default="")
    ap.add_argument("--chains", default="")
    ap.add_argument("--related", default="")
    ap.add_argument("--scratch", default=os.path.join(PKG, "tests", "out", "caseerrors"))
    args = ap.parse_args()
    args.message_verdicts = [] if args.messages else None
    args.chain_verdicts = [] if args.chains else None
    args.related_verdicts = [] if args.related else None

    db = sqlite3.connect(args.store)
    cases = db.execute("SELECT ci, name, case_file FROM cases WHERE name LIKE 'submodule_%' ORDER BY ci").fetchall()
    only = set(l.strip() for l in open(args.only) if l.strip()) if args.only else None
    skips = collections.Counter()
    case_rows = []
    for ci, name, case_file in cases:
        if args.filter and args.filter not in name:
            continue
        if only is not None and name not in only:
            continue
        base = os.path.basename(case_file)
        stem = os.path.splitext(base)[0]
        if base in casejs.SKIPPED_TESTS:
            skips["skipped by the reference"] += 1
            continue
        try:
            text = casejs.decode_case(open(case_file, "rb").read())
        except OSError:
            skips["case file unreadable"] += 1
            continue
        settings = {m.group(1).lower(): m.group(2).strip().rstrip(";") for m in casejs.OPTION_RE.finditer(text)}
        settings.pop("link", None)
        settings.pop("symlink", None)
        links = casejs.case_links(text)
        units = db.execute("SELECT name, content FROM units WHERE ci=? ORDER BY idx", (ci,)).fetchall()
        units = [(n, casejs.strip_directives(c)) for n, c in units]
        case_rows.append((ci, name, case_file, stem, text, settings, links, units))
    tsconfigs = casejs.read_tsconfigs(args, case_rows)

    plans, groups = [], collections.defaultdict(list)
    for ci, name, case_file, stem, text, settings, links, units in case_rows:
        config = tsconfigs.get(name)
        if config is not None and config[0] == "STOP":
            skips["tsconfig reader stopped"] += 1
            continue
        last = {}
        for i, (n, c) in enumerate(units):
            last[n] = i
        content_of = {}
        if units and config is None:
            tail = units[-1][1].decode("utf-8", "replace") if isinstance(units[-1][1], bytes) else units[-1][1]
            if re.search(r"require\(", tail) or re.search(r"reference\s+path", tail):
                earlier = [c for n, c in units[:-1] if n == units[-1][0]]
                if earlier:
                    content_of[units[-1][0]] = earlier[-1]
        # compiler_runner.go reads the LAST unit's own text for its root rule
        orig_last = units[-1][1] if units else b""
        orig_last_text = orig_last.decode("utf-8", "replace") if isinstance(orig_last, bytes) else orig_last
        units = [(n, content_of.get(n, c)) for i, (n, c) in enumerate(units) if last[n] == i]
        config_index = next((i for i, (n, _) in enumerate(units) if casejs.is_config_unit(n)), None) if config is not None else None
        program_units = [u for i, u in enumerate(units) if i != config_index]
        for cname, cfg in casejs.configurations(settings):
            if config is not None:
                merged = dict(config[0])
                merged["configfilepath"] = casejs.program_path_at("/.src", settings, units[config_index][0])
                merged.update(cfg)
                cfg = merged
            reason = casejs.unsupported(cfg)
            if reason:
                skips["unsupported: " + reason] += 1
                continue
            casejs.ROOT = casejs.posixpath.normpath(casejs.posixpath.join("/.src", cfg.get("currentdirectory", "").strip()))
            category = "conformance" if name.startswith("submodule_conformance_") else "compiler"
            bstem = os.path.join(casejs.TSGO_BASELINES, category, stem + ("(%s)" % cname if cname else ""))
            if not any(os.path.exists(bstem + ext) for ext in (".errors.txt", ".js", ".types", ".symbols")):
                skips["no baseline"] += 1
                continue
            opts = casejs.options_string(cfg)
            vpath = "/errors/%s/%s" % (name, cname or "default")
            parts = []
            texts = {}
            # compiler_runner.go's root files: the config's file names, else every unit
            # unless the last one requires or references the rest (programFileNames
            # drops JSON)
            last_text = orig_last_text
            last_only = bool(re.search(r"require\(", last_text) or re.search(r"reference\s+path", last_text) or cfg.get("noimplicitreferences"))
            config_roots = set(config[1]) if config is not None else None
            for ui, (un, content) in enumerate(program_units):
                body = content if isinstance(content, bytes) else content.encode("utf-8", "surrogateescape")
                ppath = casejs.program_path(un)
                if config_roots is not None:
                    root = ppath in config_roots
                else:
                    root = (not last_only) or ui == len(program_units) - 1
                if ppath.lower().endswith(".json"):
                    root = False
                parts.append(b"==== TSCALY-FILE %d %s %s\n" % (len(body), b"3" if root else b"1", un.encode("utf-8", "surrogateescape")))
                parts.append(body)
                parts.append(b"\n")
                texts[ppath] = body
            if config is not None:
                cun, ccontent = units[config_index]
                cbody = ccontent if isinstance(ccontent, bytes) else ccontent.encode("utf-8", "surrogateescape")
                parts.append(b"==== TSCALY-FILE %d c %s\n" % (len(cbody), cun.encode("utf-8", "surrogateescape")))
                parts.append(cbody)
                parts.append(b"\n")
                texts[casejs.program_path(cun)] = cbody
            for symlink, target in links:
                parts.append(b"==== TSCALY-LINK %s\t%s\n" % (casejs.program_path(symlink).encode("utf-8", "surrogateescape"), casejs.program_path(target).encode("utf-8", "surrogateescape")))
            groups[opts].append((vpath, b"".join(parts)))
            exp_messages = collections.Counter()
            exp_chains = collections.Counter()
            plans.append({"case": name, "config": cname, "cfg": cfg, "vpath": vpath, "texts": texts,
                          "expected": expected_errors(bstem + ".errors.txt", exp_messages, exp_chains),
                          "expected_messages": exp_messages, "expected_chains": exp_chains,
                          "expected_related": expected_related(bstem + ".errors.txt"),
                          "pretty": cfg.get("pretty", "").lower() == "true"})

    binary = casejs.stack_wrapper(args)
    answers = {}
    print("cases planned %d, configurations skipped %d, in %d option groups" % (len(plans), sum(skips.values()), len(groups)), flush=True)
    answers.update(harness.run_batch_groups(binary, [("--errors=" + opts, items, os.path.join(args.scratch, "g%d" % gi))
                                                     for gi, (opts, items) in enumerate(sorted(groups.items()))], args.jobs, args.timeout))

    counts, stops, verdicts = collections.Counter(), collections.Counter(), []
    message_counts, message_codes = collections.Counter(), collections.Counter()
    chain_counts, chain_codes = collections.Counter(), collections.Counter()
    related_counts, related_missing, related_extra = collections.Counter(), collections.Counter(), collections.Counter()
    missing_codes, extra_codes = collections.Counter(), collections.Counter()
    for plan in plans:
        rc, body, err = answers.get(plan["vpath"], (None, b"", b""))
        verdict, detail = "MATCH", ""
        ours = collections.Counter()
        # harnessutil compiles twice — a pre-emit program and a post-emit one whose
        # Emit runs first — and keeps the SHORTER diagnostic list (the post one on a
        # tie); the dump answers the second after a TSCALY-POST marker
        post_body = None
        marker = b"==== TSCALY-FILE TSCALY-POST\n"
        if marker in body:
            body, post_body = body.split(marker, 1)
        if rc is None or rc != 0:
            verdict, detail = "CRASH", "rc %s: %s" % (rc, (err.decode("utf-8", "replace").strip().split("\n") or [""])[-1][:120])
        elif body.startswith(b"UNPORTED "):
            verdict, detail = "UNPORTED", body.decode("utf-8", "replace").split("\n")[0]
        elif post_body is not None and post_body.startswith(b"UNPORTED "):
            verdict, detail = "UNPORTED", "post-emit " + post_body.decode("utf-8", "replace").split("\n")[0]
        else:
            our_messages = collections.Counter()
            our_chains = collections.Counter()
            our_related = collections.Counter()
            ours = answer_counter(plan, body, our_messages, our_chains, our_related)
            if post_body is not None:
                post_messages = collections.Counter()
                post_chains = collections.Counter()
                post_related = collections.Counter()
                post = answer_counter(plan, post_body, post_messages, post_chains, post_related)
                if sum(post.values()) <= sum(ours.values()):
                    ours, our_messages, our_chains, our_related = post, post_messages, post_chains, post_related
            exp = plan["expected"]
            # the port has no message text: a key counts once on each side
            if set(ours) != set(exp):
                verdict = "FAIL"
                miss = sorted(set(exp) - set(ours))
                extra = sorted(set(ours) - set(exp))
                for k in miss:
                    missing_codes[k[3]] += 1
                for k in extra:
                    extra_codes[k[3]] += 1
                detail = "missing %s extra %s" % (miss, extra)
            else:
                # the message verdict of a code MATCH: the head message text per key
                em, om = set(plan["expected_messages"]), set(our_messages)
                if not plan["pretty"]:
                    ec, oc = set(plan["expected_chains"]), set(our_chains)
                    if ec == oc:
                        chain_counts["MATCH"] += 1
                    else:
                        chain_counts["FAIL"] += 1
                        for k, t in sorted(ec - oc):
                            chain_codes[k[3]] += 1
                        if args.chain_verdicts is not None:
                            args.chain_verdicts.append((plan["case"], plan["config"], sorted(ec - oc), sorted(oc - ec)))
                er = plan["expected_related"]
                if er == our_related:
                    related_counts["MATCH"] += 1
                else:
                    related_counts["FAIL"] += 1
                    for k in (er - our_related):
                        related_missing[k[0]] += 1
                    for k in (our_related - er):
                        related_extra[k[0]] += 1
                    if args.related_verdicts is not None:
                        args.related_verdicts.append((plan["case"], plan["config"], sorted(er - our_related), sorted(our_related - er)))
                if em == om:
                    message_counts["MATCH"] += 1
                else:
                    message_counts["FAIL"] += 1
                    for k, t in sorted(em - om):
                        message_codes[k[3]] += 1
                    if args.show and (plan["case"], plan["config"]) == tuple((args.show + ":").split(":")[:2]):
                        print("  messages expected", sorted(em - om))
                        print("  messages ours    ", sorted(om - em))
                    if args.message_verdicts is not None:
                        args.message_verdicts.append((plan["case"], plan["config"], sorted(em - om), sorted(om - em)))
        counts[verdict] += 1
        if verdict == "UNPORTED":
            stops[" ".join(detail.split()[2:3])] += 1
        verdicts.append((plan["case"], plan["config"], verdict, detail))
        if args.show and (plan["case"], plan["config"]) == tuple((args.show + ":").split(":")[:2]):
            print("==== %s %s" % (plan["case"], plan["config"]))
            print(body.decode("utf-8", "replace"))
            print(err.decode("utf-8", "replace"))
            print("  expected", sorted(plan["expected"]))
            print("  ours    ", sorted(ours))
    report(args, plans, counts, skips, stops, missing_codes, extra_codes, verdicts)
    print("  messages of the code MATCHes: MATCH %d FAIL %d" % (message_counts["MATCH"], message_counts["FAIL"]))
    print("  message codes differing (pairs):", message_codes.most_common(40))
    print("  chains of the code MATCHes (not pretty): MATCH %d FAIL %d" % (chain_counts["MATCH"], chain_counts["FAIL"]))
    print("  chain codes differing (pairs):", chain_codes.most_common(40))
    print("  related information of the code MATCHes: MATCH %d FAIL %d" % (related_counts["MATCH"], related_counts["FAIL"]))
    print("  related codes missing:", related_missing.most_common(30))
    print("  related codes extra:  ", related_extra.most_common(30))
    if args.related:
        with open(args.related, "w") as fh:
            for c, cfg, miss, extra in args.related_verdicts:
                fh.write("%s\t%s\n  expected %r\n  ours     %r\n" % (c, cfg, miss, extra))
    if args.chains:
        with open(args.chains, "w") as fh:
            for c, cfg, miss, extra in args.chain_verdicts:
                fh.write("%s\t%s\n  expected %r\n  ours     %r\n" % (c, cfg, miss, extra))
    if args.messages:
        with open(args.messages, "w") as fh:
            for c, cfg, miss, extra in args.message_verdicts:
                fh.write("%s\t%s\n  expected %r\n  ours     %r\n" % (c, cfg, miss, extra))


def answer_counter(plan, body, messages=None, chains=None, related=None):
    """one program's answer → Counter of (file, line, col, code); with `messages` also the
    (key, formatted message) pairs, with `chains` the (key, message and chain) pairs"""
    ours = collections.Counter()
    if messages is None:
        messages = collections.Counter()
    if chains is None:
        chains = collections.Counter()
    if related is None:
        related = collections.Counter()
    # SortAndDeduplicateDiagnostics: diagnostics equal but for their related information
    # are one, carrying the union of it
    merged = collections.OrderedDict()
    def note(key, code, margs):
        messages[(key, format_message(code, margs))] += 1
        chains[(key, full_message(code, margs))] += 1
        group = merged.setdefault((key, full_message(code, margs)), set())
        for rpath, rpos, rcode, rargs in getattr(margs, "related", ()):
            group.add((rcode, related_location(plan, rpath, rpos), format_message(rcode, rargs)))
    for path, entry in parse_answer(body).items():
        if path.startswith("TSCALY-DECL "):
            dpath = path[len("TSCALY-DECL "):]
            dtext = plan["texts"].get(dpath)
            if dtext is not None:
                dshown = casejs.remove_test_path_prefixes(dpath)
                for pos, end, code, margs in entry["X"]:
                    line, col = line_col(dtext, pos)
                    ours[(dshown, line, col, code)] += 1
                    note((dshown, line, col, code), code, margs)
            continue
        if path == "TSCALY-GLOBAL":
            for _, _, code, margs in entry["G"]:
                ours[("", 0, 0, code)] += 1
                note(("", 0, 0, code), code, margs)
            continue
        text = plan["texts"].get(path)
        if text is None:
            continue
        shown = casejs.remove_test_path_prefixes(path)
        if casejs.is_config_unit(path):
            for pos, end, code, margs in entry["P"]:
                line, col = line_col(text, pos)
                ours[(shown, line, col, code)] += 1
                note((shown, line, col, code), code, margs)
            continue
        for pos, end, code, margs in compose(path, entry, plan["cfg"], text):
            line, col = line_col(text, pos)
            ours[(shown, line, col, code)] += 1
            note((shown, line, col, code), code, margs)
    for group in merged.values():
        for r in group:
            related[r] += 1
    return ours


def report(args, plans, counts, skips, stops, missing_codes, extra_codes, verdicts):
    print()
    print("caseerrors yardstick — %d (case, configuration) pairs against the reference error baselines" % len(plans))
    for k in ("MATCH", "UNPORTED", "FAIL", "CRASH"):
        print("  %-9s %d" % (k, counts[k]))
    print("  skipped   %d" % sum(skips.values()))
    for k, v in sorted(skips.items(), key=lambda kv: -kv[1]):
        print("    %-50s %d" % (k, v))
    if stops:
        print("  stops by tag:")
        for k, v in stops.most_common(20):
            print("    %-45s %d" % (k, v))
    print("  codes missing (pairs):", missing_codes.most_common(25))
    print("  codes extra (pairs):  ", extra_codes.most_common(25))
    if args.verdicts:
        with open(args.verdicts, "w") as fh:
            for c, cfg, v, d in verdicts:
                fh.write("%s\t%s\t%s\t%s\n" % (c, cfg, v, d))
        print("wrote %d verdicts to %s" % (len(verdicts), args.verdicts))
    return 0


if __name__ == "__main__":
    sys.exit(main())
