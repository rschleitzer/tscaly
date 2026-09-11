#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice45.sh — the slice-45 control battery, eight of them.
#
# Slice 45 is GetErrorRangeForNode's FALLBACK: the span of a diagnostic reported
# on a declaration that has no name. It is one call — the re-scan
# range_of_token_at_position, ported in slice 31 — so the battery is not about how
# much code landed. It is about the four things that one line decides, and about
# the claim the slice makes with no code at all: that the eight arms still
# deferred cannot be reached from this port at all.
#
# ★★★ THREE GROUPS.
#
#   c1        what the slice UNLOCKS: the fallback at all.
#
#   c2..c5    what the one line says, which is four claims and not one — the span
#             is the FIRST TOKEN and not the construct (c2), it is taken at the
#             node's OWN start (c3), it begins past the leading TRIVIA (c4), and
#             it is reached only when there is NO name (c5).
#
#   c6..c7    the route: an anonymous ClassDeclaration and an anonymous
#             FunctionDeclaration reach the fallback THROUGH the
#             declaration-name list, which is why the arm is not per-kind.
#
#   c8        the UNREACHABILITY claim, and it is the row that is supposed to
#             stay UNGATED. Letting the deferred arms fall through to the
#             ordinary path moves nothing, because no binder diagnostic can carry
#             one of those kinds — the enumeration is in binder.scaly below
#             error_range_for_node and the reader that earns them is the CHECKER.
#             A row whose UNGATED verdict is the finding needs its argument
#             written down beside it (§3.5v's four verdicts), or the next reader
#             takes it for a missing fixture.
#             ★ RETARGETED IN SLICE 194: seven of the eight arms are ported, so
#             the guard this row patches is the ONE that is left — the satisfies
#             arm's Reparsed test, whose false branch is the JSDoc stop. The claim
#             is unchanged and so is the expected verdict.
#
# ★★ c4 PATCHES SLICE 31's LINE, NOT SLICE 45's, and it is here on purpose: the
# fallback's start is past the leading trivia only because the re-scan skips it,
# and that skip belongs to the shared helper. So the row also moves the
# error_on_first_token units, and its number is therefore larger than the two
# fixtures this slice added. It says *the fallback inherits the trivia skip*, not
# *this many units are the slice*.
#
# ★ c2 and c3 patch the SAME line with different wrong answers, which is the c3/c7
# shape of slice 44's battery: one produces the whole construct (a well-formed
# wrong span) and the other reads the token AFTER it (a span outside the node).
#
# Usage (it patches the source tree and restores it after every control, so
# nothing may edit the tree while it runs — §3.5y):
#
#   packages/tscaly/tests/controls-slice45.sh 2>&1 | tee /tmp/battery45.log
#
# 1 baseline + 8 controls = 9 runs, about 5 minutes on an idle box. ★If it takes
# hours, read §3.5ck before suspecting the battery.

set -u
cd "$(dirname "$0")/../../.."

CTL=packages/tscaly/tests/ctl.sh
B=packages/tscaly/0.1.0/tscaly/binder.scaly

export TSCALY_BASELINE=$(mktemp -t tscaly-baseline)
cleanup() { rm -f "$TSCALY_BASELINE" "$TSCALY_BASELINE.fp"; }
trap cleanup EXIT

echo "################################################################"
if ! "$CTL" --establish-baseline </dev/null; then
  exit 2
fi

run() { echo; echo "################################################################"; "$CTL" "$1"; }

# ── group 1: what the slice unlocks ──────────────────────────────────────────

run "c1 a declaration with no name gets a span at all" <<SPEC
FILE $B
<<<OLD
        if error_node = null
        {
            this.range_of_token_at_position(AstNode.pos_of(n), out_start, out_end)
            return true
        }
>>>NEW
        if error_node = null
        {
            this.record_unported("error-range-no-name", k)
            return false
        }
SPEC

# ── group 2: the four claims of the one line ─────────────────────────────────

run "c2 the span is the FIRST TOKEN, not the whole construct" <<SPEC
FILE $B
<<<OLD
            this.range_of_token_at_position(AstNode.pos_of(n), out_start, out_end)
>>>NEW
            set *out_start: AstNode.pos_of(n)
            set *out_end: AstNode.end_of(n)
SPEC

run "c3 the token is taken at the node's OWN start" <<SPEC
FILE $B
<<<OLD
            this.range_of_token_at_position(AstNode.pos_of(n), out_start, out_end)
>>>NEW
            this.range_of_token_at_position(AstNode.end_of(n), out_start, out_end)
SPEC

run "c4 the span begins past the leading TRIVIA (slice 31's skip)" <<SPEC
FILE $B
<<<OLD
        set *out_start: trivia.token_start()
>>>NEW
        set *out_start: pos
SPEC

run "c5 the fallback is reached only when there is NO name" <<SPEC
FILE $B
<<<OLD
        if error_node = null
        {
            this.range_of_token_at_position(AstNode.pos_of(n), out_start, out_end)
>>>NEW
        if true
        {
            this.range_of_token_at_position(AstNode.pos_of(n), out_start, out_end)
SPEC

# ── group 3: the route through the declaration-name list ─────────────────────

run "c6 an anonymous ClassDeclaration reaches it through the name list" <<SPEC
FILE $B
<<<OLD
        if k = KindBindingElement
            return true
        if k = KindClassDeclaration
            return true
>>>NEW
        if k = KindBindingElement
            return true
SPEC

run "c7 an anonymous FunctionDeclaration reaches it the same way" <<SPEC
FILE $B
<<<OLD
    function error_range_uses_declaration_name(k: int) returns bool
    {
        if k = KindFunctionDeclaration
            return true
>>>NEW
    function error_range_uses_declaration_name(k: int) returns bool
    {
SPEC

# ── group 4: the unreachability claim ────────────────────────────────────────

run "c8 no binder diagnostic carries one of the deferred kinds" <<SPEC
FILE $B
<<<OLD
                if (AstNode.flags_of(target as ref[AstNode]) & NodeFlagsReparsed) <> 0
>>>NEW
                if false
SPEC
