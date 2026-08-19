// Slice 22 — `@typedef {Object[]}` plus @property, which is the ONLY input that
// reaches reparseJSDocTypeLiteral's isArrayType branch: the type literal is
// finished, wrapped in an ArrayType, and finished again at the same range.
// @Filename: arr.js
/**
 * @typedef {Object[]} Rows
 * @property {string} name
 * @property {number} [count]
 */

/**
 * @typedef {Object} Row
 * @property {string} name
 */
