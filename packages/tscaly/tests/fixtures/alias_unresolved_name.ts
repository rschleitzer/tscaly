// Slice 114: getUnresolvedSymbolForEntityName. A type reference nothing
// resolves still has a NAME — the synthetic symbol carries the identifier's text
// and its parent chain, an errorType hangs off it, and the printer answers
// `Widget` where an unrepresented miss answers `any`.
//
// ★ The DOTTED form is the point of the parent chain: `A.T` and `B.T` are two
// symbols keyed on the path, so they may not collapse into one.
let w: Widget;
let q: A.T;
let r: B.T;
let s: A.T;
