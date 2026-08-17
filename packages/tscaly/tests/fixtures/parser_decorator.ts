// The decorator, in the places a real file puts one. The coverage fixture for
// slice 12: it is written so the FIRST shape a control can change is the plain
// class decorator, and every claim with a discriminating shape of its own has a
// file of its own beside this one (slice 10's rule — a packed fixture stops at
// the first divergence and hides every claim behind it).
declare const d: any;

@d
class A {
}

@d @d
class B {
}

@d.e.f(1)
class C {
    @d m() { }
    @d p = 1;
    @d static s = 2;
    @d get g() { return 1; }
    @d set g(v: number) { }
    @d accessor a = 3;
    @d declare q: number;
    constructor(@d public x: string, @d readonly y: number) { }
    n(@d z: string) { }
}
