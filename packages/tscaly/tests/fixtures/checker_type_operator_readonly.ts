// Slice 61. checkGrammarTypeOperatorNode's `readonly` arm — TS1354, and the two
// operand kinds that are legal.
//
// ★★ THE TEST IS ON THE OPERAND'S KIND AND NOTHING ELSE: an ArrayType or a
// TupleType passes, everything else reports. A PARENTHESIZED array does NOT pass
// — the reference tests the immediate operand and does not walk through
// parentheses here, which is the opposite of what the `unique` arm does one
// branch above with WalkUpParenthesizedTypes, and is why the third declaration
// below is in the fixture.
//
// ★ The report is grammarErrorOnFirstToken, so its span is the `readonly`
// keyword and not the whole operator node.
export {};
declare const legalArray: readonly string[];
declare const legalTuple: readonly [string, number];
declare const parenthesized: readonly (string[]);
declare const plain: readonly string;
