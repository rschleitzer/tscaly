// getUnmatchedProperty: the target requires `b` and the source has no such
// property, so the relation fails before any property is compared.
//
// ★★★ IT STOPS AT `global-object-property-augment`, AND THAT IS THE SHAPE OF THE
// WHOLE FAILING HALF OF THIS CHAPTER: a property lookup that MISSES falls through
// to `getPropertyOfObjectType(globalObjectType, name)` — §3.11's augment — so
// every comparison that fails BECAUSE a property is absent stops rather than
// answers. The succeeding half needs no such lookup and is what this slice moves.
// ★The stop is read as *unknown* and not as *missing*: get_unmatched_property
// reads the mark around the lookup, which is why no TS2322 is invented here.
declare let t: { a: number, b: number };
declare let s: { a: number };
t = s;
