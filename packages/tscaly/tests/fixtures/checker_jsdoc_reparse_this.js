// SLICE 78: the PARENT half. `@this` prepends a synthesized parameter to the
// function's parameter list, and checkParameter then asks
// `slices.Index(fn.Parameters(), node) != 0` — a search in the list reached through
// the parameter's own `parent`. Without finishMutatedNode that parent is stale, the
// search answers -1, and TS2680 is reported about a parameter that IS first.
//
// The reference reports nothing here. It is a JS file because the reparser only
// runs for one, and it is findable only through a checker arm: the tree, the spans
// and the kinds all agree either way.
/**
 * @this {string}
 * @param {number} a
 */
function f(a) {}
