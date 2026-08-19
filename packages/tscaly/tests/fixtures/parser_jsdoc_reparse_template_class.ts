// Slice 22 — @template on the two CLASS-like hosts, which are the else-arms of
// the function-like host and are not the same node kind. The corpus reaches the
// declaration; the expression is only reachable through an initializer.
// @Filename: tpl.js
/** @template T */
class A {}

/** @template T */
const B = class {};

// A constrained first parameter and a default, which is the one branch of
// gatherTypeParameters that REBUILDS a type parameter instead of cloning it.
/**
 * @template {string} T
 * @template U
 * @param {T} a
 * @param {U} b
 */
function f(a, b) {}
