// Slice 62. The two containers of a property signature, side by side — and this
// fixture exists to make one sentence of the slice measurable: an INTERFACE BODY IS
// NOT WALKED.
//
// ★★★ BOTH DECLARATIONS ARE THE SAME ERROR AND ONLY ONE OF THEM IS OURS. The
// reference reports TS1246 on the interface property's initializer and TS1247 on the
// type literal's; this port reports the second alone, because
// checkInterfaceDeclaration stops at checkExportsOnMergedDeclarations while
// checkTypeLiteral's members walk is its FIRST line. So the unit's C section is a
// strict SUBSEQUENCE of the reference's with a gap in the MIDDLE, which is exactly
// the relation diagcheck asserts and the reason it can be green while a whole
// container is missing.
//
// ★★★ AND THE GAP IS NOT ONE LINE OF WORK. `checkSourceElements(node.Members())` is
// the LAST statement of checkInterfaceDeclaration and everything between the stop and
// it is the interface's declared type — getDeclaredTypeOfSymbol,
// checkInheritedPropertiesAreIdentical, the base-type assignability loop,
// checkIndexConstraints, checkObjectTypeForDuplicateDeclarations. So the reachability
// of an interface BODY is behind the type system, not behind a missing recursion, and
// controls-slice62.sh's g19 lifts it as a PREMISE rather than as a fix.
//
// ★★ THE UNIT'S TAG IS `check-exports-on-merged-declarations` AT KindInterfaceDeclaration,
// i.e. the stop that causes the gap, and it is the interface arm's own report rather
// than anything this slice added. A slice that lifts it — the interface's own type
// dimension — turns this fixture's first line green without touching a line of
// checkGrammarProperty.
export {};
interface I { p: string = "x" }
declare const a: { p: string = "x" };
