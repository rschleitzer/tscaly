// Slice 22 — @typedef and @callback differ in ONE line of the reference and it
// is easy to miss when the two arms are merged: `checkNonIdentifierName` is
// applied to the @typedef name and NOT to the @callback name. So the first of
// these reports `Identifier expected` and the second reports nothing, over the
// same unusable name.
// @Filename: name.js
/** @typedef {string} a-b */

/** @callback c-d */
