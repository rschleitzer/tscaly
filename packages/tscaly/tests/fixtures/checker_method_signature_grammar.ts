// Slice 62. checkGrammarMethod's first line — checkGrammarFunctionLikeDeclaration,
// which slice 52 wrote whole and which no METHOD had ever been handed.
//
// ★★★ ITS FOUR CHECKS ARE A CHAIN AND EACH ONE RETURNS, so each declaration below
// carries exactly one diagnostic: the empty type-parameter list (TS1098, slice 51),
// a required parameter after an optional one (TS1016) and a rest parameter that is
// not last (TS1014, both slice 52), and a modifier where none may stand (TS1070,
// slice 49). Four reports of three earlier slices, reached for the first time
// through a method.
//
// ★ `check_grammar_for_use_strict_simple_parameter_list`, the fifth step, is behind
// `IsFunctionLikeDeclaration` — which a method SIGNATURE is not, having no body — so
// it is the one step of that function this arm cannot reach.
export {};
declare const a: { m<>(): void };
declare const b: { m(p?: string, q: number): void };
declare const c: { m(...r: string[], s: number): void };
declare const d: { public m(): void };
