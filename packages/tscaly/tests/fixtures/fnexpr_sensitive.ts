// Slice 100: isContextSensitive and the three walks under it. Each group below
// is one term of the predicate, and the predicate decides which of the two
// parameter-assignment arms runs — the single most load-bearing question in this
// chapter.
export {}

// hasContextSensitiveParameters, first term: a parameter with no annotation.
const untyped: (x: number) => number = (x) => x

// hasContextSensitiveParameters, the `this` term: a FUNCTION EXPRESSION whose
// body mentions `this` has an implicit `this` parameter and is sensitive; the
// same body in an ARROW is not, because an arrow has no `this` of its own.
const fnthis: (a: number) => number = function (a: number) { return this ? a : a }

const arrowthis: (a: number) => number = (a: number) => a

// Type parameters make a function NOT context sensitive, whatever its
// parameters look like.
const generic = function <T>(t) { return t }

// hasContextSensitiveReturnExpression: the return walk, which descends through
// statements that can CONTAIN a return and stops at a nested function's boundary.
const retwalk: () => (x: number) => number = function () {
    if (1) { for (;;) { try { return (x) => x } catch (e) {} } }
    return (y) => y
}

// A return whose expression is an object literal holding a sensitive member —
// isContextSensitive recurses through the literal's properties.
const retobj = function () { return { k: (x) => x } }

// The binary arm: only `||` and `??` propagate, so the first is sensitive and
// the second is not. ★The two operands must be the SAME on both sides or the
// row measures the operand rather than the operator: `1 + 1` answers false
// whether or not the arm reads the token, which is what made the first draft of
// this group ungate its own control.
const bar = function () { return 1 || ((x) => x) }
const plus = function () { return 1 + ((x) => x) }
const nullish = function () { return 1 ?? ((x) => x) }

// The conditional arm, both branches.
const cond = function () { return 1 ? (x) => x : 2 }

// hasContextSensitiveYieldExpression: a generator whose yield operand is
// sensitive. The walk does NOT descend into a nested function, which is what the
// second generator shows — and the nested function must itself CONTAIN a
// sensitive yield, or the skip has nothing to skip and the control that removes
// it moves nothing.
const gen = function* () { yield (x) => x }
const genskip = function* () { const f = function* () { yield (y) => y }; yield 1 }

// The return walk's arm list, from the other side: the outer function's OWN
// returns are not sensitive, and a nested function's is. With the reference's arm
// list the walk stops at the nested function's boundary and answers false; with
// the list opened it descends and answers true.
const retskip = function () { const g = function () { return (x) => x }; return 1 }
