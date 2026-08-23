// Slice 62. checkGrammarModifiers reached through a property SIGNATURE for the first
// time — the first of the three calls checkPropertyDeclaration's grammar `&&` makes.
//
// ★★★ THE SHORT CIRCUIT IS LOAD-BEARING AND THE SECOND DECLARATION IS ITS WITNESS.
// `if !checkGrammarModifiers(node) && !checkGrammarProperty(node) {
// checkGrammarComputedPropertyName(node.Name()) }` — so a modifier report suppresses
// the property check, which suppresses the computed-name check. `private q: number =
// 1` is wrong twice over and collects ONE diagnostic (TS1070, the modifier), not the
// initializer's TS1247 as well; reading the chain as three independent checks would
// invent a line the reference does not have, which is the one thing diagcheck fails
// on.
export {};
declare const a: { public p: string };
declare const b: { private q: number = 1 };
