// SLICE 78: the second face of the stale parent, and a different arm.
// `@template {string} const T` reparses into a type parameter carrying a `const`
// modifier, and checkGrammarModifiers asks the type parameter's PARENT whether it
// is function-like before allowing it. A stale parent answers no and TS1277 is
// invented.
/**
 * @template {string} const T
 * @param {T} x
 */
function g(x) { return x; }
