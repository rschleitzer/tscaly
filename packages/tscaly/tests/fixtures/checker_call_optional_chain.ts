// isCallChain, and it needs a callee with a type for the same reason the
// literal-callee fixture does (slice 89). `(1)?.()` carries NodeFlagsOptionalChain,
// so resolveCallExpression takes the getOptionalExpressionType branch instead of
// falling through to checkNonNullType — the two exits of one `if`, and the only
// way to tell them apart is a unit that takes the other one.
(1)?.();
