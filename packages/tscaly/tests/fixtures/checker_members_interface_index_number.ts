// SLICE 85. The numeric key. isValidIndexKeyType's first disjunct is
// String|Number|ESSymbol, and this is the second of the three.
interface I {
    [k: number]: string;
}
