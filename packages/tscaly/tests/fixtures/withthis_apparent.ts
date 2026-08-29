// Slice 98, and the fixture the chapter opens on: the REFERENCE arm of
// getApparentType, which is the one line this slice adds and the wall slice 97
// created.
//
// The route is not the obvious one and it is worth reading before the numbers. A
// `this` expression answers the class's `this` TYPE, which carries
// TypeFlagsTypeParameter — so getApparentType takes its INSTANTIABLE hop first,
// replaces it with the base constraint (the class reference `C`), and only then is
// `t != originalType` true. That inequality is the whole guard: on a plain `C`
// receiver the hop does not run, the two are equal, and this arm never fires.
//
// What the WITHPIN reads off it: one arm-1 row per apparent type taken, with
// `arg_id` the id of the `this` type the answer is re-anchored on — a column no
// printed name can show, because a reference is named after its target and both
// sides print `C`.
export {}

class C {
    x: number = 1

    m(): number {
        return this.x
    }

    n(): number {
        return this.m()
    }
}
