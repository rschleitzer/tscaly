// Slice 22 — findMatchingParameter, whose two clauses need different inputs:
//
//   by NAME    the tag names the parameter
//   by INDEX   the tag has no name at all, and its position among the @param
//              tags of the same comment is what matches
//   by INDEX   the parameter is a binding PATTERN, so it has no name to match
//
// @Filename: match.js
/**
 * @param {string} b
 * @param {number} a
 */
function f(a, b) {}

/**
 * @param {string}
 * @param {number}
 */
function g(a, b) {}

/**
 * @param {string} first
 * @param {number} second
 */
function h({ x }, [y]) {}
