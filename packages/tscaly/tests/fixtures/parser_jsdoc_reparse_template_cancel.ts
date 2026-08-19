// Slice 22 — gatherTypeParameters' FIRST clause, which is a cancellation rather
// than a collection: when a comment carries an `@typedef` or a `@callback`, its
// `@template` tags belong to the type being DEFINED and not to the node being
// documented, so the hosted gather answers nothing at all.
//
// The two calls in the same comment are what makes it visible: the alias gets
// <T> (gatherTypeParameters(jsDoc, true)) and the function does NOT
// (gatherTypeParameters(jsDoc, false), which returns nil the moment it meets the
// typedef). One tag list, two answers.
// @Filename: cancel.js
/**
 * @template T
 * @typedef {T} Alias
 */
function f() {}

/**
 * @template U
 * @callback CB
 * @returns {U}
 */
function g() {}

// The control: no typedef, so the same @template DOES reach the function.
/**
 * @template V
 */
function h() {}
