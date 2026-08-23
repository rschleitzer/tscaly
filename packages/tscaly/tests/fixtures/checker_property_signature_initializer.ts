// Slice 62. The initializer a property SIGNATURE may not have — checkGrammarProperty's
// type-literal branch, and the only one of its three container arms this port can
// reach.
//
// ★★★ THE CONTAINER DECIDES THE MESSAGE AND ONLY THE TYPE LITERAL IS REACHABLE.
// checkGrammarProperty is a three-way branch on `node.Parent`: a class body (nothing
// walks one), an interface body (checkInterfaceDeclaration stops at
// checkExportsOnMergedDeclarations, and its members walk is the arm's LAST statement,
// with the whole declared-type machinery in between) and a type literal, whose
// members walk is checkTypeLiteral's FIRST line. So TS1247 is reported here and its
// interface twin TS1246 is not — checker_member_container_reach.ts is the fixture
// that shows the pair side by side.
//
// ★★★ THE AMBIENT BRANCH BELOW THE THREE IS THEREFORE UNREACHABLE FROM A SIGNATURE,
// AND THIS UNIT IS WHAT PROVES IT — from the far side. The type-literal arm RETURNS
// the moment the initializer is there, so checkAmbientInitializer is only ever
// entered for a property with NO initializer, where it returns at its own first line.
// controls-slice62.sh's g06 removes the report and therefore the RETURN, and this
// unit then answers **TS1039** — *initializers are not allowed in ambient contexts* —
// at the same span where the reference has TS1247. So the row that was written to be
// "ungated with a number" is diagcheck RED, and what it measures is the `return`
// rather than the report: g17 removes the ambient call and moves nothing, which is
// the same fact from the near side.
//
// ★ The report is on the INITIALIZER, not on the property.
export {};
declare const a: { p: string = "x" };
