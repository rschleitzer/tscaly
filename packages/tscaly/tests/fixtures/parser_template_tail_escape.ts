// The TAIL route: the invalid escape sits in the chunk that
// parse_literal_of_template_span rewinds out of the `}`. That chunk was never
// seen by next_token_without_check at all — the token it scanned there was a
// CloseBraceToken — so this line is the one that proves the test has to be on
// the re-scan and not only on the scan.
var d = `c${1}\u`;
