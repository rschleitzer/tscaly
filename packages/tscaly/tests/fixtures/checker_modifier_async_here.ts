// Slice 49. The TAIL of checkGrammarModifiers, which runs after the loop and is
// the only part of the function a well-formed modifier list can still reach:
// `async` is accepted by the loop (no ambient context, not a parameter, no
// abstract), sets its flag, and is then rejected by checkGrammarAsyncModifier
// because a variable statement is none of the four kinds that may carry it.
//
// TS1042, reported at the MODIFIER through the async token the loop remembered —
// lastAsync — and not at the node.
async var a: number;
