// Slice 98: the SECOND producer of the reference arm, and the one the reference
// documents the arm for — a type parameter whose base constraint is a class or
// interface reference. `getApparentType(T)` answers `C` re-anchored on `T`, not on
// `C`'s own `this` type, which is exactly what the thisArgument parameter is for.
//
// It is measured separately from withthis_apparent.ts because the two reach the
// same arm through DIFFERENT instantiable types — a class's `this` type and a
// declared type parameter — and a control that breaks the constraint hop moves one
// without the other.
export {}

class C {
    x: number = 1
    m(): number { return this.x }
}

interface I {
    y: number
}

function f<T extends C>(t: T): number {
    return t.x
}

function g<U extends I>(u: U): number {
    return u.y
}
