// Slice 61. checkGrammarTypeOperatorNode's `unique` arm — four of its five
// reports, each at a DIFFERENT span, and each reachable from a position this
// port's walk already visits.
//
// ★★★ THE ARM IS WHOLLY SYNTACTIC AND THAT IS THE POINT. `unique symbol` is a
// claim about the DECLARATION the operator sits in — is it a variable, is that
// variable const, is its name a binding pattern — and the reference asks for a
// type nowhere in it. So the whole function is portable in a slice that owns no
// type system.
//
// ★★ THE SPANS DISAGREE THREE WAYS. TS1005 reports on the OPERAND (`string` of
// `unique string`), TS1333 on the OPERATOR NODE (`unique symbol` entire) and
// TS1332 on the declaration's NAME — so a fixture with one shape would pin the
// code and not the placement.
//
// ★★ THE PARENTHESIZED DECLARATION IS THE WalkUpParenthesizedTypes WITNESS.
// `(unique symbol)` on a const is legal, and it is legal only because the walk
// climbs OUT of the parenthesized type to find the declaration; a port that read
// the operator's immediate parent would land on the ParenthesizedType, fall to the
// default arm and report TS1335. It is the one report of this arm that a negative
// case can gate.
//
// ★ The `unique symbol` on the first line is legal and must stay silent: it is
// the negative half, and without it the arm could report unconditionally and
// still look right.
export {};
declare const legal: unique symbol;
declare const parenthesized: (unique symbol);
declare let notConst: unique symbol;
declare const [destructured]: unique symbol;
declare const wrongOperand: unique string;
declare function returnsIt(): unique symbol;
