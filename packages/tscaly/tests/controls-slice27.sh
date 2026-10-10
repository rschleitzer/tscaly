#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice27.sh — the slice-27 control battery, ten of them (nine RED).
#
# Slice 27 is the binder's skeleton, and the claims worth breaking are not about
# which arms exist — the `unported` column already says that — but about the four
# things the arms rest on: the TRAVERSAL ORDER the flow half prescribes, the
# MERGE (one symbol, several declarations), the DIAGNOSTIC pair a conflict
# produces, and the two places a node's PARENT decides where a declaration lands.
#
# ★★★ THE ROW TO READ FIRST IS c1. `bindParameterFlow` binds a parameter's NAME
# LAST — after the modifiers, the `...`, the `?`, the type and the initializer —
# where ForEachChild visits it third, and this row is what says whether that
# difference is observable at all. If it is UNGATED, the arm is a transcription
# nobody can check and the comment above it has to say so.
#
# ★★ NINE FIXTURES came with this slice so that the rows below have something to be
# red about on STAGE 1: a merged symbol (`var x` twice, and `function f` twice), a
# duplicate block-scoped declaration (TS2451 at BOTH positions), `eval` as a
# parameter name (TS1100), a reserved word in strict mode (TS1212), a classifiable
# type parameter, and a parameter whose default reads an earlier parameter. Without
# them the corpus's bind diagnostics all sit in units this slice reports as unported,
# and half of these rows would be UNGATED for a reason that says nothing about the
# claim.
#
# ★★★ TWO OF THOSE NINE WERE WRITTEN BECAUSE A ROW ASKED FOR THEM, which is §3.5ap
# from the useful end: c1 and c2 — the two ORDER claims, the ones this battery exists
# for — came back UNGATED on the first pass, and neither was unreachable. The order
# of a bind is observable only where two declarations or two DIAGNOSTICS of one
# construct come out in a different sequence, so:
#   `binder_var_and_function.ts`      `var g` beside `function g` — one conflict,
#                                     two TS2300, and functions-first decides which
#                                     position is reported first (c2)
#   `binder_parameter_bind_order.ts`  `function f(implements: yield)` in strict mode —
#                                     the NAME and the TYPE each earn a TS1212, and
#                                     the reference binds the type first (c1)
# Both rows are RED with them. A control that reports UNGATED is a question about the
# corpus before it is a verdict about the claim.
#
# ★ c3 reproduces the defect the yardstick found on its first run: the JSON arm of
# bindSourceFileIfExternalModule was absent, so six units got a well-formed `f 0 0`
# instead of a column entry. It is the row that measures the difference between a
# missing arm and a reported one.
#
# Usage (it patches the source tree and restores it after every control, so
# nothing may edit the tree while it runs — §3.5y):
#
#   packages/tscaly/tests/controls-slice27.sh 2>&1 | tee /tmp/battery27.log
#
# 1 baseline + 10 controls + 1 verifying run = 12 runs.

set -u
cd "$(dirname "$0")/../../.."

CTL=packages/tscaly/tests/ctl.sh
RUN=packages/tscaly/tests/run.sh
B=packages/tscaly/0.1.2/tscaly/binder.scaly
D=packages/tscaly/0.1.2/tscaly/SymbolDump.scaly

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

# ── the traversal order ──────────────────────────────────────────────────────

run "c1 a parameter's children are bound in ForEachChild order, not the flow order" <<SPEC
FILE $B
<<<OLD
            this.bind_each(AstNode.modifiers_of(n))
            this.bind(AstNode.dot_dot_dot_token_of(n))
            this.bind(AstNode.parameter_question_token_of(n))
            this.bind(AstNode.type_of(n))
            this.bind(AstNode.initializer_of(n))
            this.bind(AstNode.name_of(n))
>>>NEW
            this.bind_each_child(n)
SPEC

run "c2 a source file's statements are bound in source order, functions not first" <<SPEC
FILE $B
<<<OLD
            this.bind_each_statement_functions_first(AstNode.statements_of(n))
            this.bind(AstNode.end_of_file_token_of(n))
>>>NEW
            this.bind_each(AstNode.statements_of(n))
            this.bind(AstNode.end_of_file_token_of(n))
SPEC

# ── the arm that reports rather than answers ─────────────────────────────────

run "c3 the JSON arm answers instead of reporting itself" <<SPEC
FILE $B
<<<OLD
        if (AstNode.flags_of(file) & NodeFlagsJsonFile) <> 0
            this.record_unported("source-file-as-json", 0)
>>>NEW
        if (AstNode.flags_of(file) & NodeFlagsJsonFile) <> 0
            return
SPEC

# ── the merge, and the two halves of a conflict's report ─────────────────────
#
# c4 makes every declaration its own symbol, which is the defect the dump's
# identity numbering exists to catch: the SHAPE at each node is unchanged.

run "c4 a name already in the table is not looked up, so nothing ever merges" <<SPEC
FILE $B
<<<OLD
            set s: SymbolTable.get(table, name_data, name_len)
>>>NEW
            set s: null as pointer[Symbol]
SPEC

run "c5 a conflict is not reported at the NEW declaration" <<SPEC
FILE $B
<<<OLD
            this.error_on_node(decl, code)
            set i: i + 1
        }
        this.error_on_node(declaration_name, code)
>>>NEW
            this.error_on_node(decl, code)
            set i: i + 1
        }
SPEC

run "c6 a symbol's value declaration is overwritten by every later one" <<SPEC
FILE $B
<<<OLD
        if s.value_declaration = null
            set s.value_declaration: n
>>>NEW
        set s.value_declaration: n
SPEC

# ── the two places PARENT decides the answer ────────────────────────────────
#
# c7 is the row that says whether porting Node.Parent with this slice was
# load-bearing: a block's container flags depend on whether its parent is
# function-like, and without that test a function BODY becomes a scope of its own,
# so every `let` in it lands in the block's table instead of the function's.

run "c7 a block's container flags are decided without asking for its PARENT" <<SPEC
FILE $B
<<<OLD
        if k = KindBlock
        {
            let p AstNode.parent_node_of(n)
>>>NEW
        if k = KindBlock
        {
            let p null as pointer[AstNode]
SPEC

run "c8 the classifiable-name set is not filled" <<SPEC
FILE $B
<<<OLD
            if (includes & SymbolFlagsClassifiable) <> 0
                SymbolTable.set_entry(host, classifiable_names, name_data, name_len, null as pointer[Symbol])
>>>NEW
            if (includes & SymbolFlagsClassifiable) <> 0
                set name_len: name_len
SPEC

run "c9 the symbol counter is not incremented per newSymbol" <<SPEC
FILE $B
<<<OLD
        set symbol_count: symbol_count + 1
>>>NEW
        set symbol_count: symbol_count
SPEC

# ── the dump's own one normalisation ────────────────────────────────────────
#
# The tables are sorted by NAME, on UNSIGNED bytes, because an internal symbol name
# begins with 0xFE and sorts after every ASCII name that way and before all of them
# signed. This row asks whether any unit this slice binds can tell the difference —
# an internal name is made by `bindAnonymousDeclaration` and by the nameless
# declaration kinds, all of which are still unported, so the honest expectation is
# UNGATED-because-unreachable (§3.5v) and the row is here to say which of the four
# it is rather than to leave it unstated.

run "c10 the table sort compares name bytes as SIGNED" <<SPEC
FILE $D
<<<OLD
            let a (*(ad + i)) as u8
            let b (*(bd + i)) as u8
>>>NEW
            let a (*(ad + i)) as int
            let b (*(bd + i)) as int
SPEC

echo
echo "################################################################"
bold "the verifying run — the report must reproduce the baseline byte for byte"
"$RUN" > /tmp/ctl27-final.log 2>&1 </dev/null
if cmp -s "$TSCALY_BASELINE" /tmp/ctl27-final.log; then
  green "IDENTICAL to the baseline report — the tree came back"
else
  red "the final report DIFFERS from the baseline:"
  diff "$TSCALY_BASELINE" /tmp/ctl27-final.log | head -30
  exit 1
fi
