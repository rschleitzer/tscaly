// SLICE 82: the two lines checkFunctionDeclaration has been missing since slice 52,
// which named them and handed them to *the slice which retires the report above*.
// checkGrammarForGenerator reports on the `*` of an overload signature — a shape
// checkGrammarMethod could never reach, because a method is not a function
// declaration.
function* generatorOverload();
function* generatorOverload() { yield 1; }
