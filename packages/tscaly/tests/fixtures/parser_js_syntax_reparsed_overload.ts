// Slice 24 — the OTHER half of the Reparsed guard, and the half a `@param`
// comment cannot show.
//
// `@param` writes an annotation onto a parameter that already exists, and the
// parameter was checked while it was being parsed — before withJSDoc ran — so the
// annotation is not there yet when the check happens and the guard is not what
// keeps it quiet. `@overload` is different: it SYNTHESIZES a whole
// FunctionDeclaration, body and all, and hangs it in the statement list. That node
// is function-like with no body, which is exactly what the signature arm reports —
// so the only thing keeping it silent is NodeFlagsReparsed on the node itself.
//
// The reference reports nothing here. A port that dropped the Reparsed test from
// the guard would report 8017 for a declaration the author never wrote.
// @Filename: reparsed_overload.js
/**
 * @overload
 * @param {string} a
 * @returns {void}
 */
function f(a) {}
