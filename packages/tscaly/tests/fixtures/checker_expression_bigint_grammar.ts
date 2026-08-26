// checkGrammarBigIntLiteral, whole, and its report is DEAD under this harness:
// `c.languageVersion < core.ScriptTargetES2020` with languageVersion at the
// derived default ES2025 (12) against ES2020 (7). So TS2737 cannot appear here
// however the literal is written.
//
// ★ The type-position exemption is ported anyway, because it is the reference's
// own short-circuit and is independent of the target: a bigint literal in a
// literal type, or under a unary minus in one, is exempt whatever the target is.
1n;
type P = 1n;
type N = -1n;
