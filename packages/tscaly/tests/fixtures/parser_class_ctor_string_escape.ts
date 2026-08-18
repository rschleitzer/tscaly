// slice 17: the constructor test is over the string's DECODED value, so a
// spelling that only reaches `constructor` after escapes are resolved builds a
// CONSTRUCTOR and not a method. This is the default arm — an escape the
// grammar does not name stands for the character itself.
//
// One arm per FILE, and that is slice 12's lesson rather than tidiness: the
// verdict is per unit, so three spellings in one file would let one control
// stand for all three and hide which route broke.
class A { "\constructor"() {} }
