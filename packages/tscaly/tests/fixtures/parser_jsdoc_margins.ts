// The MARGIN machinery: prose separated from a tag by an empty comment line, a
// tag comment continued with a deeper indent, and a tag on a line of its own
// with leading spaces instead of an asterisk.
//
// It is the fixture for removeTrailingWhitespace, which is the one part of that
// machinery whose effect crosses the boundary the yardstick can see: it can take
// the comment part COUNT to zero, and a JSDocText node exists only when the count
// is not zero. The rest of the margin arithmetic changes a part's TEXT, which
// this port does not store — see CLAUDE.md's control table.

/**
 * prose one
 *
 * @param {number} x   text after the tag
 *      deeply indented continuation
 * @returns {string} answer
 */
function f(x) { return ""; }

/**    @type {number}    */
var v;

/**
 *
 * @param y
 *   text
 */
function g(y) { return y; }
