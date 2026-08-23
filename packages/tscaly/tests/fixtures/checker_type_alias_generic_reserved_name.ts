// Slice 57. The other half of the pair the generic-interface fixture describes.
//
// ★★★ SAME SHAPE, DIFFERENT TAG. checkTypeAliasDeclaration asks the reserved
// name as its SECOND statement — before anything this port stops at — so this
// unit reaches checkExportsOnMergedDeclarations and carries THAT tag, while
// `interface never<T> {}` carries `check-type-parameter`. The diagnostics are
// the same on both sides in both files; the tag is the whole of the difference,
// and it is the reference's own statement ORDER made visible.
//
// ★ The type parameter is USED (`= T`) so that nothing else can speak about it.
type never<T> = T;
