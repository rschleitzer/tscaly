// Slice 61. The index signature — an arm that was ported in slice 52 and had no
// caller until the type literal's members walk arrived.
//
// ★★★ A REPORT THAT NOBODY REACHES IS INDISTINGUISHABLE FROM ONE THAT DOES NOT
// EXIST, and slice 52 said so at the line: *No arm of this slice can reach it (an
// index signature is a class or interface MEMBER, and neither container's members
// are walked yet), so the report stands for the whole of it.* This fixture is the
// first caller. The unit's tag is `check-grammar-index-signature`, which is the
// proof — before this slice it was `check` at TypeLiteral.
//
// ★ The index signature below is the shape the unreached check would report on
// (two parameters, TS1096), and the reference does report it; ours does not,
// because the check itself is still the report. That is the honest state and it is
// what the tag says.
export {};
declare const twoParameters: { [k: string, j: number]: number };
