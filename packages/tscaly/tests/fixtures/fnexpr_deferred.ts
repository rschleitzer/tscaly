// Slice 100: the DEFERRED half — the body walk. Before this slice no arm of this
// port had ever entered the body of a function expression or an arrow function,
// and the walk is behind checkDeferredNodes, which slice 60 recorded as
// unreachable on any unit that had already stopped.
//
// ★★ Every report below is emitted by a STATEMENT arm that has existed for
// slices, from a position nothing could reach. That is the shape of this file:
// it tests the DRAIN, not the arms.
export {}

const witharrow = () => { with (1) {} }

const withfn = function () { with (1) {} }

const withmethod = { m() { with (1) {} } }

// A nested function expression inside another one: the inner is deferred while
// the outer's deferred half is running, which is what makes the drain a LOOP
// over a list that grows rather than a walk over a snapshot.
const nested = () => { const inner = () => { with (1) {} }; return inner }

// An expression-bodied arrow: the deferred half's second arm, checkExpression on
// the body rather than checkSourceElement.
const exprbody = () => (1, 2)

// A block body with a `let` redeclaration, which is a binder diagnostic, and a
// `delete` of an identifier, which is a checker one.
const inbody = () => { const q = 1; delete q }
