// SLICE 85. A CLASS reaches two stops in a row and neither is the row slice 77
// left here: the instance type is a Reference (every class gets a `this` type) and
// the static side is an anonymous type whose symbol is a class rather than a type
// literal. Both are one call deeper than `check-index-constraints`.
class C {
    [k: string]: string;
}
