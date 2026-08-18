// slice 17, the OTHER suggestion half — getSpaceSuggestion, which asks whether
// the name BEGINS with a keyword and is more than two characters longer than
// it. It asks that of the decoded text: the name below decodes to `classAé`
// and starts with `class`, while the source spelling starts with a backslash
// and so starts with no keyword at all. The trailing `x` is what reaches the
// site — see parser_missing_semicolon_escaped.ts.
\u0063lassAé x
