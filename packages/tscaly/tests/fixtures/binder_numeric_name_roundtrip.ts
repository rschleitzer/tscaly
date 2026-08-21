// slice 44 — the SHORTEST round trip, which is the half of ToString that needs a
// multiprecision decimal and cannot be approximated.
//
// `0.1` is not 0.1: the nearest double is 0.1000000000000000055511151231257827…,
// and the member is named `0.1` because that is the shortest decimal that reads
// back as the same double. `2.675` is the same claim on a number whose seventeen
// significant digits are famous for not being 2.675.
//
// ★★ `9007199254740993` is 2^53+1, which is NOT representable: it rounds to
// 9007199254740992 and MERGES with the member spelled that way. One symbol, two
// declarations — a port that shortened its answer by one digit too many, or by one
// too few, splits them.
//
// ★ The last two are the largest finite double and the smallest positive one, whose
// shortest forms are 1.7976931348623157e+308 and 5e-324. The second is the tighter
// row: its exact value begins 4.9406564584124654…, so an implementation printing
// the exact digits and one printing the shortest disagree on every character after
// the first.
class D {
    0.1 = 1;
    2.675 = 2;
    9007199254740993 = 3;
    9007199254740992 = 4;
    1.7976931348623157e308 = 5;
    5e-324 = 6;
}
