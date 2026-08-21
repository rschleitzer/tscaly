// slice 44 — the two leading-zero forms, whose values come from two DIFFERENT
// places and neither of them from the source text.
//
// `0777` is a legacy octal literal: the scanner reports it, and its value is
// `strconv.FormatInt(ParseInt(digits, 8, 64), 10)` — the member `511` — computed
// in that arm and NOT routed through jsnum, because the arm returns before every
// other one reaches it. `0189` is not octal, so it takes the leading-zero arm
// instead, is reported for a different reason, and IS routed through jsnum, which
// trims the zero: the member `189`.
//
// ★★ Both are grammar errors and the fixture keeps them, because the bind
// diagnostics are compared too and a value computed on an error path is exactly
// the kind that no valid corpus can witness.
//
// ★ `511` beside `0777` and `189` beside `0189` make the pair a MERGE, which is
// how the table says what the name is rather than only how many names there are.
class Z {
    0777 = 1;
    511 = 2;
    0189 = 3;
    189 = 4;
}
