// Slice 58. The DEFER arm of checkGrammarImportClause — three reports, and the
// third is the reason Checker.module_kind exists.
//
// TS18058  default imports are not allowed in a deferred import
// TS18059  named imports are not allowed in a deferred import
// TS18060  deferred imports are only supported when `module` is esnext or preserve
//
// ★★★ TS18060 IS LIVE, AND THE REASON IS NOT THE ONE THE FIRST DRAFT OF THIS
// COMMENT GAVE. An unset `module` does not mean ModuleKindNone: NewChecker asks
// compilerOptions.GetEmitModuleKind(), which falls through to the TARGET when
// Module is unset, and an unset target is ScriptTargetLatestStandard = ES2025 —
// `>= ES2022` — so the derived answer is **ModuleKindES2022**. That is what
// Checker.module_kind holds and it is what the reference holds.
//
// ★★★ AND THIS FIXTURE CANNOT SEE THE DIFFERENCE, WHICH IS THE HONEST HALF. The
// test is `!= ESNext && != Preserve`, and ModuleKindNone fails it exactly as
// ES2022 does — so the naive reading of the unset option gives the RIGHT answer
// here, by accident. The derivation is therefore defended from the reference and
// not from this measurement, and the battery says so with a row that sets the
// field to None and predicts that nothing moves. The first reading that WOULD
// tell them apart is checkModuleExportName's `== ES2015 || == ES2020`, which is
// unported; the slice that ports it inherits this fixture's job.
//
// ★ What the fixture DOES gate is that the field is read at all: set it to
// ESNext and this line goes silent, which is the battery's other module_kind row.
//
// ★ The three lines are in report order and not in source order by accident —
// each arm RETURNS, so a `import defer A, { B } from "./m"` would show only the
// first. One statement per report.
import defer A from "./m";
import defer { B } from "./m";
import defer * as ns from "./m";
