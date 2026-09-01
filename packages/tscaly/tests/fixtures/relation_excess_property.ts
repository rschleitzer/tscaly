// Slice 118: hasExcessProperties' one report, AND THE FIXTURE IS A MARKER
// RATHER THAN A WITNESS. `b` is not a property of the target, so the reference
// emits TS2353 at the property and SUPPRESSES the relation's own TS2322 —
// reportRelationError opens with a switch whose first case is exactly this
// message, which is why tsc prints one line here and not two.
//
// ★★★ THIS PORT REPORTS NOTHING HERE, and the wall is one call in FRONT of the
// chapter: `check_type_related_to_and_optionally_elaborate` asks the ELABORATOR
// before it asks the reporting relation, and `elaborate-object-literal` stops
// there for every object literal. Every route to TS2353 — an assignment, an
// annotated declaration, a call argument — goes through that call, so the
// chapter's only report has NO reachable input at stage 1. Measured: 0 units in
// 1 565. The file is kept as the marker for the slice that ports the elaborator.
declare let t: { a: number };
t = { a: 1, b: 2 };
