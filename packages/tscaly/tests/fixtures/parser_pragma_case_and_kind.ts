// Two claims of the pragma scan that the main fixture cannot separate.
//
// CASE: extractName lowercases what it read, so both the TAG name and the
// ARGUMENT names are matched case-insensitively. `<REFERENCE path="x" />` is
// indistinguishable either way — folded it parses and says nothing, unfolded it
// is not a reference pragma and says nothing — so the two lines below are the
// ones that separate them: an upper-case tag with NO usable argument (TS1084
// only when folded) and an upper-case argument name (TS1084 only when NOT
// folded).
/// <REFERENCE />
/// <reference PATH="x" />
