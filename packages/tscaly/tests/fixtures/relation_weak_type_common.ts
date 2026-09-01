// The negative: one property in common is enough for hasCommonProperties, so the
// weak-type check passes and the structural comparison decides. ★It must NOT
// report `no-common-properties-report`, and that is what the row measures.
declare let t: { a?: number, b?: number };
declare let s: { a: number };
t = s;
