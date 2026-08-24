// Slice 63. ast.IsIterationStatement's `lookInLabeledStatements` flag, which is the
// one parameter in this slice whose value cannot be read off a single call site.
//
// ★★★ THE FIRST LINE IS LEGAL AND THIS FIXTURE'S WHOLE CONTENT ABOUT IT IS THAT WE
// SAY NOTHING. `continue a` names a label THREE labels above a `do` loop, and the
// predicate has to look THROUGH both intervening labels to find it — which is what
// the flag asks for and what the RECURSION passes on. Answer it without the flag and
// the port invents a TS1115 on a correct program, which is exactly what diagcheck
// exists to catch.
//
// ★★ THREE LABELS AND NOT TWO, ON PURPOSE. With two, a recursion that dropped the
// flag would still answer correctly — the one recursive step lands directly on the
// `do` — so the row that breaks the flag would be ungated and the fixture would be
// measuring nothing. Three levels separate the flag at the CALL SITE (g13) from the
// flag inside the RECURSION (g14), and both are red.
//
// ★ The second line is the same shape with the loop REPLACED by a block, and it is
// the negative control the flag does NOT change: `continue a` there is genuinely
// wrong, and the reference reports it. We do too, which is why the file is not a
// pure absence.
a: b: c: do continue a; while (1)
e: f: { continue e; }
