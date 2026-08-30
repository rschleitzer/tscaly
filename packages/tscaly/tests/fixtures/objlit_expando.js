// Slice 99: the two arms that need a JAVASCRIPT file, and neither is reachable
// from a .ts fixture.
//
// ★ The EXPANDO BAIL is checkObjectLiteral's first three lines: a literal with no
// properties whose SYMBOL has exports is not an empty object — the binder has hung
// the assignments onto it — so the type is built over the symbol's export table
// and the member loop never runs.
//
// ★ ObjectFlagsJSLiteral is set on a literal in a JS file that has no contextual
// type, which is the other column this file moves.
const expando = {}
expando.a = 1
expando.b = 2

const plain = { x: 1 }
