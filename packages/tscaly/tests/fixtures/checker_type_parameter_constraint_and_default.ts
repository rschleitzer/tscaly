// SLICE 81: the third of checkTypeParameter's three checks, i.e. the row this
// slice's stop MOVES to.
//
// checkTypeAssignableTo(defaultType, …, TS2344) is reached only when the parameter
// has BOTH a constraint and a default, and both have to RESOLVE for the mark to
// let it through — so a keyword pair is the shape that gets there. The reference's
// argument additionally needs instantiateType and a type mapper, which is two more
// dimensions behind the relation itself.
declare function bothOk<T extends string = string>(x: T): T;
declare function bothBad<T extends string = number>(x: T): T;
