// The three JSDoc PREFIX type forms, each of which needs a scanner re-scan the
// ordinary grammar has no use for. `*=` and `??` are ONE token to Scan() and TWO
// here, so without ReScanAsteriskEqualsToken and ReScanQuestionToken the first
// and the third lines below parse as something else entirely.
//
// No corpus unit contains any of them: KindJSDocAllType appears 0 times in the
// reference's own JSDoc parse of all 804 units.

/** @type {*} */
var a;

/** @type {*=} */
var b;

/** @param {?} p @param {??number} q */
function f(p, q) { return p; }

/** @param {!string} r */
function g(r) { return r; }
