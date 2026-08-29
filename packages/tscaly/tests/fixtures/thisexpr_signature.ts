// Slice 97: the SIGNATURE arm (arm 1) — a declared `this` parameter, which is the
// fork the container kind cannot see: these methods have the same container as
// thisexpr_class.ts's and a different arm.
export {}

interface Point { x: number }

function withThis(this: Point): number {
    return this.x
}

class C {
    x: number = 1
    // A method WITH a `this` parameter takes the signature arm where the same
    // method without one takes the class arm.
    m(this: Point): number {
        return this.x
    }
}

// isInParameterInitializerBeforeContainingFunction: a `this` in a parameter's own
// initializer refers to the class around the function, not to the function — unless
// the function declares a `this` parameter, which is the `||` in the guard.
class D {
    v: number = 1
    m(a: number = 2) {
        return a
    }
}
