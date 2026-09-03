// getUnmatchedProperty: the target requires `b` and the source has no such
// property, so the relation fails before any property is compared.
//
// ★★★ IT USED TO STOP AT `global-object-property-augment` — a property lookup
// that MISSES falls through to `getPropertyOfObjectType(globalObjectType, name)`,
// which is §3.11's augment — and slice 127 landed that augment. So the comparison
// now FAILS rather than stopping, and what the unit pins is the code:
// reportUnmatchedProperty puts TS2741 (*property 'b' is missing in type … but
// required in type …*) into the chain and reportRelationError SUPPRESSES its own
// TS2322 behind it. Emitting the generic code here is the failure this fixture
// catches; it did exactly that for one build.
declare let t: { a: number, b: number };
declare let s: { a: number };
t = s;
