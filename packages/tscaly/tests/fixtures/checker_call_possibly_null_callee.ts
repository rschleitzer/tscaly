// reportCannotInvokePossiblyNullOrUndefinedError — the half of
// checkNonNullTypeWithReporter's reporter flag that reads nothing but the facts,
// and the only one slice 90 can port. The callee is the `null` KEYWORD, which is
// the one nullable type this port answers from an expression without a symbol
// table, so TS2721 lands on it. `new null()` takes the OTHER half of the flag and
// is therefore silent here: reportObjectPossiblyNullOrUndefined picks among six
// codes on entityNameToString, which this port does not have.
null();
new null();
