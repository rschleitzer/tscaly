// SLICE 77: the second half of TS2499's condition. `IsEntityNameExpression(expr)
// && !IsOptionalChain(expr)` is two tests, and `a?.b` passes the first — it IS a
// property-access chain over an identifier — so a port that wrote only the first
// would leave this file silent and no other fixture would notice.
// * The reference reports TS2503 (`Cannot find namespace 'a'`) at 359..360 BEFORE
// our line, from checkTypeReferenceNode's resolveEntityName — a chapter this port
// has not reached. Ours is therefore a strict subsequence here rather than an
// equality, which is the one fixture of this slice where the two differ, and the
// difference belongs to another dimension.
declare const a: any;
interface K extends a?.b { }
