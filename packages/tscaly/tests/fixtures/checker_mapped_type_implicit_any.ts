// SLICE 82: TS7039, and it is a report this port had been DROPPING rather than
// deferring. checkMappedType's `if mappedTypeNode.Type == nil { reportImplicitAny(
// node, anyType, WideningKindNormal) }` stands between the recursion and the stop
// upstream and was simply missing here; report_implicit_any's MappedType label has
// been ported since slice 69 with nothing to feed it.
//
// ★ A dropped call is silent in BOTH halves — no diagnostic, and no work-list row
// saying one is owed — which is why it survived twenty-one slices under a chapter
// that HAS a fixture.
export {};
declare const noTemplate: { [K in "x"] };
