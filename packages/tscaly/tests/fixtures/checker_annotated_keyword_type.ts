// The ANNOTATED fork, and its only witness is the TAG. getTypeFromTypeNode's
// keyword arms answer an intrinsic type, so this unit walks past the annotation
// and stops at checkExpression; without them it stops at `get-type-from-type-node`
// on the StringKeyword. Nothing in the dump can see the type itself — the C
// section gates the T section and this unit's check does not complete.
declare var s: string;
declare var n: number;
declare var b: bigint;
declare var y: symbol;
declare var u: unknown;
declare var a: any;
