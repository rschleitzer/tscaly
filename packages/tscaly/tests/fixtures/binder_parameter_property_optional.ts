// slice 39 — the question token. The property's flags are
// `Property | IfElse(decl.QuestionToken != nil, Optional, None)`, and the
// parameter symbol beside it never carries Optional whatever the parameter does:
// a parameter's optionality is a node, a property's is a symbol flag.
//
// ★ The three shapes that are NOT the question token are here for the same
// reason the plain parameter is in the first fixture: a default value and a rest
// parameter make a parameter optional to a CALLER without making the property
// optional.
class A {
    constructor(public a?: number, public b: number = 1, public c?: string, public ...d: number[]) {}
}
class B {
    constructor(readonly e?: number) {}
}
