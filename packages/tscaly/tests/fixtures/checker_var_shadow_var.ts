// SLICE 76: the one shape that REACHES the wall. A `var` with a type annotation
// and no initializer is the shortest declaration whose type this port can answer,
// so checkVariableLikeDeclaration runs its whole tail and the trailing block calls
// checkVarDeclaredNamesNotShadowed — which passes both of the reference's guards
// and its symbol test, and stops at the one call left: c.resolveName.
//
// * The tag is `resolve-name` and NOT this function's own name, deliberately: the
// wall is binder.NameResolver.Resolve, the same one checkIdentifier stands behind,
// and the row already had one member before this slice (the implicit-any parameter
// message). Naming the row after the caller would split one wall into two.
var x: string;
