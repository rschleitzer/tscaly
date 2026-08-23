// Slice 56. checkGrammarBindingElement's SECOND and THIRD reports — TS1013 for a
// trailing comma after a rest element, TS2566 for a rest element that carries a
// property name — and the pair exists in one fixture because the SECOND line is
// what makes them a pair.
//
// ★★★ THE SECOND LINE COLLECTS BOTH, AND A CHAIN WOULD DROP ONE. The
// trailing-comma check sits BETWEEN two reports that return, and its own result
// is DISCARDED — upstream discards it too — so `{ ...a: b, }` reports TS2566 on
// the name and TS1013 on the comma. Reading the block as an else-chain, or
// returning the trailing-comma result, would drop the second, which is
// checkGrammarParameterList's discarded result (slice 52) in the same position.
//
// ★★ THE TWO ARRIVE IN POSITION ORDER AND NOT IN DISCOVERY ORDER. TS2566 is at
// the name and TS1013 at the comma one character later, and this port emits the
// comma FIRST — so the pair is also the smallest witness that the diagnostic list
// is sorted before it is dumped, which is the invariant diagcheck's subsequence
// test measures and nothing else in this fixture set exercises inside ONE node.
//
// ★ The last line is the negative half of both: a rest element that is last and
// unnamed, with no comma after it.
var { ...s, } = o;
var { ...a: b, } = o;
var [ ...t, ] = arr;
var { u, ...v } = o;
