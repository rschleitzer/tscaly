// Slice 58. The other half of checker_import_side_effect.ts: an import WITH a
// clause, whose arm stops at checkImportBinding instead.
//
// ★ Slice 59 ported checkImportBinding, so the tag this fixture witnesses is now
// `check-alias-symbol` — one call further on, and still the DEFAULT-import shape
// of the three the clause branch has (the other two are
// checker_import_namespace_binding.ts and checker_import_named_binding.ts).
//
// ★ Two one-statement fixtures rather than one two-statement fixture, because
// record_unported keeps the FIRST report and the second statement's tag would
// never be seen (slice 56's *a fixture that cannot be first is not a witness*).
import a from "./a";
