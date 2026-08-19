#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice28.sh — the slice-28 control battery, thirteen of them.
#
# Slice 28 is the MODULE SYMBOL: `"` + the file's normalized absolute path minus
# its extension + `"`, plus the two symbols an exported declaration owns. Almost
# every claim in it is about a STRING that no other yardstick can see, which is
# why the rows below are worth more here than usual — a wrong file name is a wrong
# symbol name on every module unit in the corpus and on nothing else.
#
# ★★★ THE ROW TO READ FIRST IS c3. It replaces the normalized absolute path with
# the raw argument, which is what this port handed the parse for twenty-seven
# slices. If it were UNGATED, the whole tspath group added by this slice would be
# decoration — and the paragraph in tspath.scaly claiming the two sides are handed
# the same string would be unfalsifiable.
#
# ★★ c5 is the defect this slice FOUND rather than one it invented: four of the
# reference's InternalSymbolName constants carry no 0xFE prefix (`export=`,
# `default`, `this`, `module.exports`), slice 27 routed all of them through the
# prefixing helper, and nothing produced one until the JSON arm and the unnamed
# default export did. The row re-breaks it.
#
# ★ THREE rows come back UNGATED and each says WHICH of §3.5v's four reasons it is.
# c12 (is_ambient_module) and c13 (the ALIAS arm) are unreachable-by-construction
# while the module and the import/export bind arms are unported. c7 is the
# interesting one: it was predicted RED and is UNGATED-because-indistinguishable —
# the note at that row has the argument, and a battery that omitted these three
# would leave all of it unstated.
#
# Five fixtures came with the slice so these rows have something to be red about
# on stage 1: an exported plus a local variable, a named and an unnamed default
# export, an ambient module file whose declarations are exported by the EXPORT
# CONTEXT rather than by a modifier, and `await` as an identifier at the top level
# of a module — which is what finally exercises is_in_top_level_context, whose
# unreachability claim expired with this slice.
#
# Usage (it patches the source tree and restores it after every control, so
# nothing may edit the tree while it runs — §3.5y):
#
#   packages/tscaly/tests/controls-slice28.sh 2>&1 | tee /tmp/battery28.log
#
# 1 baseline + 13 controls + 1 verifying run = 15 runs.

set -u
cd "$(dirname "$0")/../../.."

CTL=packages/tscaly/tests/ctl.sh
RUN=packages/tscaly/tests/run.sh
B=packages/tscaly/0.1.0/tscaly/binder.scaly
T=packages/tscaly/0.1.0/tscaly/tspath.scaly
P=packages/tscaly/0.1.0/tscaly/parser.scaly
S=packages/tscaly/0.1.0/tscaly_symbols.scaly

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

export TSCALY_BASELINE=$(mktemp -t tscaly-baseline)
cleanup() { rm -f "$TSCALY_BASELINE" "$TSCALY_BASELINE.fp"; }
trap cleanup EXIT

echo "################################################################"
if ! "$CTL" --establish-baseline </dev/null; then
  exit 2
fi

run() { echo; echo "################################################################"; "$CTL" "$1"; }

# ── the NAME ─────────────────────────────────────────────────────────────────

run "c1 the module symbol's name is QUOTED" <<SPEC
FILE $B
<<<OLD
        set *buf: "\"" as char
        var i 0
>>>NEW
        set *buf: "x" as char
        var i 0
SPEC

run "c2 the module symbol's name has its EXTENSION removed" <<SPEC
FILE $B
<<<OLD
        let len remove_file_extension(file_name_data, file_name_len)
>>>NEW
        let len file_name_len
SPEC

run "c3 the file name is the NORMALIZED ABSOLUTE path, not the raw argument" <<SPEC
FILE $S
<<<OLD
    let path String(name_data as pointer[const_char], name_len as size_t)
>>>NEW
    let path String(arg)
SPEC

run "c4 remove_file_extension tries .d.ts BEFORE .ts" <<SPEC
FILE $T
<<<OLD
    var r has_suffix(d, n, ".d.ts")
    if r >= 0
        return r
>>>NEW
    var r has_suffix(d, n, ".ts")
    if r >= 0
        return r
SPEC

run "c5 export= is an UNPREFIXED internal name" <<SPEC
FILE $B
<<<OLD
        if k = KindSourceFile
        {
            set *out_len: Binder.internal_name_unprefixed(host, "export=", out_data)
            return
        }
>>>NEW
        if k = KindSourceFile
        {
            set *out_len: Binder.internal_name(host, "export=", out_data)
            return
        }
SPEC

# ── the JSON arm ─────────────────────────────────────────────────────────────

run "c6 the JSON arm RESTORES the file's own symbol after the module.exports one" <<SPEC
FILE $B
<<<OLD
                this.declare_symbol(Symbol.get_exports(host, original_symbol), original_symbol, file, SymbolFlagsProperty, SymbolFlagsAll)
                set file.symbol: original_symbol
>>>NEW
                this.declare_symbol(Symbol.get_exports(host, original_symbol), original_symbol, file, SymbolFlagsProperty, SymbolFlagsAll)
SPEC

# ★★★ c7 CAME BACK UNGATED AND THE PREDICTION WAS RED, which is the row's whole
# value: the JSON guard in external_module_indicator is a faithful transcription of
# an arm that cannot change an answer TODAY, because the only way past it is a
# top-level statement with an export modifier, an import/export declaration or an
# `import.meta` — and the JSON grammar produces exactly one ExpressionStatement.
# UNGATED-because-indistinguishable (§3.5v's third reason), not because the port is
# insensitive to the claim. It stays because the arm is the reference's; what would
# make it observable is a JSON parse that can produce a module indicator, which is
# a change to the second grammar and not to the binder.
run "c7 (expected UNGATED-indistinguishable) a JSON file is never an external MODULE" <<SPEC
FILE $P
<<<OLD
        if (AstNode.flags_of(file) & NodeFlagsJsonFile) <> 0
            return false
        file_is_external_module(file, statements)
>>>NEW
        file_is_external_module(file, statements)
SPEC

# ── the two symbols of an exported declaration ───────────────────────────────

run "c8 an exported declaration's LOCAL carries only the ExportValue flag" <<SPEC
FILE $B
<<<OLD
            let local this.declare_symbol(Binder.get_locals(host, container), null as pointer[Symbol], n, export_kind, symbol_excludes)
>>>NEW
            let local this.declare_symbol(Binder.get_locals(host, container), null as pointer[Symbol], n, symbol_flags, symbol_excludes)
SPEC

run "c9 the local is JOINED to the export symbol" <<SPEC
FILE $B
<<<OLD
            if local <> null
                set local.export_symbol: exported_symbol
>>>NEW
            if local <> null
                set local.export_symbol: null as pointer[Symbol]
SPEC

run "c10 an AMBIENT container's export CONTEXT exports without a modifier" <<SPEC
FILE $B
<<<OLD
        if (AstNode.flags_of(container) & NodeFlagsExportContext) <> 0
            set exported: true
        if Binder.is_ambient_module(n)
>>>NEW
        if Binder.is_ambient_module(n)
SPEC

run "c11 an UNNAMED default export gets no local symbol at all" <<SPEC
FILE $B
<<<OLD
            let cs AstNode.symbol_of(container)
            if no_local
                return this.declare_symbol(Symbol.get_exports(host, cs), cs, n, symbol_flags, symbol_excludes)
>>>NEW
            let cs AstNode.symbol_of(container)
SPEC

# ── the two rows expected UNGATED, and which of the four reasons it is ────────
#
# is_ambient_module can only be asked of a node that reached declare_module_member,
# and the only kind it answers TRUE for is a ModuleDeclaration, whose bind arm is
# unported — so this is UNGATED-because-unreachable, not because the port is
# insensitive to it. The ALIAS arm is the same shape one level up: every kind that
# carries SymbolFlagsAlias (ImportClause, NamespaceImport, ImportSpecifier,
# ExportSpecifier, ImportEqualsDeclaration) still reports its own bind arm.

run "c12 (expected UNGATED-unreachable) an ambient module is NOT exported by its context" <<SPEC
FILE $B
<<<OLD
        if Binder.is_ambient_module(n)
            set exported: false
>>>NEW
        if false
            set exported: false
SPEC

run "c13 (expected UNGATED-unreachable) an exported alias declares into EXPORTS" <<SPEC
FILE $B
<<<OLD
            if into_exports
            {
                let cs AstNode.symbol_of(container)
>>>NEW
            if false
            {
                let cs AstNode.symbol_of(container)
SPEC

echo
echo "################################################################"
bold "the verifying run — the report must reproduce the baseline byte for byte"
"$RUN" > /tmp/ctl28-final.log 2>&1 </dev/null
if cmp -s "$TSCALY_BASELINE" /tmp/ctl28-final.log; then
  green "IDENTICAL to the baseline report — the tree came back"
else
  red "the final report DIFFERS from the baseline:"
  diff "$TSCALY_BASELINE" /tmp/ctl28-final.log | head -30
  exit 1
fi
