// Slice 56. The deferral's `ast.IsIdentifier(node.Name())` term, alone in a file
// because the term is only visible in the FIRST report a unit makes.
//
// ★★★ A RENAMING INTO A PATTERN IS NOT THE CONFUSING SHAPE THE REFERENCE FORBIDS.
// `{a: {b}}` renames property `a` into a nested destructuring, not into a plain
// name, so the deferral does not apply and the element falls through to the type
// dimension — this file's tag is `get-type-for-binding-element-parent`, where
// checker_binding_element_renamed_in_type.ts's is the function's own report.
//
// ★★ IT IS ITS OWN FILE FOR A MEASUREMENT REASON, NOT A TIDINESS ONE. A unit
// carries ONE unported tag — the first report wins — so a term whose only effect
// is to change which report comes first cannot be witnessed by a line that sits
// behind another statement's report. Three of this slice's terms need three
// files for exactly that reason, and the alternative (one file, three lines)
// would gate one of them and look like it gated all three.
declare function h3({a: {b}}): void;
