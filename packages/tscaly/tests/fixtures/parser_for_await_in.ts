// PERMANENTLY UNPORTED, and a red-producing control.
//
// With an `await` present the `of` is REQUIRED — the reference's case
// expression is `awaitToken != nil && p.parseExpected(Of) || …`, so a missing
// `of` is a diagnostic rather than a fall-through. The reference then recovers
// into a for-IN statement with no await modifier; downgrade our parseExpected
// to a parseOptional and we build that same tree WITHOUT the diagnostic, which
// the yardstick compares.
for await (const x in y) ;
