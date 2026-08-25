// The other side of isThislessInterface: a body that mentions `this` sets
// NodeFlagsContainsThis on the declaration, the predicate answers false, and the
// interface DOES get a `this` type. Nothing in this slice can print the
// difference — the row that pins it says so.
interface WithThis {
    clone(): this;
}
