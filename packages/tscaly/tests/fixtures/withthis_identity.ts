// Slice 98: the arm that answers its own input. A type that is neither a reference
// nor an intersection comes back unchanged (arm 0), and the row exists for the
// reason slice 97's `any` fallback has one — it is an ANSWER the reference gives
// too, and a chapter that stopped answering it would otherwise look identical to
// one that never met it.
//
// An interface with no `this` type and no type parameters is the shape: it is an
// object type without ObjectFlagsReference, so the first test fails and the tail
// runs.
export {}

interface Plain {
    p: number
}

class NoBase {
    q: number = 1
}

function h(x: Plain): number {
    return x.p
}
