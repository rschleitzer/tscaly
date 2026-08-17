// Unterminated is NOT under shouldEmitInvalidEscapeError:
// scanTemplateAndSetTokenValue reports Unterminated_template_literal on every
// call, INCLUDING the very call that suppresses the escape errors. Two flags,
// one function, opposite answers — the other half of §3.5z.
//
// ★ This file MATCHES since slice 13b, where it used to be permanently unported:
// the scanner reports the diagnostic now instead of the parser standing in for it
// with an `unported`. What gates the claim is unchanged in force and different in
// shape — put the report under `report_errors` and the scan-loop route loses it.
// Its sibling `templates.ts` is the case that goes red there; this one keeps the
// diagnostic through the re-scan, and that difference IS the discrimination.
var a = `c${1}d
