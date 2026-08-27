// Slice 73. The accessor/property combination — the mirror of
// checker_class_duplicate_property_accessor.ts, and the arm that needs the second
// half of the reference's condition.
//
// ★★★ IT IS THE ONLY WITNESS FOR `kind != 2`. The getter records state 2; the
// field arrives with kind 1, and `state == 2 && kind != 2` is what turns that into
// a report. Drop the conjunct and this file still reports — drop the whole `state
// == 2` case and it goes silent, which is what the control battery breaks.
export {};
class C {
    get a(): number { return 1; }
    a: number = 1;
}
