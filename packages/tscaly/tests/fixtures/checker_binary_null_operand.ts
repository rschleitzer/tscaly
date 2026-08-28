// checkNonNullType reached from the two BINARY arms that call it, with the one
// nullable type this port can answer from an expression. Both stop rather than
// report — the arithmetic and relational arms take the OBJECT-possibly-null
// reporter, not the cannot-invoke one — so this fixture's product is the row and
// not a diagnostic. It is here because the row is the claim, and a claim with no
// fixture is invisible the moment the reporter lands.
null * 1;
null < 1;
