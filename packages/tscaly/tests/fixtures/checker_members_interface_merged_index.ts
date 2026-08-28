// SLICE 85. A merged interface: the members table getMembersOfSymbol answers is
// the SYMBOL's, so the index signature of the second declaration is in it.
interface I {
    a: string;
}
interface I {
    [k: string]: string;
}
