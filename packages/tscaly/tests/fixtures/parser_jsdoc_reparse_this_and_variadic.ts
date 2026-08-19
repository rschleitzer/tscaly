// Slice 22 — @this and the variadic @param, in both places each of them is
// reached: hosted on a function, and inside a @callback signature.
// @Filename: tv.js
/**
 * @this {string}
 * @param {number} a
 */
function f(a) {}

// A `this` parameter is already there, so the tag adds nothing.
/** @this {string} */
function g(/** @type {string} */ this, a) {}

/**
 * @callback CB
 * @this {string}
 * @param {number} a
 * @param {...string} rest
 * @returns {void}
 */

/**
 * @param {...number} xs
 */
function h(xs) {}
