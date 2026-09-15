#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
#
# gentsoptions.py — generate tscaly/TsOptionDecls.scaly from the reference's
# compiler option declarations (slice 261):
#
#   internal/tsoptions/declscompiler.go      OptionsDeclarations (name, kind, isFilePath,
#                                            isCommandLineOnly, listPreserveFalsyValues,
#                                            extraValidation)
#   internal/tsoptions/commandlineoption.go  commandLineOptionElements, commandLineOptionEnumMap
#   internal/tsoptions/enummaps.go           the enum maps' keys (and LibMap's file names)
#   internal/tsoptions/parsinghelpers.go     parseCompilerOptions' switch: which option
#                                            names set a CompilerOptions field, and how
#
# ★★★ WHY IT IS GENERATED: §3.23's argument. The declarations are 1 264 reference
# lines of data whose only readers are the tsconfig conversion; a slip (a string
# option read as a path, an enum key missing) is not a compile error but an option
# silently absent from one case's configuration.
#
# The output: `TsOptionDecls.index_of(name)` (the option whose NAME is exactly
# `name`, the last declaration of a name winning as commandLineOptionsToMap's map
# does; -1 when none), then per index the declaration's fields as const int arrays,
# and `enum_value(i, lower)` — the value text a known enum key converts to (the
# key itself, or LibMap's file name), empty when the key is not in the map.
#
# Usage (from the repo root, submodule initialized):
#   packages/tscaly/tools/gentsoptions.py
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
TSO = os.path.join(ROOT, "packages/tscaly/_submodules/typescript-go/internal/tsoptions")
OUT = os.path.join(ROOT, "packages/tscaly/0.1.0/tscaly/TsOptionDecls.scaly")

KINDS = {"CommandLineOptionTypeString": 1, "CommandLineOptionTypeNumber": 2, "CommandLineOptionTypeBoolean": 3,
         "CommandLineOptionTypeObject": 4, "CommandLineOptionTypeList": 5, "CommandLineOptionTypeListOrElement": 6,
         "CommandLineOptionTypeEnum": 7}
FIELD_KINDS = {"ParseTristate": 1, "ParseString": 2, "ParseStringArray": 3, "parseStringMap": 4, "parseNumber": 5, "floatOrInt32ToFlag": 6}


def read(name):
    with open(os.path.join(TSO, name), encoding="utf-8") as fh:
        return fh.read()


def entries(text):
    """the top-level `{ ... }` literals of a Go slice body"""
    out, depth, start = [], 0, None
    for i, ch in enumerate(text):
        if ch == "{":
            if depth == 0:
                start = i
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0 and start is not None:
                out.append(text[start + 1:i])
                start = None
    return out


def field(entry, name):
    m = re.search(r"^\s*%s:\s*([^,\n]+)," % name, entry, re.M)
    return m.group(1).strip() if m else None


def slice_body(text, var):
    m = re.search(r"var %s = \[\]\*CommandLineOption\{" % var, text)
    if not m:
        sys.exit("no %s" % var)
    depth, i = 1, m.end()
    while depth:
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
        i += 1
    return text[m.end():i - 1]


def main():
    decls = read("declscompiler.go")
    options = []
    for var in ("commonOptionsWithBuild", "optionsForCompiler"):
        for e in entries(slice_body(decls, var)):
            name = field(e, "Name")
            kind = field(e, "Kind")
            if not name or not kind:
                continue
            options.append({
                "name": name.strip('"'),
                "kind": KINDS[kind],
                "file_path": field(e, "IsFilePath") == "true",
                "cmd_only": field(e, "IsCommandLineOnly") == "true",
                "preserve_falsy": field(e, "listPreserveFalsyValues") == "true",
                "locale": field(e, "extraValidation") == "extraValidationLocale",
            })

    clo = read("commandlineoption.go")
    m = re.search(r"var commandLineOptionElements = map\[string\]\*CommandLineOption\{(.*?)\n\}\n", clo, re.S)
    elements = {}
    for em in re.finditer(r'"(\w+)":\s*\{(.*?)\n\t\},', m.group(1), re.S):
        body = em.group(2)
        elements[em.group(1)] = (KINDS[field(body, "Kind")], field(body, "IsFilePath") == "true")
    m = re.search(r"var commandLineOptionEnumMap = map\[string\]\*collections\.OrderedMap\[string, any\]\{(.*?)\n\}", clo, re.S)
    enum_vars = dict(re.findall(r'"(\w+)":\s*(\w+),', m.group(1)))

    md = re.search(r"var commandLineOptionDeprecated = map\[string\]\*collections\.Set\[string\]\{(.*?)\n\}", clo, re.S)
    deprecated = {k: set(re.findall(r'"([^"]+)"', v)) for k, v in re.findall(r'"(\w+)":\s*collections\.NewSetFromItems\(([^)]*)\)', md.group(1))}
    enums_src = read("enummaps.go")
    enum_keys = {}
    for opt, var in enum_vars.items():
        mm = re.search(r"var %s = collections\.NewOrderedMapFromList\(\[\]collections\.MapEntry\[string, any\]\{(.*?)\n\}\)" % var, enums_src, re.S)
        if not mm:
            continue
        pairs = re.findall(r'\{Key: "([^"]+)", Value: ([^}]+)\}', mm.group(1))
        enum_keys[opt] = [(k, v.strip().strip('"') if opt == "lib" else k) for k, v in pairs]

    helpers = read("parsinghelpers.go")
    sw = helpers[helpers.index("func parseCompilerOptions("):]
    sw = sw[:sw.index("\nfunc ", 10)]
    field_kind = {}
    for cm in re.finditer(r'case "(\w+)":\n(.*?)(?=\n\tcase |\n\tdefault:)', sw, re.S):
        body = cm.group(2)
        fk = 0
        for fn, k in FIELD_KINDS.items():
            if fn + "(" in body or fn + "[" in body:
                fk = k
                break
        if cm.group(1) == "lib":
            fk = 3
        field_kind[cm.group(1)] = fk

    last = {}
    for i, o in enumerate(options):
        last[o["name"]] = i

    w = []
    p = w.append
    p("; SPDX-License-Identifier: Apache-2.0")
    p(";")
    p("; TsOptionDecls — the compiler option declarations the tsconfig conversion reads,")
    p("; ported from internal/tsoptions (declscompiler.go, commandlineoption.go, enummaps.go")
    p("; and parseCompilerOptions' switch in parsinghelpers.go).")
    p(";")
    p("; GENERATED by packages/tscaly/tools/gentsoptions.py. Do not edit; edit the")
    p("; generator. Regenerate after a submodule pin bump.")
    p(";")
    p("; %d declarations." % len(options))
    p("")
    for k, v in sorted(KINDS.items(), key=lambda kv: kv[1]):
        p("define TsOptionKind%s: int %d" % (k[len("CommandLineOptionType"):], v))
    for v, k in enumerate(["Tristate", "String", "StringArray", "StringMap", "Number", "Flag"]):
        p("define TsOptionField%s: int %d" % (k, v + 1))
    p("define TsOptionFieldNone: int 0")
    p("")

    def int_array(name, values):
        p("define %s: int[] [" % name)
        for i in range(0, len(values), 24):
            p("    " + ", ".join(str(v) for v in values[i:i + 24]) + ",")
        p("]")
        p("")

    int_array("TSOPTION_KIND", [o["kind"] for o in options])
    int_array("TSOPTION_FLAGS", [(1 if o["file_path"] else 0) | (2 if o["cmd_only"] else 0) | (4 if o["preserve_falsy"] else 0) | (8 if o["locale"] else 0) for o in options])
    int_array("TSOPTION_FIELD", [field_kind.get(o["name"], 0) for o in options])
    int_array("TSOPTION_ELEMENT_KIND", [elements.get(o["name"], (0, False))[0] for o in options])
    int_array("TSOPTION_ELEMENT_FILE_PATH", [1 if elements.get(o["name"], (0, False))[1] else 0 for o in options])

    p("define TsOptionDecls")
    p("{")
    p("    ; the declaration named exactly `name` (commandLineOptionsToMap keeps the last")
    p("    ; declaration of a name), -1 when none")
    p("    function index_of(name: Slice[char]) returns int")
    p("    {")
    by_len = {}
    for n, i in last.items():
        by_len.setdefault(len(n), []).append((n, i))
    for ln in sorted(by_len):
        p("        if (name.length as int) = %d" % ln)
        p("        {")
        for n, i in sorted(by_len[ln]):
            p('            if name.equals("%s")' % n)
            p("                return %d" % i)
        p("        }")
    p("        0 - 1")
    p("    }")
    p("")
    p("    function name_of(i: int) returns Slice[char]")
    p("    {")
    for i, o in enumerate(options):
        p("        if i = %d" % i)
        p('            return "%s"' % o["name"])
    p('        ""')
    p("    }")
    p("")
    p("    function kind_of(i: int) returns int")
    p("        TSOPTION_KIND[i]")
    p("")
    p("    function is_file_path(i: int) returns bool")
    p("        (TSOPTION_FLAGS[i] & 1) <> 0")
    p("")
    p("    function is_command_line_only(i: int) returns bool")
    p("        (TSOPTION_FLAGS[i] & 2) <> 0")
    p("")
    p("    function list_preserve_falsy_values(i: int) returns bool")
    p("        (TSOPTION_FLAGS[i] & 4) <> 0")
    p("")
    p("    ; extraValidationLocale")
    p("    function validates_locale(i: int) returns bool")
    p("        (TSOPTION_FLAGS[i] & 8) <> 0")
    p("")
    p("    ; how parseCompilerOptions sets the field (TsOptionFieldNone: no field)")
    p("    function field_kind_of(i: int) returns int")
    p("        TSOPTION_FIELD[i]")
    p("")
    p("    ; CommandLineOption.Elements(): the element kind, 0 when the option has none")
    p("    function element_kind_of(i: int) returns int")
    p("        TSOPTION_ELEMENT_KIND[i]")
    p("")
    p("    function element_is_file_path(i: int) returns bool")
    p("        TSOPTION_ELEMENT_FILE_PATH[i] <> 0")
    p("")
    p("    ; the enum map of option `i` at the lower-cased key: the value text, empty")
    p("    ; when the key is not in the map (or the option has no map)")
    p("    function enum_value(i: int, key: Slice[char]) returns Slice[char]")
    p("    {")
    for opt, pairs in enum_keys.items():
        if opt not in last:
            continue
        p("        if i = %d" % last[opt])
        p("        {")
        for k, v in pairs:
            p('            if key.equals("%s")' % k)
            p('                return "%s"' % v)
        p("        }")
    p('        ""')
    p("    }")
    p("")
    p("    ; formatEnumTypeKeys over the enum map of option `i`: its keys but the")
    p("    ; deprecated ones, quoted and comma-joined")
    p("    function enum_keys_text(i: int) returns Slice[char]")
    p("    {")
    for opt, pairs in enum_keys.items():
        if opt not in last:
            continue
        keys = [k for k, v in pairs if k not in deprecated.get(opt, set())]
        p("        if i = %d" % last[opt])
        p('            return "%s"' % ", ".join("'%s'" % k for k in keys))
    p('        ""')
    p("    }")
    p("}")
    text = "\n".join(w) + "\n"
    with open(OUT, "w", encoding="utf-8") as fh:
        fh.write(text)
    print("%s: %d declarations, %d enum maps, %d field setters" % (OUT, len(options), len(enum_keys), sum(1 for o in options if field_kind.get(o["name"]))))


if __name__ == "__main__":
    main()
