// Slice 108. A SPREAD argument, which stops in getEffectiveCallArguments.
//
// ★★★ TWO MISSING THINGS MEET ON THIS LINE and the row names neither of them by
// itself: the reference turns a spread of a TUPLE type into synthetic arguments, and
// this port has no tuple writer (get_parameter_count's header) and no
// SyntheticExpression node kind. So the row is the arguments' own, above the arity
// check rather than inside it.
function f(a: number, b: number): void {}
declare const args: [number, number];
f(...args);
