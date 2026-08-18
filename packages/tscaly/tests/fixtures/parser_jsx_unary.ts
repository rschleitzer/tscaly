// Slice 20 — parseSimpleUnaryExpression's `<` arm, which under the JSX variant is
// an element and not a type assertion. `must_be_unary` is TRUE at that call site
// and only there, so the two-sibling recovery is suppressed: the binary
// expression it would build is not a valid UnaryExpression and would break the
// caller. The second unit is what that guard is for — with the recovery allowed it
// would wrap, and the reference leaves the `<span>` to the expression ladder.
// @Filename: unary.tsx
const a = +<div />;
const b = !<div />;
const c = typeof <div />;
const d = void <div />;
// @Filename: guard.tsx
const e = +<div></div><span></span>;
