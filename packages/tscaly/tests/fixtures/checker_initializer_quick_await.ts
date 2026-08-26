// getQuickTypeOfExpression's AWAIT arm, which ports its RECURSION and not
// getAwaitedType — and that is what makes the report exact: only an await whose
// operand HAS a quick type reaches the awaited type at all.
//
// * THE OTHER SIDE OF THE ARM IS ITS OWN FILE: `await 1` has a literal operand,
// so the recursion answers a type and this file stops at `get-awaited-type`, while
// `await p` has none and falls through to the dispatch's
// `check-await-expression`. Under one roof only the first of the two could ever be
// the unit's tag — see checker_initializer_quick_await_opaque.ts.
//
// * THE FUNCTION TAKES NO PARAMETER, and that is forced too: an annotation would
// have to be a KEYWORD type — slice 69 ported those arms and no other — because a
// `Promise<number>` is a TypeReference whose `get-type-from-type-node` stop is
// recorded before the body is walked and takes the first-wins slot away from the
// line under test.
async function f() {
    let a = await 1;
}
