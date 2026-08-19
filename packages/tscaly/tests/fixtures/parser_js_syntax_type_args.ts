// Slice 24 — the TYPE-ARGUMENT arm, reported at the LIST's range.
//
// ★★★ THE MEASUREMENT IS THE POINT OF THIS FIXTURE, and it is not the one the
// arm's six kinds suggest: in a JavaScript file only ONE of them can be reached.
// A `.js` file is parsed under the JSX language variant (slice 22's finding), so
// `f<number>()`, `new C<string>()`, `` tag<number>`x` `` and the two `?.<T>`
// forms all read as chains of relational operators — `(f < number) > ()` — and no
// type-argument list is built at all. What survives is
// ExpressionWithTypeArguments, which parseExpressionWithTypeArguments builds in a
// heritage clause regardless of the variant.
//
// The unreachable shapes stay in the file rather than being deleted: they are the
// NEGATIVE half. A port that read `<` as a type-argument list in a JavaScript
// file would report four extra diagnostics here, and nothing else in the corpus
// would say so.
//
// The two JSX hosts (JsxOpeningElement, JsxSelfClosingElement) are unreachable
// for the same reason one level over: `<Foo<number> />` is TSX syntax, and in a
// `.jsx` unit the inner `<` is not a type-argument list either. Measured with the
// oracle, both files, before this fixture was written.
// @Filename: type_args.js
f<number>();
new C<string>();
tag<number>`x`;
g?.<number>();
class D extends Base<string> {}
// @Filename: type_args.jsx
var a = <Foo<number> />;
