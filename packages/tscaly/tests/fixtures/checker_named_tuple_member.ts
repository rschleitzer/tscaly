// Slice 61. checkNamedTupleMember's three grammar reports, and the two SPANS they
// use.
//
// ★★ THE FIRST REPORTS ON THE MEMBER AND THE OTHER TWO ON ITS TYPE. A member that
// is both optional and rest is a fact about its own two tokens, so TS5085 spans
// `...rest?: string[]` entire; a member whose TYPE carries the marker that belongs
// on the name is a fact about the type, so TS5086 and TS5087 span `string?` and
// `...string[]` alone. A fixture reporting all three at the member would pin the
// codes and lose the placement.
//
// ★ All three are grammar errors, so the file has to PARSE CLEAN — which these
// three shapes do: each is a well-formed named tuple member that the grammar
// rejects afterwards.
export {};
declare const bothOptionalAndRest: [...rest?: string[]];
declare const optionalOnTheType: [x: string?];
declare const restOnTheType: [y: ...string[]];
