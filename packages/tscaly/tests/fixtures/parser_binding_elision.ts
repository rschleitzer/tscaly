// The ELISION, on its own so it can gate. `[, a]` has TWO elements, and the
// hole is a zero-width BindingElement with all four slots null — NOT the
// OmittedExpression an array LITERAL's hole gets. Two node kinds for the same
// text in two grammars.
var [, a] = x;
var [b, , c] = x;
var [d, ] = x;
