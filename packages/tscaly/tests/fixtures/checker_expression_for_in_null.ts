// The for-in statement's left-hand chain, reached rather than stood in front of.
// The subject and the left side are both `null`, so both take the dispatch's null
// arm and the unit lands on `is-type-assignable-to` — the chain's second arm
// (TS2405), which needs a type and is the first thing this port still cannot ask.
//
// ★ THE ROW BEHIND IT IS NOT REACHABLE FROM ANY SINGLE UNIT and this file is why
// we know: TS2407 (isTypeAssignableToKind on the SUBJECT) is asked after the left
// side, so a unit whose left side is typed always reports the left side's own row
// first, and a unit whose left side is not typed never gets that far. Its row is
// ungated by construction, not by omission.
//
// ★ The declaration form — `for (var k in null)` — measures something else
// entirely: the declaration's own type comes first and the unit stops at
// `get-index-type`, which is slice 69's row and not this slice's.
for (null in null) {
}
