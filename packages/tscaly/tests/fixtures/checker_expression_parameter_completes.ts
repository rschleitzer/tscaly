// A PARAMETER's variable-like declaration now runs to its last line: it has no
// initializer, it is not a property, and every step of the trailing block is
// either ported (checkExportsOnMergedDeclarations, checkCollisionsForDeclaration
// Name) or does not apply to a parameter (checkVarDeclaredNamesNotShadowed is for
// a variable or a binding element). So the unit's stop, if any, comes from
// somewhere else in the file — which is what 23 of the corpus's units did when
// this slice landed.
declare function f(a: string, b: number): void;
