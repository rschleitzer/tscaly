// A constructor's `return x` is the assignability arm of checkReturnStatement —
// TS2409 when the expression's type does not fit the instance type. The stop
// names checkTypeAssignableToAndOptionallyElaborate; the bare `return` in the
// second class takes no arm at all.
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
