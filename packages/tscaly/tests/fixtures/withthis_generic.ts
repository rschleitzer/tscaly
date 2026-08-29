// Slice 98: the CONCATENATE path with a non-empty argument list. A non-generic
// class re-anchors an EMPTY list — `[this]` — so the append and the copy are the
// same operation and a broken order is invisible. A generic class makes the answer
// `[T, this]`, where appending at the front instead of the back produces a
// well-formed reference of the same name with the arguments swapped.
//
// ★ The arity test above it is what admits this file at all: the target's own
// TypeParameters() and the reference's resolved type arguments must be the same
// length, and for the DECLARED type of a generic class they are — the `this` type
// is not in either list until this function puts it there.
export {}

class G<T> {
    v: T
    constructor(v: T) { this.v = v }
    get(): T { return this.v }
}

class Pair<A, B> {
    a: A
    b: B
    constructor(a: A, b: B) { this.a = a; this.b = b }
    first(): A { return this.a }
}
