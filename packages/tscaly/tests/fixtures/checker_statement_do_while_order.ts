// Slice 63. The one thing that separates checkDoStatement from checkWhileStatement:
// the ORDER of their two steps.
//
// ★★★ A `do` WALKS ITS BODY AND THEN CHECKS ITS CONDITION; A `while` DOES IT THE
// OTHER WAY ROUND. Nothing here produces a diagnostic, so none of it is visible to
// diagcheck — what the order decides is the unit's unported TAG, which names
// whichever hole is met FIRST. The statement below holds a call in its body and an
// identifier in its condition, and the tag is `check-expression CallExpression`
// (214); the same two constructs in a `while` would tag the Identifier (79).
//
// ★ The two spellings cannot share a fixture: record_unported keeps the FIRST
// report, so a file holding both would only ever show the `do`'s tag.
// controls-slice63.sh's g05 swaps the two lines of checkDoStatement instead, and
// this unit's tag moving from 214 to 79 is the whole measurement.
do f(); while (y)
