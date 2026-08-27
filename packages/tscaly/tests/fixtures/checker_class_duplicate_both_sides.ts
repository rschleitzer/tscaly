// Slice 73. A name duplicated on the static side AND on the instance side — the
// only shape that can see `instanceNames` and `staticNames` being two maps.
//
// ★★★ THE OBVIOUS NEGATIVE DOES NOT GATE THIS. A static and an instance member
// of one name (checker_class_duplicate_static_instance_ok.ts) are two SYMBOLS with
// one declaration each, so the `len(Declarations) > 1` guard stops them before the
// map choice matters; folding the two maps into one is invisible there. Here both
// sides trip, and with ONE map the instance pair writes state 3 and the static
// pair is then silenced — four diagnostics become two.
export {};
class C {
    a: number = 1;
    a: number = 2;
    static a: number = 3;
    static a: number = 4;
}
