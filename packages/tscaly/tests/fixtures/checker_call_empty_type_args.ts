// checkGrammarTypeArguments on a CALL and on a NEW, which is checkCallExpression's
// FIRST line and was unreachable until slice 89 opened the arm. `g<>()` parses
// cleanly — an empty type-argument LIST is a grammar error, not a parse error,
// which is the whole reason the check exists — and both reports land before the
// signature is resolved, so they are this chapter's only product that does not
// wait on the callee.
declare function g(): void;
declare class C { }
g<>();
new C<>();
