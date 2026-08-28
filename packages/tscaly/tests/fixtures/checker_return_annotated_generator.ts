// The generator half of the same test: getIterationTypeOfGeneratorFunctionReturnType
// rather than getAwaitedTypeNoAlias. The reference asks the generator question FIRST
// because an async generator is both, and this file is what holds that order to a
// stop tag. The annotation is `any` for the reason its async sibling gives.
function* annotatedGenerator(): any {
    return 1;
}
