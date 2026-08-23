// Slice 58. checkGrammarImportClause — the one grammar check of this family
// slice 50 could not reach, because it sits BEHIND
// checkExternalImportOrExportDeclaration in checkImportDeclaration.
//
// TS1363  a type-only import may specify a default OR named bindings, not both
// TS2206  the `type` modifier on a named import under `import type`
//
// ★★ THE SECOND ONE IS check_grammar_type_only_named_imports_or_exports SEEN FROM
// ITS OTHER SIDE. The function has been ported since slice 50 and until now only
// its EXPORT caller was reachable — the note in its header said so and named this
// slice as the one that would light the import half. Its two messages differ by a
// single word, so a port that took the specifier's kind test the wrong way round
// answers TS2207 here and stays a subsequence of nothing.
//
// ★ The first clause reports and RETURNS, so the second test is not reached on
// that line; they need separate statements to both be visible.
import type A, { B } from "./m";
import type { type C } from "./m";
import type { D } from "./m";
