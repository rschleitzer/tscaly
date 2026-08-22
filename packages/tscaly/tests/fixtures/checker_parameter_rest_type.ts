// Slice 55. THE ONE HOLE checkParameter LEAVES, and a witness for a report that
// is CORRECT AND CANNOT BE OBSERVED — which is why it needed writing down rather
// than leaving to the histogram.
//
// The last term is `!c.isTypeAssignableTo(c.getReducedType(c.getTypeOfSymbol(
// node.Symbol())), c.anyReadonlyArrayType)`: a rest parameter whose type is not
// an array. The two kind tests in front of it are free and are ported, so the
// port reports `get-type-of-symbol` exactly where the reference would compute one.
//
// ★★★ THE TAG IS SHADOWED BY ITS OWN FUNCTION, AND THAT IS NOT A DEFECT. Two
// lines earlier checkParameter calls checkVariableLikeDeclaration, which for any
// parameter whose name is an identifier ends in `get-symbol-of-declaration` — and
// record_unported keeps the FIRST report. A rest parameter's name IS an
// identifier (the port's own second term says so: a pattern rest parameter takes
// the other branch), so `get-type-of-symbol` can never be the tag while
// getSymbolOfDeclaration is unported. Measured over both corpora: **0 units**
// carry it. It is emitted anyway because not emitting it would claim the term is
// ported, and the day getSymbolOfDeclaration lands it is the tag on this file.
//
// ★ The second line is the term's negative half — a rest parameter that IS an
// array type — and the reference is silent on it, so the two lines together say
// that our report follows the KIND tests and not the `...`.
function bad(...r: number) {}
function ok(...s: number[]) {}
