// Slice 59. `import * as ns from "m"` — the NAMESPACE arm of the import
// declaration's clause branch, and its whole point is the TAG.
//
// ★★ THREE CLAUSE SHAPES, THREE ANSWERS, and only separate units can witness
// them (record_unported keeps the first): a DEFAULT import hands the clause to
// checkImportBinding (checker_import_clause_only.ts), a NAMESPACE import hands it
// the namespace node — this file — and a NAMED list asks the module resolver
// first (checker_import_named_binding.ts). All three used to be one row,
// `check-import-binding` at 1 506 units.
//
// ★ The CommonJS branch beside this call (the ImportStar emit helper, and the
// `needsImportStar` flag that keeps it exclusive with ImportDefault) is dead
// under a ModuleKindNone format, so the arm is the one call and its stop.
import * as ns from "./a";
