// `arguments` is a checker-minted symbol with SymbolFlagsProperty and NO value
// declaration, so getTypeOfSymbol routes it to the variable/parameter/property
// worker, where the reference asserts a value declaration is present. What makes
// that assertion true is one line of initializeChecker — the symbol's resolved
// type is seeded with getGlobalType("IArguments", 0) — which this port resolves
// lazily instead, at the one read that can reach it.
//
// The second function is the negative control the arm needs: a property access on
// the object is where a WRONG seed (an empty object rather than the lib's
// interface) stops being invisible.
function f() {
    return arguments;
}
function g() {
    return arguments.length;
}
