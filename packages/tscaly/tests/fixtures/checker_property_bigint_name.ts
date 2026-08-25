// Slice 65. TS1539, the one report checkVariableLikeDeclaration adds BELOW the
// symbol — and the route to it is the TYPE ALIAS, which is this slice's other half.
//
// ★★★ THE CONTAINER HAD TO BE A TYPE LITERAL AND NOT AN INTERFACE, and the first
// draft of this fixture used an interface and reported nothing. §3.5's slice-62
// note says why: `checkSourceElements(node.Members())` is the LAST statement of
// checkInterfaceDeclaration, behind getDeclaredTypeOfSymbol — so an interface body
// is still unreachable, while a type literal is walked by
// `checkSourceElement(typeNode)`, which is the line slice 65 gave the alias arm.
// **The same declaration in two containers is two different reachability
// questions.**
//
// ★★ IT DOES NOT RETURN. The reference reports and carries on to getTypeOfSymbol,
// so this is a report inside the arm rather than a branch of it — which is what
// makes it visible at all: an arm that stopped here would have reported the hole
// and never spoken.
//
// ★ A NUMERIC literal name is legal and a BIGINT one is not, and the two are one
// character apart. Both are here, because a port that reported on every
// literal-named property would pass a fixture holding only the error.
export {};
type WithLiteralNames = {
    1: string;
    1n: string;
    0x10n: string;
};
