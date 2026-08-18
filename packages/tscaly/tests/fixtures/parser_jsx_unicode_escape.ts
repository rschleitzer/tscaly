// Slice 20 — parseIdentifierNameErrorOnUnicodeEscapeSequence, the reason
// parse_right_side_of_dot grew a third parameter. A JSX name may not be spelled
// with a unicode escape: Unicode_escape_sequence_cannot_appear_here (17021).
//
// ★ The report is ADDITIVE — the identifier is still built out of the DECODED
// text, so the tag below is `ab` and matches its closing tag. That is what makes
// this a third parameter rather than a refusal.
//
// All four positions are here, and the DOTTED one is the one the parameter exists
// for: every other caller of parseRightSideOfDot passes true.
// @Filename: escape.tsx
const a = <a\u0062></ab>;
const b = <div a\u0062c="1" />;
const c = <a\u0062:c></ab:c>;
const d = <a.\u0062></a.b>;
const e = <div x:\u0079="1" />;
