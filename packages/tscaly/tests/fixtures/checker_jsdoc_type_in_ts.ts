// Slice 61. checkJSDocTypeIsInJsFile, split at the one line that needs a type.
//
// ★★★ THE TWO HALVES OF THE FUNCTION REPORT DIFFERENT THINGS AND ONLY ONE OF THEM
// IS A TYPE QUESTION. A `*` gets the plain TS8020 — *JSDoc types can only be used
// inside documentation comments* — and is complete here; a `?T` or a `T!` gets a
// message that QUOTES the type it would have meant (`Did you mean to write 'T |
// null'?`), so it needs getTypeFromTypeNode and TypeToString and stops. Both are
// in the fixture, and the second is the witness that our line set is a SUBSET
// rather than an equal set.
//
// ★ The whole function is a NO-OP in a JavaScript file, which is where these kinds
// normally live — so the reported half is exactly the case that is an error, and a
// .ts fixture is the only place it can be seen.
export {};
declare const all: *;
declare const nullable: ?string;
declare const nonNullable: string!;
