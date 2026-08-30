// Slice 99: the CONTEXTUAL TYPE, and it is the half of this chapter no other
// fixture reaches. A literal whose declaration carries an annotation has a real
// contextual type, so getContextualType answers through
// getContextualTypeForVariableLikeDeclaration and the push/pop stack has
// something to hold.
//
// ★ The nested literal here is the one that reads its PARENT's entry off the
// stack rather than recomputing it — findContextualNode's whole reason.
export {}

interface Point {
    x: number
    y: number
}

const annotated: Point = { x: 1, y: 2 }

interface Outer {
    inner: Point
    n: number
}

const nestedAnnotated: Outer = { inner: { x: 1, y: 2 }, n: 3 }

// No annotation: the same shapes with NO contextual type, so the two halves of
// every contextual row can be told apart inside one unit.
const bare = { x: 1, y: 2 }

// `as const` — isConstContext's first term, which makes every member readonly and
// keeps its literal type regular instead of widening it.
const frozen = { x: 1, y: 2 } as const
