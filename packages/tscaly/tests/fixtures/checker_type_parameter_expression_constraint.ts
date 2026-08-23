// Slice 60. checkTypeParameter's second line — the Expression slot, TS1110 *type
// expected*, reported on the FIRST TOKEN of the expression rather than on the
// whole of it.
//
// ★★★ FINDING THE SHAPE IS MOST OF THE FIXTURE. parseTypeParameter fills
// `expression` instead of `constraint` only when what follows `extends` is
// `!isStartOfType() && isStartOfExpression()`, and almost everything that looks
// like a wrong constraint is a type start after all: `1`, `""`, `!0`, `void 0` and
// `(1)` all take the constraint slot. A MinusToken does not, unless a numeric
// literal follows it — so `-x` with `x` an identifier is the cheapest witness.
//
// ★★ AND THE FILE MUST PARSE CLEAN, because grammarErrorOnFirstToken returns
// false when the file has any parse diagnostic. That is what rules out the obvious
// candidates a second time: `<T extends 1 + 1>` reports nothing here, and the
// reason is the parse error rather than the slot.
//
// ★ The class comes FIRST and the `declare const` after it, so that the unit's tag
// is this arm's own stop rather than the variable declaration's — record_unported
// keeps the first report and a `declare const` reaches one too.
export {};
class C<T extends -x> { y?: T }
declare const x: number;
