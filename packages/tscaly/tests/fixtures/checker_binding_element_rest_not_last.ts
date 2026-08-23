// Slice 56. checkGrammarBindingElement's FIRST report — TS2462, a rest element
// that is not the last element of its destructuring pattern — and the first
// diagnostic this port produces from a binding element at all.
//
// ★★★ THE TEST IS AGAINST THE LAST ELEMENT OF THE PARENT'S LIST, NOT AGAINST A
// POSITION. `node.AsNode() != core.LastOrNil(elements.Nodes)` is a POINTER
// comparison, so a port that counted indices would answer the same on every
// pattern the corpus has and differently on an empty list — where LastOrNil is
// nil, the comparison is true and the report fires. That direction is
// unreachable for a rest element (a pattern holding one is not empty), which is
// why the null half is written down at the line rather than tested here.
//
// ★★ THE THIRD LINE IS THE ONE THAT SAYS THE WALK RECURSES. The offending rest
// element sits inside a NESTED pattern, so it is reached only because
// checkVariableLikeDeclaration walks a pattern's elements and a binding element's
// own name can be a pattern again — the first arm in this file whose walk feeds
// itself.
//
// ★ The last two lines are the negative half: a rest element that IS last, in
// both pattern kinds. The reference is silent on them and so are we, which is
// what makes the three above a measurement of the test rather than of the `...`.
var { ...a, b } = o;
var [ ...c, d ] = arr;
var { x: { ...q, r } } = o;
var { e, ...f } = o;
var [ g, ...h ] = arr;
