// The two callers of parseIdentifierOrPatternWithDiagnostic pass DIFFERENT
// private-identifier messages, and 13c is the slice that makes the difference
// observable: a variable declaration says 18029, a parameter says 18009, and
// the default a createIdentifier reaches on its own is 18016.
var #x = 1;
function f(#y) {}
