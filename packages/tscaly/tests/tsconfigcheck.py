#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""
tsconfigcheck.py — the TSCONFIG cross-check (slice 261): `tscaly_dump --tsconfig=`
against tests/oracle/tsconfig.go (the reference's own ParseJsonSourceFileConfigFileContent
as test_case_parser.go calls it) over every store case carrying a tsconfig.json/jsconfig.json
plus the fixtures below (globs, extension priority, JSON includes, extends chains, a
package's `tsconfig` field and index, circularity, jsconfig defaults, ${configDir},
invalid values, a root array, trailing recursion, includes outside the config directory,
a relative current directory). The options compare as a set (the port keeps assignment
order, the reference struct order), the file names in order.

Usage: tests/tsconfigcheck.py [--binary tests/out/tscaly_dump] [--store tests/out/run.db]
Builds the oracle into the scratch directory (copied into the submodule and removed again).
"""
import argparse, os, re, shutil, sqlite3, subprocess, sys, tempfile
HERE = os.path.dirname(os.path.abspath(__file__))
PKG = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import casejs  # noqa: E402
SUB = os.path.join(PKG, "_submodules", "typescript-go")

CASES = {
 "globs": [("/p/tsconfig.json", '{"include": ["src/**/*", "lib/*.ts", "x?.ts", ".hidden/*"], "exclude": ["src/skip"]}'),
           ("/p/src/a.ts", "a"), ("/p/src/skip/b.ts", "b"), ("/p/src/deep/c.tsx", "c"), ("/p/src/node_modules/m.ts", "m"),
           ("/p/lib/l.ts", "l"), ("/p/lib/l.d.ts", "l"), ("/p/x1.ts", "x"), ("/p/xy.ts", "x"), ("/p/.hidden/h.ts", "h"), ("/p/src/.dot.ts", "d")],
 "priority": [("/tsconfig.json", '{"compilerOptions": {"allowJs": true}}'), ("/a.ts", "a"), ("/a.js", "a"), ("/a.d.ts", "a"),
              ("/b.js", "b"), ("/b.d.ts", "b"), ("/c.tsx", "c"), ("/c.d.ts", "c"), ("/m.min.js", "m"), ("/d.jsx", "d"), ("/e.mts", "e"), ("/e.mjs", "e")],
 "json": [("/tsconfig.json", '{"compilerOptions": {"resolveJsonModule": true}, "include": ["*.ts", "data/*.json", "src"]}'),
          ("/a.ts", "a"), ("/data/x.json", "{}"), ("/src/y.json", "{}"), ("/src/z.ts", "z")],
 "extends_chain": [("/base/tsconfig.base.json", '{"compilerOptions": {"strict": true, "outDir": "out", "target": "ES6", "lib": ["ES2015", "DOM"]}, "include": ["src", "${configDir}/gen"], "exclude": ["src/x"]}'),
                   ("/proj/tsconfig.json", '{"extends": "../base/tsconfig.base", "compilerOptions": {"strict": null, "module": "NodeNext"}}'),
                   ("/base/src/a.ts", "a"), ("/proj/src/b.ts", "b"), ("/proj/gen/g.ts", "g"), ("/base/src/x/c.ts", "c")],
 "extends_pkg": [("/node_modules/cfg/package.json", '{"name": "cfg", "tsconfig": "./base.json"}'), ("/node_modules/cfg/base.json", '{"compilerOptions": {"declaration": true}}'),
                 ("/tsconfig.json", '{"extends": "cfg", "files": ["a.ts", "missing.ts"]}'), ("/a.ts", "a")],
 "extends_pkg_index": [("/node_modules/cfg2/tsconfig.json", '{"compilerOptions": {"noImplicitAny": true}}'),
                       ("/tsconfig.json", '{"extends": "cfg2"}'), ("/a.ts", "a")],
 "circular": [("/tsconfig.json", '{"extends": "./b.json", "compilerOptions": {"declaration": true}}'), ("/b.json", '{"extends": "./tsconfig.json", "compilerOptions": {"sourceMap": true}}'), ("/a.ts", "a")],
 "jsconfig": [("/jsconfig.json", '{"compilerOptions": {"noEmit": false}}'), ("/a.js", "a"), ("/b.ts", "b")],
 "configdir": [("/w/tsconfig.json", '{"compilerOptions": {"outDir": "${configDir}/dist", "rootDirs": ["${configDir}/a", "b"], "paths": {"x": ["${configDir}/x"]}, "typeRoots": ["./t"]}, "files": ["${configDir}/main.ts"]}'), ("/w/main.ts", "m")],
 "invalid": [("/tsconfig.json", '{"compilerOptions": {"target": "es9000", "module": 5, "strict": "yes", "outDir": "", "types": ["", "a", false], "help": true, "Strict": true, "noEmit": true, "noEmit": false}, "files": []}'), ("/a.ts", "a")],
 "array_root": [("/tsconfig.json", '[1, {"compilerOptions": {"checkJs": true}}]'), ("/a.js", "a")],
 "trailing_recursion": [("/tsconfig.json", '{"include": ["src/**", "**/../x", "lib"]}'), ("/src/a.ts", "a"), ("/lib/b.ts", "b")],
 "outside": [("/p/tsconfig.json", '{"include": ["../shared/**/*", "*.ts"]}'), ("/p/a.ts", "a"), ("/shared/s.ts", "s"), ("/shared/n/t.ts", "t")],
 "extends_array_files": [("/b1.json", '{"files": ["x.ts"], "compilerOptions": {"allowJs": true}}'), ("/sub/b2.json", '{"include": ["*.js"]}'),
                         ("/tsconfig.json", '{"extends": ["./b1", "./sub/b2.json"]}'), ("/x.ts", "x"), ("/sub/y.js", "y"), ("/z.js", "z")],
 "relative_cwd": [("tsconfig.json", '{"compilerOptions": {"outDir": "../o"}}'), ("a.ts", "a"), ("sub/b.ts", "b")],
 "case_json": [("/TsConfig.JSON", '{"compilerOptions": {"moduleResolution": "Node", "newLine": "LF", "jsx": "react-jsx"}}'), ("/a.tsx", "a")],
 "parse_error_extends": [("/base.json", '{"compilerOptions": {"strict": true,}'), ("/tsconfig.json", '{"extends": "./base.json", "compilerOptions": {"declaration": true,},}'), ("/a.ts", "a")],
 "exclude_default_outdir": [("/tsconfig.json", '{"compilerOptions": {"outDir": "dist", "declarationDir": "types"}}'), ("/a.ts", "a"), ("/dist/a.d.ts", "a"), ("/types/t.d.ts", "t")],
 "customconds": [("/tsconfig.json", '{"compilerOptions": {"customConditions": ["a", "b"], "maxNodeModuleJsDepth": 3, "lib": ["es2020.bigint", "esnext.asynciterable"]}}'), ("/a.ts", "a")],
}


def bundle_bytes(units):
    parts = []
    for un, content in units:
        body = content if isinstance(content, bytes) else content.encode("utf-8", "surrogateescape")
        parts.append(b"==== TSCALY-FILE %d 0 %s\n" % (len(body), un.encode("utf-8", "surrogateescape")))
        parts.append(body)
        parts.append(b"\n")
    return b"".join(parts)


def split(txt):
    out, cur = {}, None
    for l in txt.splitlines():
        if l.startswith("== "):
            cur = l[3:]
            out[cur] = []
        elif cur is not None:
            out[cur].append(l)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--binary", default=os.path.join(PKG, "tests", "out", "tscaly_dump"))
    ap.add_argument("--store", default=os.path.join(PKG, "tests", "out", "run.db"))
    args = ap.parse_args()
    scratch = tempfile.mkdtemp(prefix="tsconfigcheck.")
    oracle = os.path.join(scratch, "oracle_tsconfig")
    dest = os.path.join(SUB, "oracle", "tsconfig")
    os.makedirs(dest, exist_ok=True)
    shutil.copy(os.path.join(HERE, "oracle", "tsconfig.go"), os.path.join(dest, "main.go"))
    try:
        b = subprocess.run(["go", "build", "-o", oracle, "./oracle/tsconfig"], cwd=SUB, capture_output=True, text=True)
    finally:
        shutil.rmtree(os.path.join(SUB, "oracle"))
    if b.returncode != 0:
        sys.exit("the oracle failed to build:\n" + b.stderr)
    lines = []
    db = sqlite3.connect(args.store)
    for ci, name, case_file in db.execute("SELECT ci, name, case_file FROM cases WHERE name LIKE 'submodule_%' ORDER BY ci"):
        units = db.execute("SELECT name, content FROM units WHERE ci=? ORDER BY idx", (ci,)).fetchall()
        if not any(casejs.is_config_unit(n) for n, _ in units):
            continue
        text = casejs.decode_case(open(case_file, "rb").read())
        settings = {m.group(1).lower(): m.group(2).strip().rstrip(";") for m in casejs.OPTION_RE.finditer(text)}
        bf = os.path.join(scratch, name + ".bundle")
        open(bf, "wb").write(bundle_bytes(units))
        lines.append((name, settings.get("currentdirectory", ""), bf))
    for name, units in CASES.items():
        bf = os.path.join(scratch, "fixture_" + name + ".bundle")
        open(bf, "wb").write(bundle_bytes(units))
        lines.append(("fixture_" + name, "/work/here" if name == "relative_cwd" else "", bf))
    lst = os.path.join(scratch, "list")
    with open(lst, "w") as fh:
        for n, c, bfile in lines:
            fh.write("%s\t%s\t%s\n" % (n, c, bfile))
    refs = split(subprocess.run([oracle, lst], capture_output=True, text=True).stdout)
    alias = {("target", "es2015"): "es6", ("module", "es2015"): "es6", ("moduleResolution", "node10"): "node"}
    bad = 0
    for n, c, bfile in lines:
        opts = ("currentdirectory=" + c) if c else ""
        p = subprocess.run(["sh", "-c", "ulimit -s 65520; exec \"$0\" \"$1\" \"$2\"", args.binary, "--tsconfig=" + opts, bfile], capture_output=True, text=True)
        ours = []
        for l in p.stdout.splitlines():
            if l.startswith("TSCONFIG-OPTION "):
                k, _, v = l[len("TSCONFIG-OPTION "):].partition("\t")
                l = "TSCONFIG-OPTION %s\t%s" % (k, alias.get((k, v), v))
            ours.append(l)
        theirs = refs.get(n, ["(no reference answer)"])
        opt = lambda xs: sorted(x for x in xs if x.startswith("TSCONFIG-OPTION"))
        rest = lambda xs: [x for x in xs if not x.startswith("TSCONFIG-OPTION")]
        if p.returncode != 0 or opt(ours) != opt(theirs) or rest(ours) != rest(theirs):
            bad += 1
            print("DIFF %s rc=%d" % (n, p.returncode))
            for x in sorted(set(ours) - set(theirs)):
                print("   ours  ", x)
            for x in sorted(set(theirs) - set(ours)):
                print("   ref   ", x)
    shutil.rmtree(scratch)
    print("tsconfigcheck: %d of %d configurations differ" % (bad, len(lines)))
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
