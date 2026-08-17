// Unterminated is NOT exempt: scanTemplateAndSetTokenValue reports
// Unterminated_template_literal on every call, including the scan-loop call
// that suppresses the escape errors. So this reports unported where an invalid
// escape in a tagged template does not, and the two flags are tested
// separately for that reason.
//
// Permanently unported, and red if the Unterminated arm of either test is
// dropped: without it this port completes a tree with no diagnostic on it.
var a = `c${1}d
