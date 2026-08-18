// A flag character outside ASCII: the flags loop steps by the RUNE size, so a
// two-byte identifier part belongs to the literal whole. The reference only
// validates flags in the checker, so the parse takes any identifier part.
var k = /ab/á;
var l = 2;
