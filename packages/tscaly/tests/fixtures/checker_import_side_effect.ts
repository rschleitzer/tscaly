// Slice 58. A side-effect-only import — no clause — and the fixture exists for a
// TAG rather than for a diagnostic.
//
// ★★★ `NoUncheckedSideEffectImports` IS **TRUE** WHEN UNSET, and that is the
// second of this slice's two option surprises. The reference reads it through
// `IsTrueOrUnknown()`, and a Tristate's zero value is TSUnknown — so the branch
// behind it is taken for every `import "m"` under this harness, and the arm stops
// at resolveExternalModuleNameWorker rather than running to the end.
//
// ★★ NOTHING IN THE C SECTION SAYS SO. Both statements below are silent on our
// side and the reference answers TS2307 on each; a subsequence test is green
// either way. What separates a port that took the branch from one that skipped
// it is the unported TAG — `resolve-external-module-name` for the first line,
// `check-import-binding` for the second — and the battery's PIN is the only
// instrument that reads it. §3.5be's rule from the other side: the mechanism is
// reachable, so it is built; the thing that makes it OBSERVABLE is named here.
//
// ★ record_unported keeps the FIRST report, so the two statements need separate
// units to both be witnesses — which is why the second one is in
// checker_import_clause_only.ts and not on the next line.
import "./a";
