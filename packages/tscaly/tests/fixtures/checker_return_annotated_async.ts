// An ANNOTATED async function with a `return`. checkReturnStatement unwraps the
// return type before checkReturnExpression, and an async one is unwrapped through
// getAwaitedTypeNoAlias — so the stop names the awaited dimension and not the
// relation. It is the only shape that tells the unwrap's call from its absence.
//
// The annotation is `any` and not `Promise<number>` deliberately: a TypeReference
// stops in getTypeFromTypeNode one call earlier (the globals table, 3.11), so an
// annotation this port cannot build would make the file measure that instead.
async function annotatedAsync(): any {
    return 1;
}
