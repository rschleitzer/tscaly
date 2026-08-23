// Slice 62. What the property arm actually buys, and it is a WALK rather than a
// report: a property signature's TYPE ANNOTATION was unreachable until now.
//
// ★★★ TS1016 COMES FROM FOUR ARMS DOWN AND EVERY ONE OF THEM IS OLDER THAN THIS
// SLICE — the property arm, checkVariableLikeDeclaration's
// `checkSourceElement(type_node)` (slice 55), the TypeLiteral arm and its members
// walk (slice 61), the MethodSignature arm, checkSignatureDeclaration's parameter
// list (slice 52) and finally checkGrammarParameterList's required-after-optional
// report. Removing the property arm silences the line, which is what makes this a
// gate on the walk and not on a check.
//
// ★★ THE SECOND DECLARATION IS THE SAME STATEMENT MADE WITH A TAG INSTEAD OF A
// DIAGNOSTIC: a nested index signature carries `check-grammar-index-signature`, the
// report slice 52 wrote and slice 61 first reached. The reference reports TS1096
// there and this port does not, because that check IS still the report.
export {};
declare const a: { p: { m(q?: string, r: number): void } };
declare const b: { p: { [k: string, j: number]: number } };
