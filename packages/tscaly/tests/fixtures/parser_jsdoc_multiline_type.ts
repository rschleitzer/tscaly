// A JSDoc TYPE written across several lines of the comment. The margin `*` must
// be trivia to the type parser — that is what skip_jsdoc_leading_asterisks is
// for, and it is the only place in this port where Scan() consumes a character
// and produces no token.
//
// ★ It also gates the flag's ONE READER, which is easy to ship the flag without:
// createIdentifier takes the token's START rather than its FULL start when a
// margin asterisk was skipped in front of it, so `a` below has pos 21 and not 15.
// Without that reader the property names swallow the margin, which is a wrong
// range on a node the reference gets right — and no corpus unit has the shape.

/**
 * @type {{
 *   a: string,
 *   b: number
 * }}
 */
var v;

/** @param {Array<
 * string>} p */
function f(p) { return p; }
