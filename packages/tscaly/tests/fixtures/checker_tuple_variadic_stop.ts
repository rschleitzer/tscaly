// Slice 61. The one place in this slice where the SHAPE of the absence matters:
// checkTupleType STOPS its ordering loop at a VARIADIC element rather than
// skipping it, and this fixture is the witness that the difference is a
// diagnostic and not a preference.
//
// ★★★ A VARIADIC ELEMENT'S FLAGS DEPEND ON A TYPE. The reference resolves `...R`,
// finds it array-like and sets ElementFlagsRest on the element — so the optional
// element that follows it is *an optional element after a rest element*, TS1266,
// and the loop breaks there. A port that merely SKIPPED the element it cannot
// classify would carry `seenRestElement` as false into the next round, take
// TS1266's branch untaken, set seenOptionalElement instead, and then report
// TS1257 on `number` — a diagnostic the reference does not have, which is the one
// thing diagcheck can fail on. Stopping the loop emits nothing here, and nothing
// is a subset.
//
// ★ The alias is declared AFTER the tuple deliberately: a type alias statement
// reports `check-exports-on-merged-declarations` from its own arm, and putting it
// first would make the unit's tag that instead of the tuple's.
export {};
declare const t: [...R, string?, number];
type R = string[];
