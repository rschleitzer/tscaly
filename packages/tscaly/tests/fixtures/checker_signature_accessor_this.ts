// "If only one accessor includes a this-type annotation, the other behaves as if
// it had the same type annotation": the setter has no `this` parameter, so its
// signature borrows the getter's.
interface Ctx {
    n: number;
}
class C {
    get x(this: Ctx): number {
        return 1;
    }
    set x(v: number) {
        return;
    }
}
