// Slice 100: the CONTEXTUAL half — a function expression whose contextual type
// supplies a call signature. getContextualSignature reaches
// getApparentTypeOfContextualType, and the parameter types then come from
// tryGetTypeAtPosition rather than from the widening walk.
//
// ★★ EVERY ANNOTATION HERE IS WRITTEN INLINE AND NOT THROUGH A TYPE ALIAS, and
// that is a measurement rather than a style: a `type F = (x: number) => number`
// reaches get-type-from-type-alias-reference, one chapter out, and the first
// draft of this file stopped there on every group — the FNPIN read ONE row for
// eight function expressions. **A fixture written around an arm has to be
// checked against the pin that reads it, not against the arm's source.**
//
// ★ The arity rule is the point of the second group: a contextual signature with
// FEWER parameters than the function is refused by isAritySmaller, and an
// optional, defaulted or rest parameter stops the count before it gets there.
export {}

const ok: (x: number) => number = (x) => x

const fewer: (a: number) => number = (a, b) => a

const optional: (a: number) => number = (a, b?) => a

const defaulted: (a: number) => number = (a, b = 1) => a

const rest: (a: number) => number = (a, ...r) => a

// A contextual signature with MORE parameters than the function: the arity fork
// on the not-sensitive side, which is entered and does nothing.
const more: (a: number, b: number) => number = (a: number) => a

// A contextual type that is not callable at all: getSignaturesOfType answers an
// empty list, the applicable set is empty, and the answer is nil without ever
// reaching getIntersectedSignatures.
const notcallable: { a: number } = { a: 1 }

// A contextual signature reached through a PROPERTY of an annotated object type
// — the object-literal member's own contextual type, which is
// getContextualTypeForObjectLiteralElement.
const holder: { h: (x: string) => string } = { h: (x) => x }

// An object-literal METHOD under the same contextual type: the third kind, and
// the one that reaches getContextualTypeForObjectLiteralMethod.
const holdermethod: { h: (x: string) => string } = { h(x) { return x } }

// A contextual signature carrying a `this` parameter: the arm that mints a
// transient symbol through createSymbolWithType.
const withthis: (this: { k: number }, a: number) => number = function (a) { return a }

// ★★ isAritySmaller's `this` DECREMENT is about the FUNCTION's own parameter list
// and not about the contextual signature's, which is what the group above cannot
// show. Here the function writes an explicit `this` and the contextual signature
// has ONE parameter: without the decrement the required arity reads 2 and the
// signature is refused.
const thisparam: (a: number) => number = function (this: { k: number }, a) { return a }

// ★★ A contextual signature whose parameter is OPTIONAL, which is the only shape
// that reaches getTypeOfParameter's optionality disjunct and assignParameterType's
// — the two readers whose conditions are different and whose helper is the same.
const optparam: (a?: number) => number = function (a) { return 1 }

// And one whose parameter carries a DEFAULT, which is the half of that disjunct
// the other reader does not have.
const defparam: { f(a?: number): number }["f"] = function (a) { return 1 }
