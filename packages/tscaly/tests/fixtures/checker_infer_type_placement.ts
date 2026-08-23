// Slice 61. checkInferType's grammar report, TS1338, and the ancestor walk that
// decides it.
//
// ★★★ THE PREDICATE IS ABOUT THE ANCESTOR'S PARENT, NOT ABOUT THE NODE'S. The
// reference's FindAncestor starts AT the infer type and asks of each step whether
// ITS parent is a conditional type whose extendsType is that step — so the
// PARENTHESIZED `(infer W)` below is legal, because the walk climbs out of the
// parenthesized type and finds the relation one level up. Reading the predicate as
// *my parent is a conditional type* would reject it, which is why the fixture
// carries the parenthesized case and not only the bare one.
// ★★ THE SECOND HALF OF THE PREDICATE IS THE IDENTITY TEST — the ancestor's parent
// must be a conditional type whose EXTENDS type is that ancestor, not merely a
// conditional type. `string extends number ? infer X : never` puts the infer in the
// TRUE branch and reports, which is what a port that only asked for a conditional
// ancestor would miss.
export {};
declare const bare: infer U;
declare const trueBranch: string extends number ? infer X : never;
declare const legal: string extends infer V ? V : never;
declare const parenthesized: string extends (infer W) ? W : never;
