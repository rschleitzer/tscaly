// Slice 57. checkTypeNameIsReserved through the INTERFACE arm — TS2427.
//
// ★★★ ALL ELEVEN SPELLINGS ARE CONTEXTUAL KEYWORDS, which is the whole reason
// the check reads the identifier's TEXT rather than asking what token it was.
// `interface string {}` parses with an Identifier named `string`, so a test on
// the kind would answer *identifier* for every one of the eleven and report
// none of them. The two below are the LAST entry of the reference's list and one
// from the middle of it; `never` is in the generic fixture, so the three files
// together read three different positions of the same switch.
//
// ★★ `Object` IS NOT A NEGATIVE HERE AND IT IS IN THE TYPE-ALIAS FIXTURE, which
// is why both files carry it. An interface named `Object` MERGES with the global
// one and the reference says nothing; a type alias of the same name is a
// TS2300 duplicate identifier. The eleven are a spelling list and nothing else —
// *looks like a built-in* is not the rule, and one line of each kind is what
// proves it.
//
// ★ `Thing` is the clean negative: no report from either side. Without it the
// fixture would pass just as well against a port that reported on every
// interface it saw.
interface string {}
interface undefined {}
interface Object {}
interface Thing {}
