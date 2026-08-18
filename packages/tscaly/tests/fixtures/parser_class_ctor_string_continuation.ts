// slice 17, the LINE CONTINUATION arm. A backslash followed by a line
// terminator is "the empty code unit sequence", so this string decodes to
// `constructor` and the member is a constructor. While the port stored no
// value this arm was folded into "any other escaped character stands for
// itself", which decodes the newline to a newline and builds a method.
class A { "const\
ructor"() {} }
