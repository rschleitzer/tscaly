// Slice 48. checkGrammarStatementInAmbientContext, on the two arms whose WHOLE
// body it is — the empty statement and the debugger statement — plus the
// expression statement, whose first line it is.
//
// ★★ THE POINT OF THE FIXTURE IS THE ONCE-BIT, not the first diagnostic. The
// reference keeps `hasReportedStatementInAmbientContext` on the containing BLOCK
// (here the source file) and its own comment says why: *we only want to really
// report an error once to prevent noisiness*. So all four statements below are
// statements in an ambient context and exactly ONE TS1036 comes out of them. A
// port without the bit answers four, which is a difference no single-statement
// fixture could show.
//
// ★ The file has no declaration at top level, so checkGrammarSourceFile's walk
// finds nothing to require a `declare` of and this unit's C section is the
// statement check alone.
;
debugger;
M.f(1);
;
