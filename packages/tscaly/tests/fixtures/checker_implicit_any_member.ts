// TS7008, and it is a TYPE LITERAL rather than an interface on purpose: an
// interface declaration stops at checkIndexConstraints, one call before its own
// members walk (slice 62's finding), so a `interface I { x; }` never reaches the
// member at all. A ported arm is not a reached arm.
type T = { x; };
