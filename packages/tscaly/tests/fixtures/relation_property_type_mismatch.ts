// propertiesRelatedTo -> propertyRelatedTo -> isPropertySymbolTypeRelated, whose
// inner relation answers FALSE. ★The diagnostic is TS2322 and NOT TS2326: the
// reference's `Types_of_property_0_are_incompatible` is a chain LINK, and the
// chain's HEAD is reportRelationError's own message. A dump carries a code and a
// span, so the link is invisible in both directions — which is the containment
// that lets this whole chapter be report-free.
declare let t: { a: number };
t = { a: "s" };
