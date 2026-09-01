// Slice 108. A NON-generic candidate handed type arguments.
//
// ★★★ IT IS A SEPARATE ROW FROM THE ARITY FAILURE and the reference is why: this
// shape reports TS2558 (`Expected 0 type arguments, but got 1`) while a wrong arity
// reports TS2554, so the two failures are told apart one function further down than
// this slice reaches. Folding them into one row would make the successor unable to
// tell which of its two reports it owes.
function f(a: number): void {}
f<number>(1);
