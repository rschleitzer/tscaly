// The negative of relation_excess_property: every property of the source IS a
// property of the target, so isKnownProperty answers yes for each and the
// excess check falls through to the structural comparison, which succeeds.
// ★ The assertion is the ABSENCE of a diagnostic and the absence of a stop.
declare let t: { a: number, b: number };
t = { a: 1, b: 2 };
