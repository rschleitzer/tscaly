// An unterminated block comment is reported by the SCANNER, before the
// skip_trivia test — which is the whole point: with trivia skipped (every
// parse) the comment is discarded and nothing downstream can see it was left
// open. The diagnostic is TS1010 at the end of the text, and the parser stamps
// ThisNodeHasError (1<<15) on the token that follows it.
//
// The comment must be LAST in the file, because it swallows everything after.
var x = 1;
a.public /*CHECK#1/