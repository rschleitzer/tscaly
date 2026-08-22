// Slice 54. checkGrammarVariableDeclaration's definite-assignment term, two of
// its three codes plus the shape that is legal.
//
// ★★★ THE THREE-WAY MESSAGE CHOICE COLLAPSES TO THREE CODES AND NO ARGUMENT, so
// the dump tells them apart on the code alone (§3.5ct). Which one fires is
// decided in the reference's order: an initializer first, then a missing type
// annotation, then the catch-all — and the first line here is the NEGATIVE half
// of the whole term, the one spelling where a `!` is permitted (a variable
// STATEMENT, with a type, without an initializer, not ambient).
//
// ★★ THE SPAN IS THE `!` TOKEN AND NOT THE DECLARATION, which is the only report
// of that function pointing at something other than the declaration's name:
// grammarErrorOnNode is handed node.ExclamationToken, and error_range_for_node
// has no arm for a token kind, so the span is the token's own trivia-skipped
// start.
var a!: number;
let b!: number = 1;
let c!;
