// Slice 24 — the GUARD, from the side that must stay silent. In a JavaScript
// file JSDoc IS the type syntax, so everything the reparser synthesizes carries
// NodeFlagsReparsed and checkJSSyntax must ignore it: the annotation it writes
// on the parameter, the type-parameter list `@template` builds, the `?` a
// bracketed `@param` makes optional and the modifier `@public` adds.
//
// A port that dropped the Reparsed test would report every one of these, and a
// port that dropped the JS-ness test would report nothing anywhere — which is
// why the two halves need a fixture each rather than one between them.
// @Filename: reparsed_quiet.js
/**
 * @template T
 * @param {string} a
 * @param {number} [b]
 * @returns {void}
 */
function f(a, b) {}

class C {
    /** @public */
    /** @type {number} */
    p;
}
