// slice 39 — MEMBERS and not exports, and the fixture is built so the two
// tables disagree: a class's STATIC member goes to the class symbol's exports and
// an instance property to its members, so `a` may name both without a collision.
// Declaring the parameter property into the wrong table makes this unit a
// duplicate-identifier report instead.
class A {
    static a: number;
    static m(): void {}
    constructor(public a: number, public m: number) {}
}
