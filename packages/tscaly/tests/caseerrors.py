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

# compiler/program.go plainJSErrors
PLAIN_JS_ERRORS = {1013, 1014, 1048, 1049, 1053, 1054, 1091, 1100, 1101, 1102, 1104, 1105, 1106, 1107, 1113, 1114,
                   1115, 1116, 1162, 1171, 1174, 1182, 1184, 1186, 1188, 1189, 1190, 1191, 1193, 1197, 1200, 1210,
                   1211, 1214, 1215, 1248, 1255, 1258, 1262, 1312, 1325, 1344, 1358, 1359, 1450, 1451, 1473, 1474,
                   2451, 2462, 2492, 2501, 2528, 2566, 2633, 2752, 2753, 2803, 17000, 17001, 18006, 18007, 18012,
                   18013, 18016, 18036, 18038, 18041}


def expected_errors(path):
    """→ Counter of (file, line, col, code); file "" for a global diagnostic"""
    out = collections.Counter()
    if not os.path.exists(path):
        return out
    with open(path, "rb") as fh:
        text = fh.read().decode("utf-8", "replace").replace("\r\n", "\n")
    for line in text.split("\n"):
        if line.startswith("==== "):
            break
        # `@pretty: true`: `file:line:col - error TSn:` in ANSI colours (slice 269)
        plain = ANSI_RE.sub("", line)
        m = PRETTY_RE.match(plain)
        if m:
            out[(m.group(1), int(m.group(2)), int(m.group(3)), int(m.group(5)))] += 1
            continue
        m = PRETTY_GLOBAL_RE.match(plain) if plain != line else None
        if m:
            out[("", 0, 0, int(m.group(2)))] += 1
            continue
        m = HEADER_RE.match(line)
        if m:
            out[(m.group(1), int(m.group(2)), int(m.group(3)), int(m.group(5)))] += 1
            continue
        m = GLOBAL_RE.match(line)
        if m:
            out[("", 0, 0, int(m.group(2)))] += 1
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
    for line in body.decode("utf-8", "replace").split("\n"):
        if line.startswith("==== TSCALY-FILE "):
            cur = {"K": 0, "D": [], "J": [], "B": [], "C": [], "R": [], "S": [], "P": [], "G": []}
            files[line[len("==== TSCALY-FILE "):]] = cur
            continue
        if cur is None or len(line) < 2:
            continue
        tag, rest = line[0], line[2:].split()
        if tag == "K":
            cur["K"] = int(rest[0])
        elif tag in "DJBCRSPG" and len(rest) == 3:
            cur[tag].append(tuple(int(x) for x in rest))
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
    for start, end, kind in directives:
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
            out.append((start, end, 2578))
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
    ap.add_argument("--scratch", default=os.path.join(PKG, "tests", "out", "caseerrors"))
    args = ap.parse_args()

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
            plans.append({"case": name, "config": cname, "cfg": cfg, "vpath": vpath, "texts": texts,
                          "expected": expected_errors(bstem + ".errors.txt")})

    binary = casejs.stack_wrapper(args)
    answers = {}
    print("cases planned %d, configurations skipped %d, in %d option groups" % (len(plans), sum(skips.values()), len(groups)), flush=True)
    answers.update(harness.run_batch_groups(binary, [("--errors=" + opts, items, os.path.join(args.scratch, "g%d" % gi))
                                                     for gi, (opts, items) in enumerate(sorted(groups.items()))], args.jobs, args.timeout))

    counts, stops, verdicts = collections.Counter(), collections.Counter(), []
    missing_codes, extra_codes = collections.Counter(), collections.Counter()
    for plan in plans:
        rc, body, err = answers.get(plan["vpath"], (None, b"", b""))
        verdict, detail = "MATCH", ""
        ours = collections.Counter()
        if rc is None or rc != 0:
            verdict, detail = "CRASH", "rc %s: %s" % (rc, (err.decode("utf-8", "replace").strip().split("\n") or [""])[-1][:120])
        elif body.startswith(b"UNPORTED "):
            verdict, detail = "UNPORTED", body.decode("utf-8", "replace").split("\n")[0]
        else:
            for path, entry in parse_answer(body).items():
                if path == "TSCALY-GLOBAL":
                    for _, _, code in entry["G"]:
                        ours[("", 0, 0, code)] += 1
                    continue
                text = plan["texts"].get(path)
                if text is None:
                    continue
                shown = casejs.remove_test_path_prefixes(path)
                if casejs.is_config_unit(path):
                    for pos, end, code in entry["P"]:
                        line, col = line_col(text, pos)
                        ours[(shown, line, col, code)] += 1
                    continue
                for pos, end, code in compose(path, entry, plan["cfg"], text):
                    line, col = line_col(text, pos)
                    ours[(shown, line, col, code)] += 1
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
        counts[verdict] += 1
        if verdict == "UNPORTED":
            stops[" ".join(detail.split()[2:3])] += 1
        verdicts.append((plan["case"], plan["config"], verdict, detail))
        if args.show and (plan["case"], plan["config"]) == tuple((args.show + ":").split(":")[:2]):
            print("==== %s %s" % (plan["case"], plan["config"]))
            print("  expected", sorted(plan["expected"]))
            print("  ours    ", sorted(ours))

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
