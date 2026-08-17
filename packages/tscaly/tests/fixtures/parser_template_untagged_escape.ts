// An UNTAGGED template with an invalid escape is a grammar error the reference
// reports, so this file is permanently UNPORTED and is a red-producing control
// anyway (the parser_types_linebreak technique).
//
// Drop the IsInvalid test in re_scan_template_token — leaving the exemption in
// next_token_without_check with nothing behind it — and this port stops
// declaring unported, completes a tree, and answers it without the reference's
// diagnostic. The runner compares that and fails.
//
// This is the NoSubstitutionTemplateLiteral route, through the re-scan in
// parse_primary_expression. Its two siblings — the head and the tail — have a
// file each, because the verdict is per FILE: packed together, whichever line
// came first would keep the case unported and hide the other two.
var a = `\u`;
