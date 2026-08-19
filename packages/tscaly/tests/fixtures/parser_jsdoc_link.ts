// The inline link, which is the one thing inside a JSDoc comment that is a NODE
// rather than prose: `{` hands over to parseJSDocLink, and the text before it
// becomes a JSDocText of its own. All three spellings are separate kinds.
//
// It also drives the EAGER route: for a TS file the reference defers the whole
// JSDoc parse, EXCEPT when the comment contains @see or @link — so every line
// here is parsed twice over, once by withJSDoc during the parse and once by the
// yardstick's own Node.JSDoc(file).
//
// No corpus unit contains one.

/** See {@link Alpha} for more. */
var a;

/** Prefer {@linkcode Beta.gamma} over {@linkplain Delta}. */
var b;

/** {@link Epsilon} at the very start. */
var c;

/** A brace that opens no link: { not a link } and text after it. */
var d;

/** @param {number} x see {@link Zeta} in the tag comment */
function f(x) { return x; }
