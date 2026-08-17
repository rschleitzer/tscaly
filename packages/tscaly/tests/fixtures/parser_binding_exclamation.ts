// PERMANENTLY UNPORTED, and a red-producing control — the
// parser_types_linebreak technique.
//
// The definite-assignment `!` is admitted only when the NAME is an Identifier,
// so after a binding pattern the `!` is not an exclamation token and the
// reference reports a missing `;`. Drop the KIND guard and our side takes the
// `!`, then reads `= x` as the initializer, and completes a tree the reference
// does not have.
var [a]! = x;
