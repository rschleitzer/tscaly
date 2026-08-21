// slice 39 — the ambient and the OVERLOAD, which are the two shapes where a
// parameter property has no constructor BODY.
//
// A: an ambient class. NodeFlagsAmbient suppresses the strict-mode eval/arguments
// check above the arm and nothing else, so the property is declared as usual.
//
// B: an overload plus its implementation. Two Constructor nodes, each declaring
// `b` into the SAME class members table — one symbol with two declarations, which
// is the merge the excludes admit.
declare class A {
    constructor(public a: number);
}
class B {
    constructor(public b: number);
    constructor(public b: number) {}
}
