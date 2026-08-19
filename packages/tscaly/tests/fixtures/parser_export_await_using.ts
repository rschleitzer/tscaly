// `await using` with MODIFIERS — the one arm of parseDeclarationWorker that was
// left out on the argument that nothing reached it. The unported escape hatch
// could not fire here, because it is guarded on a NULL modifier list and this
// path always has one: the fallthrough made a MissingDeclaration for `export`
// plus a second statement for the rest, with one diagnostic and rc 0, where the
// reference makes a single VariableStatement whose declaration list carries the
// Using|AwaitUsing flags (6). §3.5bn.
export await using x = null;
