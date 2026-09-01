// isPerformingCommonPropertyChecks: a target ALL of whose properties are optional
// is a WEAK type, and a source with no property in common with it is refused even
// though every property of the target is optional. This is the second of the three
// rows the slice removes, and it is the one whose REPORT is still a stop — the
// TS2559/TS2560 fork needs the return type of the source's first signature
// related to the target, a relation asked from inside a relation.
// ★So the assertion here is the STOP and its tag: `no-common-properties-report`
// is reached, which proves the four conjuncts slice 102 could not ask now answer.
declare let t: { a?: number, b?: number };
declare let s: { z: number };
t = s;
