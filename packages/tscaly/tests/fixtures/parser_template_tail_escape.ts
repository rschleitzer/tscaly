// The TAIL route: the invalid escape sits in the chunk that
// parse_literal_of_template_span rewinds out of the `}`. That chunk is never
// scanned by the scan loop at all — the token there was a CloseBraceToken — so
// this line is the one that proves the report has to live on the RE-SCAN and not
// only on the scan.
var d = `c${1}\u`;
