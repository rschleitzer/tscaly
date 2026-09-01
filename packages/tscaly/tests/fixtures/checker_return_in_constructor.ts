// A constructor's `return x` is the assignability arm of checkReturnStatement —
// TS2409 when the expression's type does not fit the instance type. Slice 112 gives
// that arm a body and the wall moves one call in: the RELATION now stops at
// `common-property-check`, so TS2409 still has no reachable input. The bare `return`
// in the second class takes no arm at all.
class C {
    constructor() {
        return this;
    }
}
class D {
    constructor() {
        return;
    }
}