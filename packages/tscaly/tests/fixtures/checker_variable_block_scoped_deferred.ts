// Slice 53. checkGrammarForDisallowedBlockScopedVariableStatement and
// containerAllowsBlockScopedVariable are PORTED AND COMPLETE, and every one of the
// nine lines below is a DEFERRED witness: the reference answers TS1156 on eight of
// them, and our side reports nothing, because reaching a variable statement whose
// parent is one of those seven kinds needs the parent's own check arm — and this
// slice ports none of them. On this unit our side stops at `check IfStatement`, the
// first statement's own arm.
//
// ★★★ THE FUNCTION IS NOT UNEXECUTED CODE, AND THE DIFFERENCE COST A CONTROL TO
// FIND. It runs on EVERY variable statement in the corpus — it is the last term of
// a chain slice 53 completes — and what no corpus reaches is its REPORT, which
// `containerAllowsBlockScopedVariable` suppresses by answering true for the only
// three parents in reach. `controls-slice53.sh`'s f10 was written expecting no
// change and came back RED 345; f11 then gated the arm list itself. So what this
// fixture is deferred FOR is narrower than it looks: the four keyword arms of the
// TS1156 switch, the `with` container, and the LabeledStatement RECURSION — which
// is the one mechanism of this slice that NO control can redden, because reddening
// it would need a refusing kind to walk up to and there is none.
//
// ★★ THE LAST LINE IS THE NEGATIVE HALF and it is what makes the mask test a test:
// `var` is not block-scoped, so `blockScopeKind` is 0 and the report is skipped
// even though the container refuses one.
if (a) let x = 1;
while (a) const y = 2;
for (;;) let z = 3;
with (a) let w = 4;
if (a) lbl: let v = 5;
do let u = 6; while (a);
for (const k in a) let t = 7;
for (const k of a) let s = 8;
if (a) var ok = 9;
