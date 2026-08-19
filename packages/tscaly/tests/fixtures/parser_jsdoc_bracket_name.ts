// Two shapes of a @param NAME that are not simply an identifier.
//
// `[x]` is the optional marker and may carry a DEFAULT, which the reference
// parses with the ordinary expression parser and then throws away — so the
// expression is not in the tree and the SPANS are the only evidence it was read.
//
// A backquoted name is not legal JSDoc at all; the reference's own comment says
// it "occurs in the wild" and parses it anyway.

/**
 * @param [a] optional
 * @param [b=42] with a default
 * @param {number} [c=1+2] typed, optional, with an expression default
 * @param `d` markdown-quoted
 * @param [e.f] a dotted name in brackets
 */
function f(a, b, c, d, e) { return a; }
