// SLICE 71's STRING arm, and the file is here to pin the arm rather than the
// NAME: the type is made, the expression statement discards it, and the unit
// runs to the type walk exactly as `null;` does. What the name looks like is
// invisible to every yardstick — see tests/litcheck.sh, which is the instrument
// that measures it.
//
// Both `case` labels of the reference's shared arm are here, because they are
// two KINDS that share one body: a StringLiteral and a
// NoSubstitutionTemplateLiteral. A port that ported one and forgot the other
// would leave a fixture green.
//
// * The last two lines are the INTERNING, and they gate nothing today: two
// occurrences of one value must be one type, and no instrument here compares
// type identity. Written down rather than left out, because the day
// isTypeIdenticalTo lands this file is where it is asked.
"abc";
``;
`no substitution`;
"";
"a";
"a";
