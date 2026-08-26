// ★★★ THE ONE SHAPE THAT REACHES THE SLICE'S STOP, and it took a measurement to
// find: hasOverloads must be true (a body-less declaration) AND bodyDeclaration
// non-nil (an implementation), so the reference goes on to getSignaturesOfSymbol
// and compares the implementation signature with each overload for assignability
// (TS2394) — the signature dimension, which the tag names.
//
// ★★★ AND THE OVERLOADS MUST TAKE NO PARAMETERS. checkSignatureDeclaration runs
// BEFORE the symbol check and walks the parameters, and a parameter symbol is
// getTypeOfSymbol's variable-or-property arm — so every overload set with a
// parameter reports `get-type-of-variable-or-parameter-or-property` first and
// this stop is never the tag. That is why the row was EMPTY on the whole corpus
// before this fixture existed, and it is a measurement of the corpus rather than
// of the slice.
function s(): void;
function s(): void { }
