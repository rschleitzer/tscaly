// getQuickTypeOfExpression's CALL arm and the one term in this slice that needs a
// global. isSymbolOrSymbolForCall is two syntactic tests and then `globalESSymbol
// == c.resolveName(left, "Symbol", …)`, so a call to the identifier `Symbol`
// cannot be decided here at all.
//
// * THE CONJUNCT IS NOT COSMETIC: it chooses between this arm's own stop and the
// expression dispatch's `check-call-expression`, i.e. between two rows of the work
// list. So the report sits at the term rather than in front of the arm, and this
// file is what says which of the two a `Symbol(...)` initializer lands on.
//
// * `Symbol.for` IS A SEPARATE FILE — see checker_initializer_quick_symbol_for.ts
// — because the tag is FIRST-WINS and a second line here could not be gated.
let d = Symbol("x");
