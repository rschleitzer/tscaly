// Slice 61. Why the chapter is ONE slice: the arms compose, and a walk stopped one
// kind short of its neighbour is not a smaller slice but a broken one.
//
// ★★★ THE DIAGNOSTIC AT THE BOTTOM IS THE PIN. Reaching the dot of `Box.<number>`
// takes SIX arms in a row — ArrayType, ParenthesizedType, TypeOperator, TupleType,
// ParenthesizedType again and TypeReference — and the report is emitted only if
// every one of them recursed. Remove any single arm from the switch and this line
// goes silent, which is what makes one fixture gate the whole closure rather than
// six fixtures gating six arms.
//
// ★ Two of those six are `case … : node.ForEachChild(c.checkSourceElement)` in the
// reference, i.e. arms with no body of their own — the ones easiest to leave out
// on the grounds that they do nothing.
export {};
interface Box<T> { v: T }
declare const deep: (keyof [readonly (Box.<number>)[]])[];
