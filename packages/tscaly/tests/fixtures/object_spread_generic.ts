// Slice 170 — getSpreadType's three remaining arms: the UNION operand on either
// side (through tryMergeUnionOfObjectTypeAndEmptyObject), the GENERIC operand with
// the intersection fork the reference's own comment names, and the
// OPTIONAL-PROPERTY merge, which fires only when the RIGHT property is optional.
let o = { a: 1, b: 'no' }
let o2 = { b: 'yes', c: true }

// the plain fold — both sides concrete, no name in both
let both = { ...o, ...o2 }

// the optional-property merge: the RIGHT property is optional, so the two are unioned
let left = { a: 1, b: 'x' }
let opt: { a?: number } = { a: 2 }
let merged = { ...left, ...opt }

// the right property is NOT optional — it wins whole
let overridden = { ...opt, ...left }

// the generic operand, and the intersection fork the reference's own comment names
function f<T, U>(t: T, u: U) {
    return { ...t, ...u, id: 'id' };
}
function g<T>(t: T) {
    return { ...t, a: 1 };
}
let inst = f({ a: 1, id: true }, { c: 1, d: 'no' })
let inst2 = g({ b: 'x' })

// the empty left, which answers the right operand unchanged
function h<T>(t: T) {
    return { ...t };
}

// the UNION operand, on either side
function u1(v: { a: number } | { b: string }) {
    return { ...v, c: 1 };
}
function u2(v: { a: number } | { b: string }) {
    return { c: 1, ...v };
}

// a union that merges into an empty object: tryMergeUnionOfObjectTypeAndEmptyObject
function u3(v: { a: number } | undefined) {
    return { ...v };
}

// a readonly index signature keeps its bit through the spread
let ro: { readonly [x: string]: number } = { q: 1 }
let spreadRo = { ...ro }
