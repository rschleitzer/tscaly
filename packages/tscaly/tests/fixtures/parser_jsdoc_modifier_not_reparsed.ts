// DeepCloneReparseModifiers is not DeepCloneReparse: it visits a modifier list
// and does NOT stamp NodeFlagsReparsed (1<<3), because that bit goes on a clone
// ROOT and a modifier list has none. Cloning each element through the stamping
// helper gave every modifier the flag. The tree, the spans and the kinds all
// agree either way — this is one bit in one word, and only the parser yardstick
// prints it. §3.5bo.
//
// Two hosts, one helper: the `const` of a constrained @template (which only
// takes the transformed branch when a constraint is present), and the `export`
// of an @overload-synthesized signature.
// @Filename: modifiers.js
/**
 * @template {string} const T
 * @param {T} x
 */
function g(x) { return x; }

/**
 * @overload
 * @param {string} a
 * @returns {string}
 */
export function f(a) { return a; }
