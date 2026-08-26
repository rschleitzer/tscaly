// TS7006 — the largest report family this slice adds, and the fixture is an
// AMBIENT function so that the body walk slice 68 opened does not stop the unit
// before the parameter is reached.
//
// ★ The parameter arm of getTypeForVariableLikeDeclaration falls THROUGH here: a
// set accessor's paired getter, a JSDoc full signature, a contextual `this` and a
// contextual parameter type all answer nothing, each at a syntactic test.
declare function g(p): void;
