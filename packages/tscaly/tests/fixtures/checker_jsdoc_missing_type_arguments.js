// Slice 113: the JavaScript arity FALL-THROUGH. `C` has one type parameter from
// `@template` and the reference fills the missing argument with `any` after
// reporting, where a TypeScript file would stop at errorType.
/** @template T */
class C {}
/** @param {C} p */
function f(p) {}
