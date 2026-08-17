// An invalid escape is LEGAL in a tagged template — the raw text reaches the
// tag function — and the reference says nothing about these lines. It says
// nothing at SCAN time either, for any template: scanTemplateAndSetTokenValue
// is called with shouldEmitInvalidEscapeError = false from the scan loop, and
// the diagnostic comes only from a parser re-scan that knows the template is
// not tagged.
//
// So this file MATCHES, and it is what makes the exemption in
// next_token_without_check checkable: treat ContainsInvalidEscape as a scan
// fault the way a string literal's is, and every line here is reported
// unported instead.
declare function t(s: TemplateStringsArray, ...v: any[]): string;

t`\u`;
t`\x`;
t`\u{}`;
t`\01`;

// The three routes into the re-scan, one line each: a no-substitution literal
// is above, this one is the HEAD chunk and the next is the TAIL chunk. The head
// route is also what pins the `true` this port hands parse_template_expression
// from parse_tagged_template_rest — with `false` there, parse_template_head
// re-scans reporting errors and this line goes unported.
t`\u${1}b`;
t`a${1}\u`;
