// The ANNOTATED fork, and its only witness is the TAG. getTypeFromTypeNode's
// keyword arms answer an intrinsic type, so this unit walks past the annotation
// and stops past it; without them it stops at `get-type-from-type-node` on the
// StringKeyword. Nothing in the dump can see the type itself — the C section gates
// the T section and this unit's check does not complete.
//
// ★ SLICE 70 MOVED THE STOP AND NOT THE FORK: with the expression dispatch in
// place these declarations run their whole tail and the tag is now
// `check-var-declared-names-not-shadowed 261`. What the fixture measures is
// unchanged — it is still the keyword arms, and controls-slice69.sh's g26 still
// moves it — but the tag it is pinned to belongs to a later question now.
declare var s: string;
declare var n: number;
declare var b: bigint;
declare var y: symbol;
declare var u: unknown;
declare var a: any;
