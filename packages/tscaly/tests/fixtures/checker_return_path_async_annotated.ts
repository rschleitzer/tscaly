// SLICE 82: unwrapReturnType's ASYNC arm. An async function's declared return type
// is unwrapped through getAwaitedTypeNoAlias before the void test, so
// `async function f(): void` cannot take the early return its plain sibling does —
// the unit belongs to the awaited dimension.
//
// ★ The annotation is a KEYWORD rather than `Promise<T>` on purpose: a type
// reference stops in the type-node table first and the unwrap would never be
// reached, which would make the fixture measure the wrong thing.
async function asyncAnnotated(): void {
}
