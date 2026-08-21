// slice 44 — the plainest numeric declaration name, and the MERGE that says the
// name is the VALUE and not the spelling.
//
// A numeric literal's Text is not its source slice: the scanner ends scanNumber
// with jsnum.FromString(tokenValue).String(), the ECMAScript ToString of the
// parsed double. So `0` and `0.0` are the SAME name, one symbol with two
// declarations and one entry in the class's members table — and a port storing
// the source slice declares two members here, silently, because both spellings
// are well formed and both produce a symbol.
//
// ★ `1` and `1.0` are the second pair, so the row is not carried by zero alone,
// and `2` is the singleton beside them: three names out of five members.
//
// ★ The identifier member is the shape the slice did NOT change — a declaration
// named by an Identifier never went through the literal arm at all.
class C {
    0 = 1;
    0.0 = 2;
    1 = 3;
    1.0 = 4;
    2 = 5;
    plain = 6;
}
