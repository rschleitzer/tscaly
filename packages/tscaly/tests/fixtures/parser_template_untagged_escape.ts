// An UNTAGGED template with an invalid escape is a grammar error the reference
// reports, and since slice 13b this port reports it too — so the file MATCHES
// rather than being permanently unported, and the whole diagnostic is compared
// (code and span) instead of merely provoking a bail-out.
//
// The claim: shouldEmitInvalidEscapeError is `!isTaggedTemplate` at the re-scan
// and FALSE in the scan loop. Flip either and this goes red — the re-scan control
// takes the diagnostic away, the scan-loop control hands one to the TAGGED
// fixtures that must not have it. §3.5z is the account of how the asymmetry was
// found; the port of it is now the parameter rather than a flag test beside it.
//
// This is the NoSubstitutionTemplateLiteral route, through the re-scan in
// parse_primary_expression. Its two siblings — the head and the tail — have a
// file each, because a verdict is per FILE: packed together, whichever line came
// first would decide the case and hide the other two.
var a = `\u`;
