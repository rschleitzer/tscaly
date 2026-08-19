// Slice 22 — the two hosts @type turns into a CAST rather than into a type
// slot: a return statement and a parenthesized expression. `isAssertion` is
// true for @type (an `as` expression) and false for @satisfies, which is the
// one place makeNewCast's flag is visible in the tree.
// @Filename: casts.js
function f() {
    /** @type {string} */
    return 1;
}

const p = /** @type {number} */ ("x");

function g() {
    /** @satisfies {string} */
    return 1;
}
