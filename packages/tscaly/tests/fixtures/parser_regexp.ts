// Parser slice 16 — the regular expression literal, terminated forms.
// The scanner always answers `/` as a division sign, so every line here is a
// case of the parser asking for the re-scan at an expression position.
var a = /abc/;
var b = /abc/gimsuy;
// A `/` inside a character class does not close the literal.
var c = /[/]/;
// An escaped slash does not either, and the escape arm swallows whatever
// follows it — including a `[`.
var d = /\//;
var e = /\[/;
// NESTED character classes are deliberately not tracked: `/[[]/` is a
// terminated literal with an incomplete class, not a run to the next slash.
var f = /[[]/;
// `/=` is one token out of the scan, and the re-scan has to accept it as the
// opening of a literal rather than as an operator.
var g = /=a/;
// Expression positions other than a variable initializer.
var h = [/a/, /b/g];
var i = (/a/).source;
foo(/a/, 1);
// A division sign in the same file, so the two readings of `/` stand side by
// side: this one is never re-scanned, because it is not at the start of an
// expression.
var j = a / b / c;
