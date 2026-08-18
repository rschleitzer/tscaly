// slice 17, the \x arm of scanEscapeSequence: two hex digits, and the value is
// the character they name. See parser_class_ctor_string_escape.ts for why each
// arm gets a file.
class A { "\x63onstructor"() {} }
