// slice 41 — THE fixture for the decision. `B` has no private member, so it
// never asks for an id and never draws one: `C` is `%FE#2@#x`, not `%FE#3@#x`.
//
// ★★★ GetSymbolId is LAZY upstream — the id is assigned on first request, by CAS
// into a field whose zero value means unassigned — and this port's per-file
// counter reproduces that only because it kept the laziness. Assign at symbol
// CREATION instead, which is the shape §3.10 argues for node ids, and every
// class after the first idless one is numbered wrong while every name still
// looks well formed. The numbers are the only place the difference shows.
class A {
    #x = 1;
}

class B {
    m() { return 1; }
}

class C {
    #x = 3;
}
