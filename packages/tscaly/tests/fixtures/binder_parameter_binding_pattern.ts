// slice 40 — the binding-pattern arm of bindParameter, plainest shape. A
// destructured parameter has no name to be known by, so the binder gives it one
// built from its POSITION: `__0`, `__1`, … via bindAnonymousDeclaration.
//
// ★ The anonymous symbol goes into NO table — bindAnonymousDeclaration creates a
// symbol and adds the declaration to it, and that is all. So the parameter node's
// walk line names a symbol that no locals table holds, while the pattern's
// ELEMENTS are ordinary function-scoped variables in the function's locals.
//
// ★★ The plain parameter beside it is the other half: `c` takes the named route
// (declareSymbolAndAddToSymbolTable, ParameterExcludes) and appears in locals as
// itself. Both routes in one signature is what makes the if/else observable.
function f({ a, b }: { a: number; b: string }, c: number) {
    return a;
}

function g([x, y]: number[]) {
    return x + y;
}
