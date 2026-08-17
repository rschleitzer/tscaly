// PERMANENTLY UNPORTED. A private identifier is admitted by
// isBindingIdentifierOrPrivateIdentifierOrPattern in order to be REFUSED one
// level down — the reference emits "private identifiers are not allowed in
// variable declarations" — so it stays a diagnostic and the message that
// parseIdentifierOrPatternWithDiagnostic threads through is a mechanism this
// port deliberately does not carry (§3.5q).
var [#a] = x;
