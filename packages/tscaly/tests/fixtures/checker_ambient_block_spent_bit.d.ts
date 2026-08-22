// Slice 50, and the fixture for the defect the BLOCK arm exposed on its first
// corpus run — `compiler_ambientWithStatements`, reduced to two statements.
//
// ★★★ THE ONCE-BIT IS THE WHOLE BLOCK'S AND ONLY THE FIRST STATEMENT SPENDS IT.
// The reference answers ONE TS1036 here, on the `break`; this port has no
// break-statement arm, so before spend_ambient_report_of_container it reported the
// `debugger` instead — a diagnostic at a position the reference does not have,
// which is exactly what diagcheck can fail on and did. The port now says nothing
// about this block, which keeps our C section a strict SUBSET.
//
// ★★ SO THIS UNIT'S EXPECTED ANSWER IS EMPTY, and it is a gate in the direction
// that matters: restore the report and it prints `C 27 35 1036` while
// checker_ambient_statements_only.d.ts — whose first statement IS ported — stays
// green. Two fixtures, one mechanism, and only the pair can tell the suppression
// from a missing check.
declare namespace M { break; debugger; }
