// isKnownProperty's SECOND disjunct: a target with a string index signature knows
// every name, so no property of the source is in excess however it is spelled.
// ★★It stops at `check-grammar-index-signature`, which halts the walk at the
// FIRST node of any file containing an index signature — the same wall slice 117
// recorded for getPropertyTypeForIndexType's index arm. The file is the marker.
declare let t: { a: number, [k: string]: number };
t = { a: 1, zzz: 2 };
