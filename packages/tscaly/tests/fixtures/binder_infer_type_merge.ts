// slice 43 — the excludes, which for a type parameter permit a MERGE.
//
// ★★ `TypeParameterExcludes = Type & ^TypeParameter`, so two infers of the same
// name in one extends clause do not conflict: the second finds the standing symbol
// in the conditional's table, its flags do not meet the excludes, and it is added
// as a SECOND DECLARATION of the same symbol. One symbol, two `d` lines, one table
// entry, and NO bind diagnostic — a port that reported a duplicate identifier here
// would be wrong in a way only this shape shows.
//
// ★ Two DIFFERENT names in one clause are the control beside it: two symbols in the
// one table, which is what says the table is shared and the merge above is about
// the name rather than about the table.
//
// ★ And `Shadow<U>` puts the infer's name on the alias's OWN type parameter. Two
// tables, so two symbols and no interaction at all — the conditional's locals is
// not a scope layered onto the alias's, it is a separate table that the merge rule
// above is asked about separately.
type Twice<T> = T extends [infer A, infer A] ? A : never;
type Both<T> = T extends [infer A, infer B] ? A : B;
type Shadow<U> = U extends infer U ? U : never;
