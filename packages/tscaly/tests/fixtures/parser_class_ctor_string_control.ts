// slice 17, the same fold from the other side and the sharper half: `\r` is a
// CARRIAGE RETURN and `\n` a LINE FEED, not the letters `r` and `n`. Read as
// letters both of these would decode to `constructor` and build a constructor;
// they are ordinary methods.
class A { "const\ructor"() {} }
class B { "co\nstructor"() {} }
