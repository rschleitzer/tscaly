// SLICE 71's BOOLEAN arms — `c.trueType` and `c.falseType`, which are the FRESH
// member of each of the two pairs initialize_intrinsic_types builds by hand.
// They are the only literal types this port never mints through
// getFreshTypeOfLiteralType, so they are the only ones whose fresh/regular cycle
// is written out rather than derived, and this is the fixture that proves the
// two of them answer at all.
//
// * `boolean` itself is still missing and cannot be here: it is the UNION of the
// two REGULAR members, and type_to_string's Boolean arm still reports.
true;
false;
