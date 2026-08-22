// Slice 52. `Parameter cannot have question mark and initializer`, and the
// REPARSED guard that stands next to it.
//
// ★★★ THE CONDITION HAS THREE TERMS AND THE THIRD CANNOT BE REACHED FROM THIS
// ARM, which is worth writing at the fixture rather than discovering as a missing
// row: `parameter.QuestionToken != nil && QuestionToken.Flags&NodeFlagsReparsed ==
// 0 && parameter.Initializer != nil`. A reparsed `?` is the bracketed name of a
// JSDoc `@param [x]` tag, so the function it belongs to carries
// NodeFlagsHasJSDoc — and check_source_element_worker reports
// `check-jsdoc-comments` and RETURNS for any node that does, one call before this
// check runs. So no unit can separate the guard from its absence here, the same
// shape as §3.5cv's `@augments` walk, and it expires with the same slice: the one
// that ports the JSDoc comment check.
//
// ★ The second function is the negative half of the FIRST term: an optional
// parameter without an initializer is ordinary and must report nothing.
function f(a?: number = 1) {}
function g(a?: number) {}
