// The same shape with the target property OPTIONAL — getUnmatchedProperty skips
// it under the assignable relation (requireOptionalProperties is false unless the
// relation is one of the two subtype ones), so nothing is unmatched and the
// assignment holds. ★It stops for relation_missing_property's reason all the
// same: the property LOOP below then looks `b` up in the source and misses.
declare let t: { a: number, b?: number };
declare let s: { a: number };
t = s;
