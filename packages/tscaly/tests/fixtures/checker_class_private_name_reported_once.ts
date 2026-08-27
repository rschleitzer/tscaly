// Slice 73. TS2804 is reported ONCE however many members share the private name —
// the `flags != 3` guard, and the only shape that can see it.
//
// ★★★ IT NEEDS A FOURTH SIGHTING, NOT A THIRD. The instance `#x` writes 1, the
// first `static #x` ORs in 2 and reports on reaching 3; the SECOND `static #x`
// then finds 3 and must be skipped. Without the guard, `3 | 2` is still 3 and the
// report fires a second time — which duplicates every line of the first report,
// since reportDuplicateMemberErrors walks the whole member list each time.
//
// ★ The two static `#x` are also a kind-map duplicate, so TS2300 appears here as
// well; the diagnostic this file is about is the TS2804 count.
export {};
class C {
    #x: number = 1;
    static #x: number = 2;
    static #x: number = 3;
}
