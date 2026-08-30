// Slice 100: the GRAMMAR half — checkGrammarFunctionLikeDeclaration and, for a
// function expression only, checkGrammarForGenerator. Every report in this file
// comes from that pair, and the second is guarded by BOTH conjuncts: an arrow
// cannot be a generator and a grammar error already reported suppresses it.
export {}

const dupe = function (a, a) { return a }

const arrowdupe = (b, b) => b

// A required parameter after an optional one, and a parameter with both a
// question mark and an initializer.
const afteropt = function (p?: number, q: number) { return q }

const bothmarks = (r?: number = 1) => r

// A rest parameter that is not last, and one with an initializer.
const restnotlast = function (...s: number[], t: number) { return t }

// `this` in a position that is not the first parameter.
const thisnotfirst = function (u: number, this: number) { return u }

// An empty type-parameter list on a function expression.
const emptytp = function <>(v) { return v }
