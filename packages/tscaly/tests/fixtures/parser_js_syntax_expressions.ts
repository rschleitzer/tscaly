// Slice 24 — the three expression arms. The non-null assertion is reported at
// the whole expression's range; `as` and `satisfies` are reported at their TYPE's
// range, which is what distinguishes them from the annotation arm.
// @Filename: expressions.js
var a = b!;

// ★★★ `b!!` is the shape that makes the ABSENCE of the dedup observable. Both
// non-null expressions start at `b`, so the two diagnostics share a POS — and
// `parseErrorAtRange`'s dedup drops a second entry at the last one's position,
// while `jsErrorAtRange` appends raw. The reference reports both; a port that
// routed these through the parse-error path would report one.
var c2 = b!!;
var c = d as number;
var e = f satisfies string;
