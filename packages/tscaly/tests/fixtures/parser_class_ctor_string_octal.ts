// slice 17, the legacy-octal arm — the one arm whose VALUE depends on whether
// errors are reported: with them (a string literal always) it answers the
// decoded character, without them (a tagged template) the raw escape text.
// `\143` is `c`, so this is a constructor, and it carries the octal diagnostic
// the arm emits besides.
class A { "\143onstructor"() {} }
