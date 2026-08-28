// SLICE 85. isValidIndexKeyType's NEGATIVE: a literal type is not a valid index
// key, so no IndexInfo is made and checkIndexConstraints returns at its first
// line. The grammar check reports TS1268 on the same declaration, which is what
// tells a reader the declaration was seen at all.
interface I {
    [k: 1]: string;
}
