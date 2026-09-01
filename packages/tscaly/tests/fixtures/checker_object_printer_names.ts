// Slice 111. The PROPERTY-NAME classification, which is three-way and not two-way:
// an identifier bare, a numeric-literal name bare as a NUMBER, everything else
// quoted — and `stringNamed` turns the middle arm off, so `"1"` is quoted where `1`
// is not.
declare const ident: { abc: string };
declare const numeric: { 1: string };
declare const stringnum: { "1": string };
declare const dashed: { "peer-a": string };
declare const dotted: { "./*": string };
declare const negative: { "-1": string };
declare const newmeth: { new(): void };
