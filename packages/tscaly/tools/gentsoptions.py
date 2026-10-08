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
OUT = os.path.join(ROOT, "packages/tscaly/0.1.1/tscaly/TsOptionDecls.scaly")

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


MESSAGE_CODES = {}


def message_code(text):
    """`diagnostics.NAME` → its code, 0 for anything else"""
    if not text:
        return 0
    if not MESSAGE_CODES:
        gen = open(os.path.join(TSO, "..", "diagnostics", "diagnostics_generated.go"), encoding="utf-8").read()
        for m in re.finditer(r"^var (\w+) = &Message\{code: (\d+),", gen, re.M):
            MESSAGE_CODES[m.group(1)] = int(m.group(2))
    m = re.match(r"diagnostics\.(\w+)$", text.strip())
    if not m:
        return 0
    return MESSAGE_CODES[m.group(1)]


def decl_record(e, name, kind):
    minv = field(e, "minValue")
    return {
        "name": name.strip('"'),
        "kind": KINDS.get(kind, 0) if not kind.startswith('"') else {"\"boolean\"": 3, "\"string\"": 1, "\"number\"": 2}[kind],
        "file_path": field(e, "IsFilePath") == "true",
        "cmd_only": field(e, "IsCommandLineOnly") == "true",
        "preserve_falsy": field(e, "listPreserveFalsyValues") == "true",
        "locale": field(e, "extraValidation") == "extraValidationLocale",
        "tsconfig_only": field(e, "IsTSConfigOnly") == "true",
        "simplified": field(e, "ShowInSimplifiedHelpView") == "true",
        "short": (field(e, "ShortName") or "").strip('"'),
        "description": message_code(field(e, "Description")),
        "category": message_code(field(e, "Category")),
        "default": (field(e, "DefaultValueDescription") or ""),
        "min": int(minv) if minv and minv.isdigit() else 0,
        "category_name": (field(e, "Category") or "").strip(),
        "affects": (1 if field(e, "AffectsBuildInfo") == "true" else 0) | (2 if field(e, "AffectsSemanticDiagnostics") == "true" else 0) | (4 if field(e, "AffectsEmit") == "true" else 0) | (8 if field(e, "AffectsDeclarationPath") == "true" else 0) | (16 if field(e, "strictFlag") == "true" else 0) | (32 if field(e, "allowJsFlag") == "true" else 0),
    }


MESSAGE_TEXTS = {}


def message_text(name):
    """a diagnostics message's text by its Go name (diagnostics_generated.go)"""
    if not MESSAGE_TEXTS:
        gen = open(os.path.join(TSO, "..", "diagnostics", "diagnostics_generated.go"), encoding="utf-8").read()
        for m in re.finditer(r'^var (\w+) = &Message\{code: \d+,.*?text: "((?:[^"\\]|\\.)*)"', gen, re.M):
            MESSAGE_TEXTS[m.group(1)] = bytes(m.group(2), "utf-8").decode("unicode_escape").encode("latin-1").decode("utf-8")
    return MESSAGE_TEXTS[name]


CORE_ALIASES = {}


def resolve_value(expr):
    """a Go constant expression of a default or an enum value, aliases resolved"""
    expr = expr.strip()
    if not CORE_ALIASES:
        src = open(os.path.join(TSO, "..", "core", "compileroptions.go"), encoding="utf-8").read()
        for m in re.finditer(r"^\s*(\w+)\s+\w+\s*=\s*(\w+)\s*$", src, re.M):
            if not m.group(2).isdigit():
                CORE_ALIASES["core." + m.group(1)] = "core." + m.group(2)
    while expr in CORE_ALIASES:
        expr = CORE_ALIASES[expr]
    return expr


def help_record(o, element, enum_raw, deprecated):
    """generateOptionOutput's data: the value type and possible values
    (getValueCandidate), the default text, and showAdditionalInfoOutput"""
    kind = o["kind"]
    names = {1: "string", 2: "number", 3: "boolean"}

    def possible(k, name):
        if k in names:
            return names[k]
        if k == 4:
            return ""
        inverted = []
        for key, value in enum_raw.get(name, []):
            if key in deprecated.get(name, set()):
                continue
            v = resolve_value(value)
            for entry in inverted:
                if entry[0] == v:
                    entry[1].append(key)
                    break
            else:
                inverted.append((v, [key]))
        return ", ".join("/".join(keys) for _, keys in inverted)

    if kind == 4:
        candidate = None
    elif kind in (1, 2, 3):
        candidate = (message_text("X_type_Colon"), names[kind])
    elif kind == 5:
        candidate = (message_text("X_one_or_more_Colon"), possible(element[0], element[2]) if element else "")
    else:
        candidate = (message_text("X_one_of_Colon"), possible(kind, o["name"]))
    d = o["default"].strip()
    if d.startswith("diagnostics."):
        default = message_text(d[len("diagnostics."):])
    elif not d or d in ("nil", "core.TSUnknown"):
        default = "undefined"
    else:
        target_kind, target_name = (element[0], element[2]) if kind in (5, 6) and element else (kind, o["name"])
        if target_kind == 7:
            v = resolve_value(d)
            default = "/".join(k for k, val in enum_raw.get(target_name, []) if resolve_value(val) == v)
        elif d.startswith('"'):
            default = bytes(d[1:-1], "utf-8").decode("unicode_escape")
        else:
            default = d
    show = o["category_name"] != "diagnostics.Command_line_Options"
    if show and candidate is not None and candidate[1] == "string" and (not d or d in ('"false"', '"n/a"')):
        show = False
    return candidate, default, show


def main():
    decls = read("declscompiler.go")
    options = []
    common_count = 0
    for var in ("commonOptionsWithBuild", "optionsForCompiler"):
        for e in entries(slice_body(decls, var)):
            if var == "commonOptionsWithBuild" and field(e, "Name") and field(e, "Kind"):
                common_count += 1
            name = field(e, "Name")
            kind = field(e, "Kind")
            if not name or not kind:
                continue
            options.append(decl_record(e, name, kind))

    clo = read("commandlineoption.go")
    m = re.search(r"var commandLineOptionElements = map\[string\]\*CommandLineOption\{(.*?)\n\}\n", clo, re.S)
    elements = {}
    for em in re.finditer(r'"(\w+)":\s*\{(.*?)\n\t\},', m.group(1), re.S):
        body = em.group(2)
        elements[em.group(1)] = (KINDS[field(body, "Kind")], field(body, "IsFilePath") == "true", field(body, "Name").strip('"'))
    m = re.search(r"var commandLineOptionEnumMap = map\[string\]\*collections\.OrderedMap\[string, any\]\{(.*?)\n\}", clo, re.S)
    enum_vars = dict(re.findall(r'"(\w+)":\s*(\w+),', m.group(1)))

    md = re.search(r"var commandLineOptionDeprecated = map\[string\]\*collections\.Set\[string\]\{(.*?)\n\}", clo, re.S)
    deprecated = {k: set(re.findall(r'"([^"]+)"', v)) for k, v in re.findall(r'"(\w+)":\s*collections\.NewSetFromItems\(([^)]*)\)', md.group(1))}
    enums_src = read("enummaps.go")
    enum_keys = {}
    enum_raw = {}
    for opt, var in enum_vars.items():
        mm = re.search(r"var %s = collections\.NewOrderedMapFromList\(\[\]collections\.MapEntry\[string, any\]\{(.*?)\n\}\)" % var, enums_src, re.S)
        if not mm:
            continue
        pairs = re.findall(r'\{Key: "([^"]+)", Value: ([^}]+)\}', mm.group(1))
        enum_keys[opt] = [(k, v.strip().strip('"') if opt == "lib" else k) for k, v in pairs]
        enum_raw[opt] = [(k, v.strip()) for k, v in pairs]

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

    # the watch options and the build options (declswatch.go, declsbuild.go)
    watch = []
    for e in entries(slice_body(read("declswatch.go"), "OptionsForWatch")):
        watch.append(decl_record(e, field(e, "Name"), field(e, "Kind")))
    build_src = read("declsbuild.go")
    tb = re.search(r"var TscBuildOption = CommandLineOption\{(.*?)\n\}", build_src, re.S).group(1)
    build = [decl_record(tb, field(tb, "Name"), field(tb, "Kind"))]
    for e in entries(slice_body(build_src, "OptionsForBuild")):
        if field(e, "Name") is None:
            continue
        build.append(decl_record(e, field(e, "Name"), field(e, "Kind")))
    int_array("TSOPTION_KIND", [o["kind"] for o in options])
    int_array("TSOPTION_FLAGS", [(1 if o["file_path"] else 0) | (2 if o["cmd_only"] else 0) | (4 if o["preserve_falsy"] else 0) | (8 if o["locale"] else 0) for o in options])
    int_array("TSOPTION_FIELD", [field_kind.get(o["name"], 0) for o in options])
    int_array("TSOPTION_ELEMENT_KIND", [elements.get(o["name"], (0, False))[0] for o in options])
    int_array("TSOPTION_ELEMENT_FILE_PATH", [1 if elements.get(o["name"], (0, False))[1] else 0 for o in options])
    int_array("TSOPTION_AFFECTS", [o["affects"] for o in options])
    _core = open(os.path.join(TSO, "..", "core", "compileroptions.go"), encoding="utf-8").read()
    _struct = _core[_core.index("type CompilerOptions struct {"):]
    _struct = _struct[:_struct.index("\n}\n")]
    _lower = {}
    for i, o in enumerate(options):
        _lower[o["name"]] = i
        _lower[o["name"].lower()] = i
    int_array("TSOPTION_COMPILER_FIELDS", [_lower.get(fm.group(1), _lower.get(fm.group(1).lower(), -1)) for fm in re.finditer(r"^\t([A-Z]\w*)\s+\S", _struct, re.M)])

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
    def emit_meta(prefix, decls, with_names):
        if with_names:
            p("    function %scount() returns int" % prefix)
            p("        %d" % len(decls))
            p("")
            p("    function %sname_of(i: int) returns Slice[char]" % prefix)
            p("    {")
            for i, o in enumerate(decls):
                p("        if i = %d" % i)
                p('            return "%s"' % o["name"])
            p('        ""')
            p("    }")
            p("")
            p("    function %skind_of(i: int) returns int" % prefix)
            p("    {")
            for i, o in enumerate(decls):
                p("        if i = %d" % i)
                p("            return %d" % o["kind"])
            p("        0")
            p("    }")
            p("")
        p("    ; ShortName, empty when the option has none")
        p("    function %sshort_name_of(i: int) returns Slice[char]" % prefix)
        p("    {")
        for i, o in enumerate(decls):
            if o["short"]:
                p("        if i = %d" % i)
                p('            return "%s"' % o["short"])
        p('        ""')
        p("    }")
        p("")
        p("    ; IsTSConfigOnly")
        p("    function %sis_tsconfig_only(i: int) returns bool" % prefix)
        p("    {")
        for i, o in enumerate(decls):
            if o["tsconfig_only"]:
                p("        if i = %d" % i)
                p("            return true")
        p("        false")
        p("    }")
        p("")
        p("    ; ShowInSimplifiedHelpView")
        p("    function %sshow_in_simplified_help_view(i: int) returns bool" % prefix)
        p("    {")
        for i, o in enumerate(decls):
            if o["simplified"]:
                p("        if i = %d" % i)
                p("            return true")
        p("        false")
        p("    }")
        p("")
        p("    ; the Description message's code, 0 for none")
        p("    function %sdescription_of(i: int) returns int" % prefix)
        p("    {")
        for i, o in enumerate(decls):
            if o["description"]:
                p("        if i = %d" % i)
                p("            return %d" % o["description"])
        p("        0")
        p("    }")
        p("")
        p("    ; the Category message's code, 0 for none")
        p("    function %scategory_of(i: int) returns int" % prefix)
        p("    {")
        for i, o in enumerate(decls):
            if o["category"]:
                p("        if i = %d" % i)
                p("            return %d" % o["category"])
        p("        0")
        p("    }")
        p("")
        p("    ; DefaultValueDescription as the reference's Go expression text, empty for none")
        p("    function %sdefault_value_description_of(i: int) returns Slice[char]" % prefix)
        p("    {")
        for i, o in enumerate(decls):
            if o["default"]:
                p("        if i = %d" % i)
                p("            return \"%s\"" % o["default"].replace("\\", "\\\\").replace('"', '\\"').replace("`", "\\`"))
        p('        ""')
        p("    }")
        p("")
        p("    ; the help text's value type (getValueCandidate), empty for an object option")
        p("    function %shelp_value_type(i: int) returns Slice[char]" % prefix)
        p("    {")
        helps = [help_record(o, elements.get(o["name"]), enum_raw, deprecated) for o in decls]
        def lit(t):
            return '"%s"' % t.replace("\\", "\\\\").replace('"', '\\"').replace("`", "\\`")
        for i, h in enumerate(helps):
            if h[0] is not None:
                p("        if i = %d" % i)
                p("            return %s" % lit(h[0][0]))
        p('        ""')
        p("    }")
        p("")
        p("    ; the help text's possible values (getPossibleValues)")
        p("    function %shelp_possible_values(i: int) returns Slice[char]" % prefix)
        p("    {")
        for i, h in enumerate(helps):
            if h[0] is not None and h[0][1]:
                p("        if i = %d" % i)
                p("            return %s" % lit(h[0][1]))
        p('        ""')
        p("    }")
        p("")
        p("    ; the help text's default (a message's text, or formatDefaultValue)")
        p("    function %shelp_default(i: int) returns Slice[char]" % prefix)
        p("    {")
        for i, h in enumerate(helps):
            if h[1]:
                p("        if i = %d" % i)
                p("            return %s" % lit(h[1]))
        p('        ""')
        p("    }")
        p("")
        p("    ; showAdditionalInfoOutput")
        p("    function %shelp_shows_additional_info(i: int) returns bool" % prefix)
        p("    {")
        for i, h in enumerate(helps):
            if h[2]:
                p("        if i = %d" % i)
                p("            return true")
        p("        false")
        p("    }")
        p("")
        p("    ; IsCommandLineOnly")
        p("    function %shelp_command_line_only(i: int) returns bool" % prefix)
        p("    {")
        for i, o in enumerate(decls):
            if o["cmd_only"]:
                p("        if i = %d" % i)
                p("            return true")
        p("        false")
        p("    }")
        p("")
        p("    ; minValue (a number option's floor)")
        p("    function %smin_value_of(i: int) returns int" % prefix)
        p("    {")
        for i, o in enumerate(decls):
            if o["min"]:
                p("        if i = %d" % i)
                p("            return %d" % o["min"])
        p("        0")
        p("    }")
        p("")
    p("    ; a declaration of commonOptionsWithBuild (the build command's own table shares it)")
    p("    function is_common_with_build(i: int) returns bool")
    p("        (i >= 0) and (i < %d)" % common_count)
    p("")
    emit_meta("", options, False)
    emit_meta("watch_", watch, True)
    emit_meta("build_", build, True)
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
    p("    ; tsoptions.LibFilesSet in LibMap's order, then TargetToLibMap's values: the")
    p("    ; default library files a test system writes at startup; empty past the end")
    p("    function default_lib_file_at(i: int) returns Slice[char]")
    p("    {")
    lib_files = []
    for k, v in enum_keys.get("lib", []):
        if v not in lib_files:
            lib_files.append(v)
    mt = re.search(r"var targetToLibMap = map\[core\.ScriptTarget\]string\{(.*?)\n\}", enums_src, re.S)
    for v in re.findall(r'"([^"]+)"', mt.group(1)):
        if v not in lib_files:
            lib_files.append(v)
    for i, v in enumerate(lib_files):
        p("        if i = %d" % i)
        p('            return "%s"' % v)
    p('        ""')
    p("    }")
    p("")
    p("    ; the first key of option `i`'s enum map whose value is the value `text` converts")
    p("    ; to (`text` being a key, or for lib a file name): generateTSConfig's")
    p("    ; formatSingleValue over a parsed value; empty when none")
    p("    function enum_first_key(i: int, text: Slice[char]) returns Slice[char]")
    p("    {")
    for opt, pairs in enum_raw.items():
        if opt not in last:
            continue
        p("        if i = %d" % last[opt])
        p("        {")
        for k, v in pairs:
            rv = resolve_value(v)
            first = next(k2 for k2, v2 in pairs if resolve_value(v2) == rv)
            probe = v.strip('"') if opt == "lib" else k
            p('            if text.equals("%s")' % probe)
            p('                return "%s"' % first)
        p("        }")
    p('        ""')
    p("    }")
    p("")
    # core.CompilerOptions' exported fields in declaration order, each the option
    # CommandLineCompilerOptionsMap.Get(field name) finds (-1 for none)
    core_src = open(os.path.join(TSO, "..", "core", "compileroptions.go"), encoding="utf-8").read()
    struct = core_src[core_src.index("type CompilerOptions struct {"):]
    struct = struct[:struct.index("\n}\n")]
    lower_last = {}
    for i, o in enumerate(options):
        lower_last[o["name"]] = i
        lower_last[o["name"].lower()] = i
    fields = []
    for fm in re.finditer(r"^\t([A-Z]\w*)\s+\S", struct, re.M):
        name = fm.group(1)
        fields.append(lower_last.get(name, lower_last.get(name.lower(), -1)))
    core_values = {}
    for cm in re.finditer(r"^\s*(\w+)\s+\w+\s*=\s*(\d+)\s*(?://.*)?$", core_src, re.M):
        core_values["core." + cm.group(1)] = int(cm.group(2))
    p("    ; core.CompilerOptions' exported fields in declaration order: the option each")
    p("    ; one is (ForEachCompilerOptionValue's CommandLineCompilerOptionsMap.Get),")
    p("    ; -1 for a field no declaration names")
    p("    function compiler_field_count() returns int")
    p("        %d" % len(fields))
    p("")
    p("    function compiler_field_option(f: int) returns int")
    p("        TSOPTION_COMPILER_FIELDS[f]")
    p("")
    p("    ; AffectsBuildInfo 1, AffectsSemanticDiagnostics 2, AffectsEmit 4,")
    p("    ; AffectsDeclarationPath 8, strictFlag 16, allowJsFlag 32")
    p("    function affects_of(i: int) returns int")
    p("        TSOPTION_AFFECTS[i]")
    p("")
    p("    ; the numeric value of option `i`'s enum key (a Go ScriptTarget, ModuleKind, ...),")
    p("    ; -1 when the key is not in the map or the map's values are not numbers")
    p("    function enum_number(i: int, key: Slice[char]) returns int")
    p("    {")
    for opt, pairs in enum_raw.items():
        if opt not in last or opt == "lib":
            continue
        p("        if i = %d" % last[opt])
        p("        {")
        for k, v in pairs:
            rv = resolve_value(v)
            if rv in core_values:
                p('            if key.equals("%s")' % k)
                p("                return %d" % core_values[rv])
        p("        }")
    p("        0 - 1")
    p("    }")
    p("")
    p("    ; the first key of option `i`'s enum map whose value is the number `n`, empty")
    p("    ; when none")
    p("    function enum_key_of_number(i: int, n: int) returns Slice[char]")
    p("    {")
    for opt, pairs in enum_raw.items():
        if opt not in last or opt == "lib":
            continue
        p("        if i = %d" % last[opt])
        p("        {")
        seen = set()
        for k, v in pairs:
            rv = resolve_value(v)
            if rv in core_values and core_values[rv] not in seen:
                seen.add(core_values[rv])
                p("            if n = %d" % core_values[rv])
                p('                return "%s"' % k)
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
