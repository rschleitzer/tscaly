// Slice 52. FindUseStrictPrologue's own rule: a directive PROLOGUE ends at the
// first statement that is not a string-literal expression statement.
//
// ★★★ THE SECOND FUNCTION MUST REPORT NOTHING, and that `else return nil` is the
// only thing that makes it so. Both functions have a non-simple parameter list and
// both contain `"use strict"`; the difference is that the second one's directive
// follows real code, so it is not a directive at all. A port that SEARCHED the
// statement list instead of walking its prologue reports on both and is green on
// any fixture that has only the first.
//
// ★★ THE THIRD IS THE OTHER HALF OF THE SAME LOOP: a run of directives is walked
// through, so a `"use strict"` behind ANOTHER directive still counts. Together the
// two say the loop continues over prologue directives and stops at the first
// statement that is not one — which two separate fixtures could each satisfy
// alone.
function f(a = 1) { "use strict"; }
function g(a = 1) { let x = 1; "use strict"; }
function h(a = 1) { "use asm"; "use strict"; }
