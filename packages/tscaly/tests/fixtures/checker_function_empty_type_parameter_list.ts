// Slice 52. checkGrammarTypeParameterList reached through the FUNCTION, which is
// the second caller of the check slice 51 ported and of §3.5cv's side table.
//
// ★★ THE TABLE IS INDEXED BY THE LIST, NOT BY THE OWNER, so the row for a
// function's `<>` is found by the same search as a class's — this unit is what
// proves the search does not depend on who declared the list. Slice 51's own
// fixture could not: it had one caller.
//
// ★ The second function is the negative: the check fires on a list that EXISTS and
// is EMPTY, and a one-parameter list is neither. The third is the arm's own fork —
// a generic function stops at checkTypeParameter, which is what makes
// `check-type-parameter` a row of the work list at all.
function f<>() {}
function g<T>(x: T) {}
function h<T extends string>(x: T) {}
