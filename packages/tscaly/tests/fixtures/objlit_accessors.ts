// Slice 99: the get/set members, which the reference DEFERS — checkNodeDeferred —
// and whose binder symbol goes into the properties table unchanged. They are the
// only arm of the member loop that adds a property without building a type for it.
//
// ★ The deferral is what makes this different from a method: an object-literal
// METHOD reports (checkFunctionExpressionOrObjectLiteralMethod), an accessor does
// not, so a literal of accessors alone builds its type and one with a method does
// not.
export {}

const accessors = {
    get g() { return 1 },
    set s(v: number) { }
}

const mixed = {
    plain: 1,
    get g() { return 2 }
}
