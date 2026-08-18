// Slice 20 — the recovery at the END of
// parseJsxElementOrSelfClosingElementOrFragment, and it is the strangest thing in
// this grammar: two sibling elements in an expression context are parsed as a
// BINARY expression whose operator is a zero-width synthetic comma, purely so the
// formatter does less damage and the message can be
// JSX_expressions_must_have_one_parent_element (2657).
//
// The report's own span starts at the FIRST element (trivia skipped) and ends at
// the second, so it covers both — `top_invalid_node_position` is how that start
// survives the recursion when there are three.
// @Filename: two.tsx
const a = <div></div><span></span>;
// @Filename: three.tsx
const b = <a /><b /><c />;
