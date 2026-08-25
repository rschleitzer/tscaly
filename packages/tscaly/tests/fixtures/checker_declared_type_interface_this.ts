// The other side of isThislessInterface: a body that mentions `this` sets
// NodeFlagsContainsThis on the declaration, the predicate answers false, and the
// interface DOES get a `this` type. Nothing in this slice can print the
// difference — the row that pins it says so.
//
// ★★★ SLICE 67 HAD TO MAKE THAT COMMENT TRUE. It was written by slice 66 as a
// description of the reference and read as a description of the port, and the
// port did not do it: NodeFlagsContainsThis had no WRITER here at all, so the
// predicate answered thisless and this interface was denied its `this` type. The
// two fixtures agreeing was taken as evidence that the difference could not be
// printed, when it was also evidence that there was no difference to print. See
// checker_base_types_interface_this_extends.ts, which is the tag that shows it.
interface WithThis {
    clone(): this;
}
