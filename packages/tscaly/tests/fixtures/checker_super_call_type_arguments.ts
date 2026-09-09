// resolveCall's outer guard is FOUR disjuncts and this port carried one, on the
// premise that a super call never reaches resolveCall. Slice 152 opened that
// route; without `!isSuperCall(node)` the call's own `<T>` is read and checked
// for arity against the base constructor's zero type parameters, and the port
// invented a TS2558 the reference does not report. D is the case; E is the
// negative control — the same `<T>` on an ORDINARY call, where the arity report
// is the reference's own answer and must survive.
class C {
}

class D<T> extends C {
    constructor() {
        super<T>();
    }
}

function plain() {
}

class E<T> {
    m() {
        plain<T>();
    }
}
