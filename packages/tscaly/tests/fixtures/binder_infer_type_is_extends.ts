// slice 43 — the ZERO-HOP case: the infer type IS the extends clause.
//
// getInferTypeContainer starts its walk AT the InferType node, so when the infer
// type is itself the conditional's extendsType the predicate matches before a
// single step up. A port that started one level higher — at the InferType's parent
// — would answer the same thing for `Array<infer U>` and nothing at all here, so
// this is the fixture that pins where the walk begins.
//
// ★ The second alias adds the infer type's own CONSTRAINT (`infer U extends
// string`), which makes the type parameter's node span cover the constraint too.
// The container question is unaffected by it, and that is the point of having both
// lines: same arm, two spans.
type Direct<T> = T extends infer U ? U : never;
type Constrained<T> = T extends infer U extends string ? U : never;
