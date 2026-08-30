// Slice 100: the ordinary shape of all three kinds this chapter serves — a
// function expression, an arrow function and an object-literal method — each
// with untyped parameters, which is what makes them CONTEXT SENSITIVE and sends
// them down assignNonContextualParameterTypes. That arm is not a no-op: with no
// contextual type it forces every parameter through
// getWidenedTypeForVariableLikeDeclaration WITH reportErrors, which is where
// TS7006 comes from.
//
// ★ This file is what the FNPIN's six columns are read on: three kinds, three
// type identities, one arm.
export {}

const arrow = (x) => x

const fnexpr = function (y) { return y }

const named = function inner(z) { return z }

const method = { m(w) { return w } }

// Annotated parameters: NOT context sensitive by the parameter test, but a
// function expression with no explicit `this` parameter still is when its body
// mentions `this` — see fnexpr_sensitive.ts. An arrow is exempt from that half.
const typed = (a: number, b: string) => a

const typedfn = function (a: number): number { return a }

// Zero parameters, and an arrow whose body is an EXPRESSION rather than a block:
// the deferred half's second arm.
const nullary = () => 1

// Default and optional parameters: the two shapes isAritySmaller stops counting
// at, and the two addOptionality asks about from opposite sides.
const withdefault = (p = 1) => p

const withrest = (...rest) => rest
