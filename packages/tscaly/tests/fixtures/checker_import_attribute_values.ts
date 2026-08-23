// Slice 58. TS2858 — `Import attribute values must be string literal
// expressions`, the last block of checkExternalImportOrExportDeclaration.
//
// ★★ THE LOOP DOES NOT STOP AT THE FIRST BAD VALUE and the fixture is what makes
// that measurable: the reference accumulates a flag and reports every attribute,
// so the first statement is TWO diagnostics. A port that returned at the first
// one would still be a subsequence of the reference's list and diagcheck would
// stay green — the COUNT is the only witness, which is why both bad values are on
// one line.
//
// ★ The block is guarded by `!IsImportEqualsDeclaration(node)`, and that guard is
// the reason ast.GetImportAttributes may answer null for a kind rather than
// panicking: an `import = require(…)` has no such slot and never asks.
//
// ★ The third line is the negative half — a well-formed attribute value makes the
// function answer TRUE, so the declaration goes on to its import clause.
import a from "./a" with { type: 1, other: 2 };
export { b } from "./b" with { type: c };
import d from "./d" with { type: "json" };
