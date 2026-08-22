// Slice 48, and the first unit in this dimension that a check ARM makes
// comparable rather than an empty statement list.
//
// Every statement here is one of the three arms slice 48 ports, and two of them
// (`;` and `debugger;`) are arms whose WHOLE body is
// checkGrammarStatementInAmbientContext — so the check runs to the end, the dump
// is produced, and the YARDSTICK compares the C section exactly. That is the one
// gate the diagnostics instrument cannot be: tests/diagcheck.sh compares our
// lines as a SUBSEQUENCE of the reference's, which is blind to a diagnostic we
// FAIL to report, and this unit is not.
//
// ★★ WHAT IT PINS IS THE ONCE-BIT. The file is ambient (a .d.ts), so all four
// statements are statements in an ambient context, and the reference answers
// exactly ONE TS1036 — the bit lives on the containing block, which is the source
// file here. Drop the bit and this unit answers four; drop the ambient check and
// it answers none. Both directions are red.
;
debugger;
;
debugger;
