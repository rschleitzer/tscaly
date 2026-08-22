// Slice 52. isUseStrictPrologueDirective compares the RAW SOURCE TEXT of the
// literal, quotes included — not its cooked value.
//
// ★★★ THE SECOND FUNCTION IS THE WHOLE FIXTURE AND IT MUST REPORT NOTHING.
// `"use\u0020strict"` COOKS to the ten characters `use strict`, so a port that
// asked literal_text_of would call it a directive; the reference reads
// GetSourceTextOfNodeFromSourceFile and compares against the twelve-character
// spellings, with its own comment saying why: *it is not ok for the string to
// contain unicode escapes (as per ES5).* This is the only shape in the corpus that
// can separate the raw text from the cooked one.
//
// ★★ AND BOTH QUOTE FORMS COUNT, which is a second thing one spelling cannot
// prove: the comparison is against `"use strict"` OR `'use strict'`, so the first
// function here uses single quotes. A port that hardcoded the double quote is
// green on every other fixture of this slice.
//
// ★ The third is the length test from the other side: a longer string whose first
// twelve bytes match must not pass, which is what makes the check `end - start ==
// 12` rather than a prefix comparison.
function f(a = 1) { 'use strict'; }
function g(a = 1) { "use\u0020strict"; }
function h(a = 1) { "use strict but longer"; }
