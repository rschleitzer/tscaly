// SLICE 82: unwrapReturnType's GENERATOR arm, and the reason the generator test is
// asked before the async one — an async generator is both, and the reference
// resolves the overlap that way.
function* generatorAnnotated(): void {
}
