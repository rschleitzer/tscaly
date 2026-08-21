// slice 39 — the PARENT test. IsParameterPropertyDeclaration is a conjunction,
// and this is the half the modifier fixture cannot show: a parameter-property
// modifier on a parameter of anything that is not a Constructor declares NO
// property. Every one of these is a grammar error the checker reports and the
// binder does not; the parse is the same on both sides, so the unit measures the
// bind alone.
class A {
    m(public a: number): void {}
    get g(): number { return 1; }
    set s(public v: number) {}
}
function f(readonly b: number) {}
const g = function (private c: number) {};
const h = (protected d: number) => d;
declare function i(override e: number): void;
