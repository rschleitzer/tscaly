// The HEAD route of the same claim as parser_template_untagged_escape: an
// invalid escape in the head chunk of an untagged template. Permanently
// unported, red if re_scan_template_token stops testing IsInvalid.
var b = `\u${1}c`;
