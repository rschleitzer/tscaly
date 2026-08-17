// PERMANENTLY UNPORTED, and a red-producing control anyway — the
// parser_types_linebreak technique.
//
// An ARRAY literal's element does NOT clear DisallowInContext (the reference
// passes parseArgumentOrArrayLiteralElement here and parseArgumentExpression
// there, and only the wrapper clears the flag), so inside a for initializer
// `in` is not an operator: the reference reports "',' expected" and RECOVERS
// into an array of two identifiers. This port stops at the diagnostic. Give
// the array element the argument context's clear and our side no longer stops
// — it completes a tree the reference does not have.
for ([a in b];;) ;
