// Slice 49. The `must precede` family, which is sixteen of the reports in
// checkGrammarModifiers and one diagnostic CODE — TS1029 — for all of them.
//
// ★ It is also what pins the ARGUMENT decision. Upstream fills `{0}` and `{1}`
// from visibilityToString and scanner.TokenToString; this port computes neither,
// because the dump is `C pos end code` and a code does not depend on its
// arguments. Every line here would be a different SENTENCE upstream and is the
// same three numbers in the artifact.
//
// The span is the MODIFIER, through GetErrorRangeForNode — not the statement and
// not its first token.
declare export var a: number;
declare export interface I { x: number; }
declare export enum E { A }
declare export type T = number;
