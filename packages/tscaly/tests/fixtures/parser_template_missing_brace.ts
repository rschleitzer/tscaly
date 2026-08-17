// A substitution that is not closed by `}`. The reference reports "'}'
// expected" and synthesizes an empty TemplateTail so the span loop terminates;
// a diagnostic is where this port stops, so the case is permanently UNPORTED
// and is a red-producing control anyway.
//
// Remove the CloseBrace test in parse_literal_of_template_span and the re-scan
// runs from the `;` instead: scan_template then reads `;z}` looking for a
// backtick, finds the closing one, and answers a TemplateTail — so this port
// completes a whole template expression the reference does not have, with none
// of its diagnostics. The runner compares that and fails.
var a = `x${y;z}`;
