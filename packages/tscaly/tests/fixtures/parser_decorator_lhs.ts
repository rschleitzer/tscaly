// A decorator's expression is a LEFT-HAND-SIDE expression — parseDecorator
// calls parseLeftHandSideExpressionOrHigher, not the assignment ladder — so
// `@a` ends at the `a` and the `+` is a grammar error the reference reports.
// Permanently UNPORTED, and a red-producing control for exactly that choice:
// parse the expression one rung higher and this port answers `@(a + b)`
// followed by a method, a complete tree with none of the reference's five
// diagnostics.
class C { @a + b m() { } }
