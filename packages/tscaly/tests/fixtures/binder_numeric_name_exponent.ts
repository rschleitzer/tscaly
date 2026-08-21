// slice 44 — the two boundaries that decide the FORM, and the overflow past them.
//
// ToString is fixed notation for 1e-6 <= |x| < 1e21 and exponential outside it,
// so `1e20` is the member `100000000000000000000` and `1e21` is `1e+21`; `0.000001`
// is `0.000001` and `1e-7` is `1e-7`. Four members, four different names, and a
// port that picked either form alone gets two of them wrong.
//
// ★★ The exponent's own spelling is normalized twice over: a POSITIVE exponent
// keeps its sign and at least two digits (`1e+21`), a negative one below ten
// loses its leading zero (`1e-7` and not `1e-07`) — which in the reference is a
// textual fix-up applied to Go's own output and not something the formatter does.
//
// ★ `1e999` overflows to Infinity and is named `Infinity`, a member name with no
// digit in it at all; `1e-323` is a DENORMAL, whose shortest round trip is `1e-323`
// and whose exact value has 323 decimal places.
//
// ★★ `1e` is the last member and it is not a typo: an exponent with no digits is
// reported and does NOT extend the span the value is taken from, so the value is
// the `1` in front of it and the member merges with the plain `1` beside it. It
// is the one shape in which the reference's `end` and its `s.pos` differ, and a
// port taking the value from the token's whole span reads `1e`, which is not a
// number at all.
class E {
    1e20 = 1;
    1e21 = 2;
    0.000001 = 3;
    1e-7 = 4;
    1e999 = 5;
    1e-323 = 6;
    1e = 7;
    1 = 8;
}
