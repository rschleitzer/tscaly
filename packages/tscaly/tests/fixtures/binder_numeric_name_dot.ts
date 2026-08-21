// slice 44 — the literal that begins with a DOT, and the one that ends with it.
//
// `.5` is a NumericLiteral token and therefore a property name; its value is
// `0.5`, with a zero the source does not contain. It is here because of how the
// port reached it: scan()'s `.` arm called scan_number and then set NO token value
// at all, so a `.5` property name carried whatever the PREVIOUS token had left
// behind. Unobservable while no numeric value was stored; a wrong symbol name the
// moment one was.
//
// ★ `5.` is the mirror — an empty fraction, whose value is `5` — and it is the
// third of the three shapes where this port's raw value differs as a STRING from
// the reference's (the trailing `.` survives here and decimal.set tracks the point
// rather than the digits).
//
// ★ `0.5` and `5` beside them make both rows merges.
class Dot {
    .5 = 1;
    0.5 = 2;
    5. = 3;
    5 = 4;
}
