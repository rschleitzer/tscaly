// The AWAIT arm's other side: an await whose operand has NO quick type. The
// recursion answers nothing, the arm answers nothing, and the expression falls
// through to the dispatch's `check-await-expression` — so getAwaitedType is never
// asked.
//
// * WHAT THIS FILE GATES is the operand test itself. Report unconditionally
// instead of only when the recursion answered, and this file's tag becomes its
// sibling's; the sibling alone cannot see that, because its own first line stops
// there already.
//
// * The parameter's annotation is a KEYWORD type for the reason the sibling's
// header gives: a TypeReference would record its own stop before the body is
// walked.
async function f(p: any) {
    let b = await p;
}
