#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice36.sh — the slice-36 control battery, thirty-two of them.
#
# Slice 36 ports the LAST thirteen arms of the reference's bindChildren switch:
# the statement-flow chapter — if / while / do / the three `for` heads / switch
# with its three clause kinds / break / continue — plus the conditional
# expression. Every one of them is a flow arm upstream, so what the port claims
# is the TRAVERSAL, and the reading that decided the slice is that ten of the
# thirteen visit children in ForEachChild's own order while three do not.
#
# ★★★ THE BATTERY IS IN THREE GROUPS BECAUSE THE SLICE HAS THREE DIFFERENT
# CLAIMS, and only the middle group is about this port's own code.
#
#   c1..c13   what each arm UNLOCKS. Each row makes that one ARM report
#             `bind-children` again — the pre-slice behaviour exactly — so the
#             number is the units that kind was parking. ★It has to be the arm and
#             NOT the inventory list; the note over the group has the account, and
#             the first draft of this battery is what paid for it.
#             ★ THEY OVERLAP BY CONSTRUCTION: a unit with a `switch` is counted
#             by c9, c10, c11 and c12 alike, and a file with one `if` anywhere in
#             it is counted by c6 whatever else it holds. Slice 34's c5..c11 are
#             the same arithmetic — the same number is not the same control, and
#             the DIFF tells them apart where the count cannot.
#
#   c14..c24  the three reorders and the six accessors they need. These are the
#             rows that gate this slice's own lines: the `for` head binding its
#             BODY before its INCREMENTOR, and the `for-in`/`for-of` head binding
#             its EXPRESSION first.
#
#   c25..c32  the falsifiability of the ten "= ForEachChild" rows, and this group
#             exists because of the negative-control lesson: *indistinguishable*
#             is only an honest verdict if the corpus COULD have seen a
#             difference. Each row reverses that one kind's child walk in place —
#             no new accessor, so nothing dead is added to the tree — and a RED
#             says the B section can witness that kind's order, i.e. the verdict
#             is a statement about the REFERENCE and not about a blind spot.
#             ★ Break and Continue get no row: their arm has ONE child, so a
#             reversal is the identity and the claim is arithmetic rather than
#             measured.
#
# ★ Where the two order fixtures come from and why they look like that: symbols
# are numbered in WALK order (slice 33), so a bind ORDER shows only in the B
# section, which is a bind-order append of the bind diagnostics. Both fixtures
# therefore put a REPORTING expression in each of the two slots that swap —
# `eval = n` in a `for` head's incrementor and body, an `eval`/`arguments`
# declaration against an assignment in the `for-in`/`for-of` expression — and the
# reference's own B section comes out non-monotonic in POSITION, which is a thing
# only a reorder can produce.
#
# Usage (it patches the source tree and restores it after every control, so
# nothing may edit the tree while it runs — §3.5y):
#
#   packages/tscaly/tests/controls-slice36.sh 2>&1 | tee /tmp/battery36.log
#
# 1 baseline + 32 controls + 1 verifying run = 34 runs, about 11 minutes.

set -u
cd "$(dirname "$0")/../../.."

CTL=packages/tscaly/tests/ctl.sh
RUN=packages/tscaly/tests/run.sh
B=packages/tscaly/0.1.2/tscaly/binder.scaly
A=packages/tscaly/0.1.2/tscaly/ast.scaly

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

# ── group 1: what each of the thirteen arms unlocks ──────────────────────────
#
# ★★★ THESE ROWS PATCH THE ARM AND NOT THE INVENTORY LIST, and the first draft of
# this battery got it wrong in the direction ctl.sh warns about — reporting too
# LOW. Slice 35's equivalent rows put the kind back on
# kind_has_unported_bind_arm, which works there because those fifteen kinds have
# no arm of their own: the list IS the switch entry. Here every one of the
# thirteen has an explicit arm ABOVE the gate, so adding the kind to the list
# changes nothing at all — c1 duly reported UNGATED with the patch verified as
# applied. What restores the pre-slice behaviour is making the ARM report.

unlock_default() {  # $1 = row label, $2 = kind constant — the ten default arms
  run "$1" <<SPEC
FILE $B
<<<OLD
        if k = $2
        {
            this.bind_each_child(n)
            return
        }
>>>NEW
        if k = $2
        {
            this.record_unported("bind-children", k)
            return
        }
SPEC
}

unlock_default "c1 the while statement has a bindChildren arm"  KindWhileStatement
unlock_default "c2 the do statement has one"                    KindDoStatement

run "c3 the for statement has one" <<SPEC
FILE $B
<<<OLD
            this.bind(AstNode.initializer_of(n))
            this.bind(AstNode.for_condition_of(n))
            this.bind(AstNode.statement_of(n))
            this.bind(AstNode.for_incrementor_of(n))
>>>NEW
            this.record_unported("bind-children", k)
SPEC

run "c4 the for-in statement has one" <<SPEC
FILE $B
<<<OLD
        if k = KindForInStatement
        {
            this.bind_for_in_or_of_statement(n)
            return
        }
>>>NEW
        if k = KindForInStatement
        {
            this.record_unported("bind-children", k)
            return
        }
SPEC

run "c5 the for-of statement has one" <<SPEC
FILE $B
<<<OLD
        if k = KindForOfStatement
        {
            this.bind_for_in_or_of_statement(n)
            return
        }
>>>NEW
        if k = KindForOfStatement
        {
            this.record_unported("bind-children", k)
            return
        }
SPEC

unlock_default "c6 the if statement has one"                    KindIfStatement
unlock_default "c7 the break statement has one"                 KindBreakStatement
unlock_default "c8 the continue statement has one"              KindContinueStatement
unlock_default "c9 the switch statement has one"                KindSwitchStatement
unlock_default "c10 the case block has one"                     KindCaseBlock
unlock_default "c11 the case clause has one"                    KindCaseClause
unlock_default "c12 the default clause has one"                 KindDefaultClause
unlock_default "c13 the conditional expression has one"         KindConditionalExpression

# ── group 2: the three reorders, and the accessors they are made of ──────────

# ★★★ The slice's first observable claim: the reference binds a `for` head's BODY
# before its INCREMENTOR, where ForEachChild visits the incrementor third.
run "c14 the for statement binds its BODY before its INCREMENTOR" <<SPEC
FILE $B
<<<OLD
            this.bind(AstNode.initializer_of(n))
            this.bind(AstNode.for_condition_of(n))
            this.bind(AstNode.statement_of(n))
            this.bind(AstNode.for_incrementor_of(n))
>>>NEW
            this.bind_each_child(n)
SPEC

# ★★★ The second: the for-in/for-of head binds its EXPRESSION first, where
# ForEachChild visits it third — after the await modifier and the initializer.
run "c15 the for-in/of head binds its EXPRESSION first" <<SPEC
FILE $B
<<<OLD
        this.bind(AstNode.expression_of(n))
        if AstNode.kind_of(n) = KindForOfStatement
            this.bind(AstNode.for_await_modifier_of(n))
        this.bind(AstNode.initializer_of(n))
        this.bind(AstNode.statement_of(n))
>>>NEW
        this.bind_each_child(n)
SPEC

# The await modifier's POSITION inside that arm — expected UNGATED, and the
# reason is worth measuring rather than asserting: an await modifier is a TOKEN,
# and binding a token produces nothing at all.
run "c16 the await modifier is bound AFTER the expression" <<SPEC
FILE $B
<<<OLD
        this.bind(AstNode.expression_of(n))
        if AstNode.kind_of(n) = KindForOfStatement
            this.bind(AstNode.for_await_modifier_of(n))
>>>NEW
        if AstNode.kind_of(n) = KindForOfStatement
            this.bind(AstNode.for_await_modifier_of(n))
        this.bind(AstNode.expression_of(n))
SPEC

# The KIND test on it — the `in` form is built with a null in that slot, so
# dropping the test binds a null. Same expectation, a different reason.
run "c17 the await modifier is bound on the OF form only" <<SPEC
FILE $B
<<<OLD
        if AstNode.kind_of(n) = KindForOfStatement
            this.bind(AstNode.for_await_modifier_of(n))
>>>NEW
        this.bind(AstNode.for_await_modifier_of(n))
SPEC

run "c18 for_condition_of answers a ForStatement" <<SPEC
FILE $A
<<<OLD
            when fs: ForStatement
                return fs.condition
>>>NEW
SPEC

run "c19 for_incrementor_of answers a ForStatement" <<SPEC
FILE $A
<<<OLD
            when fs: ForStatement
                return fs.incrementor
>>>NEW
SPEC

run "c20 for_await_modifier_of answers a ForOfStatement" <<SPEC
FILE $A
<<<OLD
            when fos: ForOfStatement
                return fos.await_modifier
>>>NEW
SPEC

run "c21 expression_of answers a ForInStatement" <<SPEC
FILE $A
<<<OLD
            when fis: ForInStatement
                return fis.expression
>>>NEW
SPEC

run "c22 expression_of answers a ForOfStatement" <<SPEC
FILE $A
<<<OLD
            when fos: ForOfStatement
                return fos.expression
>>>NEW
SPEC

run "c23 initializer_of answers the three for kinds" <<SPEC
FILE $A
<<<OLD
            when fs: ForStatement
                return fs.initializer
            when fis: ForInStatement
                return fis.initializer
            when fos: ForOfStatement
                return fos.initializer
>>>NEW
SPEC

run "c24 statement_of answers the three for kinds" <<SPEC
FILE $A
<<<OLD
            when fs: ForStatement
                return fs.statement
            when fis: ForInStatement
                return fis.statement
            when fos: ForOfStatement
                return fos.statement
>>>NEW
SPEC

# ── group 3: can the corpus SEE the order of the ten default-arm kinds? ──────
#
# Each row replaces one kind's bind_each_child with the SAME walk in reverse. A
# RED means *indistinguishable* is a claim about the reference; an UNGATED means
# the corpus cannot witness that kind's order at all, and the row would then have
# to say so.

reverse() {  # $1 = row label, $2 = kind constant
  run "$1" <<SPEC
FILE $B
<<<OLD
        if k = $2
        {
            this.bind_each_child(n)
            return
        }
>>>NEW
        if k = $2
        {
            var m 0
            while AstNode.child_at(n, m) <> null
                set m: m + 1
            while m > 0
            {
                set m: m - 1
                this.bind(AstNode.child_at(n, m))
            }
            return
        }
SPEC
}

reverse "c25 the corpus can see a while statement's child order"       KindWhileStatement
reverse "c26 ... a do statement's"                                     KindDoStatement
reverse "c27 ... an if statement's"                                    KindIfStatement
reverse "c28 ... a switch statement's"                                 KindSwitchStatement
reverse "c29 ... a case block's clause order"                          KindCaseBlock
reverse "c30 ... a case clause's"                                      KindCaseClause
reverse "c31 ... a default clause's statement order"                   KindDefaultClause
reverse "c32 ... a conditional expression's"                           KindConditionalExpression

echo
echo "################################################################"
bold "the verifying run — the report must reproduce the baseline byte for byte"
"$RUN" > /tmp/ctl36-final.log 2>&1 </dev/null
if cmp -s "$TSCALY_BASELINE" /tmp/ctl36-final.log; then
  green "IDENTICAL to the baseline report — the tree came back"
else
  red "the final report DIFFERS from the baseline:"
  diff "$TSCALY_BASELINE" /tmp/ctl36-final.log | head -30
  exit 1
fi
