// Slice 52. checkGrammarForUseStrictSimpleParameterList — the last term of
// checkGrammarFunctionLikeDeclaration's five-term `||`, and the first check in
// this port whose gate is the LANGUAGE VERSION.
//
// ★★★ THE GATE IS LIVE BECAUSE THE OPTION IS UNSET, which is the opposite of how
// `check-decorators` reads its unset option. `c.languageVersion >=
// core.ScriptTargetES2016` and languageVersion is GetEmitScriptTarget(), which
// answers ScriptTargetLatestStandard — ES2025 — when Target is unset. So this
// whole function runs on every function declaration in the corpus, and it is the
// one place where reading "the harness sets nothing" as "the branch is dead" would
// have silently dropped a check.
//
// ★★ THE THREE NON-SIMPLE SHAPES ARE THE THREE TERMS OF THE FILTER, one function
// each: an initializer, a binding pattern NAME, and a rest parameter. A port that
// implemented one of them passes on a single-function fixture.
//
// ★ The last function is the negative half and it is what makes the report a
// statement about the parameters rather than about the directive: a simple
// parameter list with `"use strict"` is legal, so nothing may be said there.
function f(a = 1) { "use strict"; }
function g([a]: number[]) { "use strict"; }
function h(...a: number[]) { "use strict"; }
function i(a: number) { "use strict"; }
