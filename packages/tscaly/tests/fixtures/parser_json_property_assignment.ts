// Slice 19 — validateJsonObjectLiteral's first clause: an element that is not a
// PropertyAssignment is reported (1136) and SKIPPED, so its parts are never
// validated. Three shapes the object grammar accepts and JSON does not.
// @Filename: spread.json
{...x}
// @Filename: shorthand.json
{a}
// @Filename: method.json
{ m() {} }
