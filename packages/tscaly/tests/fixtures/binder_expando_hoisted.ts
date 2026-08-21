// slice 38 — WHY THE PASS IS DEFERRED, which is the condition §3.5l says has to
// be ported exactly rather than approximated.
//
// ★★★ AND THE OBVIOUS SHAPE FOR IT GATES NOTHING, which is worth more than the
// fixture. `f.a = 1` above `function f() {}` looks like the whole argument — a
// single pass would look `f` up before its declaration and find nothing — and it
// is bound correctly WITHOUT any deferral, because
// bindEachStatementFunctionsFirst walks a statement list TWICE and binds every
// FUNCTION DECLARATION on the first walk. So the hoisting of a function is
// already handled one mechanism earlier, and the first half of this file is a
// fixture that agrees with the reference while measuring nothing (§3.5ap).
//
// What DOES discriminate is a host that is not a function declaration: a `const`
// initialized with an arrow is bound in source order, so at `g.b = 2` the name
// `g` is not in the file's locals yet. Bound where it is met, nothing is
// declared; deferred, `b` lands on the arrow's own symbol. That is the second
// half, and it is what turns the row for the deferral red.
f.a = 1;
function f() {}

g.b = 2;
const g = () => {};
