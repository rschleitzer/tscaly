#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice41.sh — the slice-41 control battery, eighteen of them.
#
# Slice 41 is the PRIVATE NAME: a class member declared `#x` is named after the
# CLASS it sits in, `GetSymbolNameForPrivateIdentifier(containingClass.Symbol(),
# name.Text())`, i.e. the 0xFE prefix, a `#`, the containing class symbol's
# lazily drawn id, an `@` and the text. It is the head slices 31–40 deferred,
# because the id is the mechanism §3.10 diverges from.
#
# ★★★ FOUR GROUPS, AND THE SECOND ONE IS WHY THE BATTERY EXISTS.
#
#   c1        what the slice UNLOCKS: the arm at all.
#
#   c2..c5    the DRAW, which is the decision this slice had to make and the only
#             part of it that no amount of reading the reference settles. Four
#             rows for four ways to be wrong about WHEN a symbol takes a number:
#             at creation (the shape §3.10 argues for node ids), per request
#             rather than once, from a counter that starts at the wrong place, and
#             not read at all. ★Each produces well-formed names throughout — the
#             numbers are the only place the difference is visible, which is
#             exactly why they are measured rather than argued.
#
#   c6..c12   the NAME's arithmetic: the prefix byte, the two separators, the
#             length, the digit count, the digit order, and the description's
#             bytes.
#
#   c13..c18  the CONTAINING CLASS: that it is asked at all, that the null answer
#             is `missing` rather than a marker, that the innermost class-like
#             wins, that the walk's STARTING POINT is load-bearing — and the
#             class-unbound marker itself, expected UNGATED, since a class-like
#             node is always declared by the time its members are bound.
#
# ★★★ c16 IS UNGATED BY CONSTRUCTION AND c18 IS THE CLAIM IT WANTED TO MAKE. The
# reference walks from `node.Parent`, and the loop's first test is on the start
# node itself — so `node` and `node.Parent` can differ ONLY when the start node is
# itself class-like, and not one of the three callers ever passes one (a private
# member's declaration, an identifier, and a variable/function/catch context). The
# difference is therefore a CONJUNCTION — the wrong start AND a class-like argument
# — and `ctl.sh` patches one contiguous block of one file. c18 states it as one
# mutation of one site instead, starting the walk one level ABOVE the declaration,
# where the class the arm must find is exactly what gets skipped. Same shape as
# slice 40's c15/c18 pair: **a row whose own verdict is UNGATED can still be
# load-bearing, and the row that proves it is a row about something else.**
#
# ★★ c15 and c16 patch `get_containing_class`, whose two OTHER callers are the
# strict-mode messages, so each of those rows counts more than this arm — labelled
# rather than dressed up, the way slice 40's c16/c17 are: a row whose scope is
# wider than its title is a wrong number wearing a right one's clothes.
#
# Usage (it patches the source tree and restores it after every control, so
# nothing may edit the tree while it runs — §3.5y):
#
#   packages/tscaly/tests/controls-slice41.sh 2>&1 | tee /tmp/battery41.log
#
# 1 baseline + 18 controls + 1 verifying run = 20 runs, about 11 minutes on an
# idle box. ★If it takes hours, read §3.5ck before suspecting the battery: a
# stage-2 artifact tree created and deleted under packages/ leaves this machine's
# own indexer busy for a long time afterwards. A control's VERDICT is a count and
# survives that; its timing does not.

set -u
cd "$(dirname "$0")/../../.."

CTL=packages/tscaly/tests/ctl.sh
RUN=packages/tscaly/tests/run.sh
B=packages/tscaly/0.1.2/tscaly/binder.scaly

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

# ── group 1: what the slice unlocks ──────────────────────────────────────────

run "c1 a private name is named at all" <<SPEC
FILE $B
<<<OLD
                let id this.get_symbol_id(cs)
                let td AstNode.identifier_text_of(name)
                let tl AstNode.identifier_text_length_of(name)
                set *out_len: Binder.private_identifier_name(host, id, td, tl, out_data)
                return
>>>NEW
                this.record_unported("declaration-name-private-identifier", 0)
                return
SPEC

# ── group 2: the draw — the decision ─────────────────────────────────────────

run "c2 the id is drawn LAZILY, not at symbol creation" <<SPEC
FILE $B
<<<OLD
        set symbol_count: symbol_count + 1
        Symbol.create(host, flags, name_data, name_len)
>>>NEW
        set symbol_count: symbol_count + 1
        let s Symbol.create(host, flags, name_data, name_len)
        set next_symbol_id: next_symbol_id + 1
        set s.id: next_symbol_id
        s
SPEC

run "c3 ... and ONCE per symbol, not once per request" <<SPEC
FILE $B
<<<OLD
        if s.id = 0
        {
            set next_symbol_id: next_symbol_id + 1
            set s.id: next_symbol_id
        }
        s.id
>>>NEW
        set next_symbol_id: next_symbol_id + 1
        set s.id: next_symbol_id
        s.id
SPEC

run "c4 the first id drawn is 1 (the counter starts at zero)" <<SPEC
FILE $B
<<<OLD
        set b.next_symbol_id: 0
>>>NEW
        set b.next_symbol_id: 1
SPEC

run "c5 the id is READ (hardwired 1: every class is class 1)" <<SPEC
FILE $B
<<<OLD
                let id this.get_symbol_id(cs)
>>>NEW
                let id 1
SPEC

# ── group 3: the name ────────────────────────────────────────────────────────

run "c6 the prefix is the 0xFE byte, not an ASCII underscore" <<SPEC
FILE $B
<<<OLD
        set *buf: 0xFE as char
        set *(buf + 1): "#" as char
>>>NEW
        set *buf: "_" as char
        set *(buf + 1): "#" as char
SPEC

run "c7 the first separator is a '#'" <<SPEC
FILE $B
<<<OLD
        set *(buf + 1): "#" as char
>>>NEW
        set *(buf + 1): "@" as char
SPEC

run "c8 the second separator is an '@'" <<SPEC
FILE $B
<<<OLD
        set *(buf + 2 + digits): "@" as char
>>>NEW
        set *(buf + 2 + digits): "#" as char
SPEC

run "c9 the returned LENGTH counts prefix, separators and text" <<SPEC
FILE $B
<<<OLD
        set *out_data: buf
        total
    }
>>>NEW
        set *out_data: buf
        total - 1
    }
SPEC

run "c10 the digit COUNT is measured (hardwired 1)" <<SPEC
FILE $B
<<<OLD
        var digits 1
        var rest id / 10
        while rest > 0
        {
            set digits: digits + 1
            set rest: rest / 10
        }
>>>NEW
        var digits 1
SPEC

run "c11 the digits are written most-significant-LAST" <<SPEC
FILE $B
<<<OLD
        var value id
        var i digits
        while i > 0
        {
            set *(buf + 1 + i): ((("0" as char) as int) + (value % 10)) as char
            set value: value / 10
            set i: i - 1
        }
>>>NEW
        var value id
        var i 1
        while i <= digits
        {
            set *(buf + 1 + i): ((("0" as char) as int) + (value % 10)) as char
            set value: value / 10
            set i: i + 1
        }
SPEC

run "c12 the description's bytes are the private identifier's own TEXT" <<SPEC
FILE $B
<<<OLD
            set *(buf + 3 + digits + j): *(desc_data + j)
>>>NEW
            set *(buf + 3 + digits + j): "x" as char
SPEC

# ── group 4: the containing class ────────────────────────────────────────────

run "c13 the containing class is ASKED for (hardwired null: every name missing)" <<SPEC
FILE $B
<<<OLD
                let containing_class Binder.get_containing_class(n)
>>>NEW
                let containing_class null as pointer[AstNode]
SPEC

run "c14 the null class answers 'missing' rather than a marker" <<SPEC
FILE $B
<<<OLD
                if containing_class = null
                {
                    set *out_len: Binder.internal_name(host, "missing", out_data)
                    return
                }
>>>NEW
                if containing_class = null
                {
                    this.record_unported("private-identifier-no-class", 0)
                    return
                }
SPEC

run "c15 the INNERMOST class-like wins (shared: also the strict-mode messages)" <<SPEC
FILE $B
<<<OLD
        var p AstNode.parent_node_of(n)
        while p <> null
        {
            let k AstNode.kind_of(p)
            if k = KindClassDeclaration
                return p
            if k = KindClassExpression
                return p
            set p: AstNode.parent_node_of(p)
        }
        null
>>>NEW
        var p AstNode.parent_node_of(n)
        var last null as pointer[AstNode]
        while p <> null
        {
            let k AstNode.kind_of(p)
            if k = KindClassDeclaration
                set last: p
            if k = KindClassExpression
                set last: p
            set p: AstNode.parent_node_of(p)
        }
        last
SPEC

run "c16 the walk starts at the PARENT (shared: also the strict-mode messages)" <<SPEC
FILE $B
<<<OLD
        var p AstNode.parent_node_of(n)
        while p <> null
        {
            let k AstNode.kind_of(p)
            if k = KindClassDeclaration
                return p
>>>NEW
        var p n
        while p <> null
        {
            let k AstNode.kind_of(p)
            if k = KindClassDeclaration
                return p
SPEC

run "c17 the class-unbound marker — expected UNGATED, a class-like is declared first" <<SPEC
FILE $B
<<<OLD
                if cs = null
                {
                    this.record_unported("private-identifier-class-unbound", 0)
                    return
                }
>>>NEW
                if cs = null
                {
                    set *out_len: Binder.internal_name(host, "missing", out_data)
                    return
                }
SPEC

run "c18 the walk starts at the DECLARATION (one level up skips its own class)" <<SPEC
FILE $B
<<<OLD
                let containing_class Binder.get_containing_class(n)
>>>NEW
                let containing_class Binder.get_containing_class(AstNode.parent_node_of(n))
SPEC

echo
echo "################################################################"
bold "the verifying run — the report must reproduce the baseline byte for byte"
"$RUN" > /tmp/ctl41-final.log 2>&1 </dev/null
if cmp -s "$TSCALY_BASELINE" /tmp/ctl41-final.log; then
  green "IDENTICAL to the baseline report — the tree came back"
else
  red "the final report DIFFERS from the baseline:"
  diff "$TSCALY_BASELINE" /tmp/ctl41-final.log | head -30
  exit 1
fi
