// Slice 61. checkGrammarMappedType — TS7061, on a mapped type's recovery slot.
//
// ★★ THE MEMBER LIST OF A MAPPED TYPE IS THE PARSER'S RECOVERY SLOT and any entry
// in it is an error, so the check is one report on the FIRST member however many
// there are. That is why the second declaration carries two: one report, on `z`.
//
// ★★★ IT IS ALSO THE FIXTURE FOR THE ARM SLICE 60 WROTE INERT. checkMappedType's
// first recursion is `checkSourceElement(mappedTypeNode.TypeParameter)`, which is
// the first caller in this port to hand a TYPE PARAMETER to checkSourceElement —
// slice 60 named exactly this caller when it wrote the arm down unreachable.
//
// ★ Neither constraint is a UNION, and that is deliberate: a `"x" | "y"` in the
// first declaration would record the union's own stop before the type parameter's
// and the unit's tag would say nothing about the arm this fixture is here for.
export {};
declare const ok: { [K in "x"]: number };
declare const withMembers: { [K in "y"]: number; z: string; w: boolean };
