// Slice 55. checkVariableLikeDeclaration's TS2371 — an initializer on a parameter
// of a function that has no body — and the first of slice 54's three commented
// branches to become live code.
//
// ★★★ THE SECOND FUNCTION IS THE ONE THIS FIXTURE EXISTS FOR, AND IT BREAKS A
// TRANSCRIPTION THAT WAS CORRECT WHEN IT WAS WRITTEN. The reference asks
// `IsBindingPattern(name)` TWICE — once to walk the elements, once to validate
// the pattern — and slice 54 merged the two blocks because the statement between
// them was dead for a variable declaration. It is not dead for a parameter: with
// the blocks merged, `f`'s pattern parameter takes the validation branch and
// RETURNS before TS2371, so the diagnostic disappears. An identifier parameter
// (`i`) cannot show it, because it never enters either block.
//
// ★★ THE THIRD FUNCTION IS THE NEGATIVE HALF, and it is `NodeIsMissing` rather
// than a null test that decides it: a function WITH a body may give any parameter
// an initializer, which is the ordinary default-argument spelling and by far the
// commonest parameter shape in the corpus. A port that read the test as
// `fn.Body() == nil` would agree with the reference here and disagree on a
// function whose body failed to parse.
declare function i(a = 1): void;
function f({a}: any = {}): void;
function f(x?: any): void {}
function withBody(b = 2) {}
