// slice 44 — the radix literals, whose value shares no character with its text.
//
// `0x10` is the member `16`, `0b110` is `6` and `0o23534` is `10076`; the scanner
// builds the reference's own `0x`+digits form — lower-case marker whatever the
// source wrote, separators dropped — and hands it to jsnum. The upper-case
// spellings beside them are the same three names, which is what says the marker
// is normalized rather than copied.
//
// ★★ The last one is past int64 and is the reason the conversion is exact rather
// than an int64 parse: `0x1ffffffffffffffff` is 2^69-1, which no 64-bit integer
// holds, and its nearest double is 590295810358705651712.
//
// ★ `0x10` and `16` merge, which is the same claim binder_numeric_name.ts makes
// for `0` and `0.0` and is here because a reader looking at a radix literal would
// not expect the decimal spelling to be its equal.
class R {
    0x10 = 1;
    16 = 2;
    0X10 = 3;
    0b110 = 4;
    0B110 = 5;
    0o23534 = 6;
    0O23534 = 7;
    0x1ffffffffffffffff = 8;
}
