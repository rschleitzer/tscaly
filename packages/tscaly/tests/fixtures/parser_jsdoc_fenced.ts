// A fenced code block inside a JSDoc comment. Three or more consecutive
// backticks toggle it, and inside it an `@` at the start of a line is TEXT
// rather than a tag — which is the whole reason the state machine counts
// backticks at all.

/**
 * Prose before.
 * ```
 * @param this is not a tag
 * {@link neither is this}
 * ```
 * @param {number} x a real tag, after the fence closes
 */
function f(x) { return x; }

/** Inline `code` with one backtick pair, and @param after it. */
var a;
