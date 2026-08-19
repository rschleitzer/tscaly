// Slice 24 — the second guard, which is not about the FILE but about a TYPE.
//
// A parameter list and an accessor parsed as part of a TYPE are never checked:
// the reference passes `parseParameter` (no check) where a signature passes a
// closure that checks, and gates the accessor on `flags&ParseFlagsType == 0`.
// The reason is that a type's insides are TypeScript syntax by construction — the
// annotation that CONTAINS them is what gets reported, once, at its own range.
//
// So each line below must produce exactly ONE diagnostic, at the outer
// annotation, and nothing for the parameter, the getter or the method signature
// inside it. Measured against the oracle before the fixture was written: three
// diagnostics, at 7..26, 35..54 and 63..85.
// @Filename: type_position_quiet.js
var f: (a: string) => void;
var o: { get x(): number };
var p: { m(b: string): void };
