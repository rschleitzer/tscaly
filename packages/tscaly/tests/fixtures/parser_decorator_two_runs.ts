// A THIRD run of decorators is not admitted: once a modifier has followed a
// trailing decorator, parseModifiersEx's hasTrailingModifier shuts the
// decorator arm off for good and the loop ends at the next `@`. The reference
// then reports Declaration_expected, so this file is permanently UNPORTED — and
// a red-producing control anyway, the parser_types_linebreak technique.
//
// Drop the hasTrailingModifier guard and this port takes the third run, finds
// `class C {}` behind it, and completes a tree the reference does not have,
// with none of its diagnostics. The runner compares that and fails.
//
// ★ The trailing modifier has to be `export`, and the first shape tried here —
// `export @d declare @d class C {}` — GATED NOTHING. `declare` is admitted as a
// modifier only when canFollowModifier says so, and `@` is not in that set, so
// the list ended at `declare` and the guard was never reached. canFollowExport-
// Modifier, by contrast, admits `@` explicitly. A control aimed through a token
// that cannot reach the site measures nothing (§3.5v, and slice 9's rule that a
// red is not self-validating, seen from the ungated side).
declare const d: any;

export @d export @d class C { }
