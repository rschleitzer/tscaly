// Parser slice 16 — the unterminated regular expression, which is the whole of
// the reference's second pass: guess the extent from the nearest unbalanced
// bracket, trim trailing whitespace and semicolons, then report.
// A line break ends the body; nothing is unbalanced, so the guess runs to the
// end of the scan and the trim takes the `;` back off.
var a = /abc;
// An unbalanced closer outside a character class ends the guess before it.
var b = /ab)cd;
var c = /ab]cd;
var d = /ab}cd;
// A `{n,m}` quantifier suppresses the group arms, so this `}` does not end it.
var e = /a{2,3}b;
// Balanced groups and classes are walked through rather than stopped at.
var f = /(a)[b]c;
// A trailing run of whitespace is trimmed as well as the semicolon.
var g = /abc   ;   
