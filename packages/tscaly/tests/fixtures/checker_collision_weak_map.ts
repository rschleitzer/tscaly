// Slice 59. recordPotentialCollisionWithWeakMapSetInGeneratedCode's guard —
// `languageVersion <= ScriptTargetES2021`, which ES2025 closes.
//
// ★★ THE PAIR IS ONE CONDITION: the reference asks
// needCollisionCheckForIdentifier for `WeakMap` and for `WeakSet` in one
// disjunction, because the down-level private-name transform reserves both. One
// fixture is therefore a witness for both spellings.
//
// ★ Behind the guard: addDeferredDiagnostic of checkWeakMapSetCollision, which
// reads NodeCheckFlagsContainsClassWithPrivateIdentifiers off nodeLinks — a table
// this port does not have. Hence a report and not a port, and hence this pin.
class WeakMap {}
