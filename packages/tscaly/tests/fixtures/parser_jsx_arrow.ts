// Slice 20 — the JSX override in isParenthesizedArrowFunctionExpression. Under
// this variant a `<` followed by a name is an ELEMENT far more often than a type
// parameter list, so the tristate is DECIDED rather than left Unknown, and the
// three shapes that decide it for the arrow function are narrow.
//
//   comma     `<T,>` — the trailing comma exists in real code precisely because
//             of this rule
//   extends   `<T extends X>` — but not with `=`, `>` or `/` after `extends`, all
//             three of which are element syntax
//   equals    `<T = X>` — a default
//   const     the modifier is consumed by the lookahead before the name
//
// The last unit is the OTHER side of the same rule: `<T>(x) => x` is an ELEMENT
// here, with `(x) => x` as its text, and the reference agrees — which is why the
// answer is TSFalse and not TSUnknown.
// @Filename: arrow.tsx
const a = <T,>(x: T) => x;
const b = <T extends object>(x: T) => x;
const c = <T = string>(x: T) => x;
const d = <const T,>(x: T) => x;
const e = <const T extends object>(x: T) => x;
// @Filename: notarrow.tsx
const f = <T>(x) => x</T>;
// @Filename: extendselem.tsx
// The three tokens the `extends` branch EXCLUDES, each of which makes the `<` an
// element after all: `/`, `>` and `=`.
const g = <T extends />;
const h = <T extends>child</T>;
