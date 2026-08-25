// getTypeOfSymbol's third call site: a rest parameter, whose type the reference
// tests against anyReadonlyArrayType. A parameter's symbol is a
// FunctionScopedVariable, so the dispatch takes the
// getTypeOfVariableOrParameterOrProperty arm — which is where the OTHER 4 694
// units of the old single row went, and it is the row slice 68 has to decide
// about.
function f(...rest: string[]) {}
