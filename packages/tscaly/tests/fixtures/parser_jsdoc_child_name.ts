// A nested @param run ends at the first child whose name is not a member of the
// parent's — `other.b` under `opts` is a different object, so it terminates the
// run and `opts.c` after it is NOT folded into the type literal.

/**
 * @param {Object} opts
 * @param {number} opts.a
 * @param {string} other.b
 * @param {number} opts.c
 */
function f(opts) { return opts; }
