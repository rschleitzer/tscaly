// A STRING literal always scans with ReportErrors set, where a template scans
// with it CLEAR — the asymmetry §3.5z is about, seen from the string side.
// scanString passes the flag unconditionally, so an invalid escape here is a
// diagnostic at scan time; the same escape in `` `\u` `` says nothing until an
// untagged re-scan asks for it.
//
// ONE LINE on purpose. fixtures/strings.ts already carries this escape, and it is
// permanently unported at a parser `;` diagnostic several lines earlier — so the
// runner never compares it and the claim was UNGATED with a fixture sitting right
// there. A case has to parse to completion for its diagnostics to be looked at.
var s = '\u';
