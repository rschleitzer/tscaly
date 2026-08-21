// slice 42 — isReplaceableByMethod, SECOND arm: the constructor property arrived
// FIRST, carries the mark, and now a real method conflicts with it. The property
// loses again — but the other way round: a FRESH symbol replaces it in the table
// and the marked one is simply dropped.
//
// ★★★ THE DUMP SHOWS AN ORPHAN, which is the whole point. Two symbols are named
// `m`: the marked property, with its declaration, in NO table at all; and the
// method, which is what the members table holds. No duplicate-identifier
// diagnostic either — a port that fell through to the ordinary conflict path
// would produce one, and a port that merged them would show one symbol with two
// declarations.
//
// ★ The mark itself is visible in the flags of the orphan (ReplaceableByMethod is
// set on the symbol at creation, not carried in the call), so this fixture pins
// the write as well as the two arms that read it.
// @Filename: thisrepl2.js
class C {
    constructor() {
        this.m = 1;
    }
    m() {
        return 1;
    }
}
