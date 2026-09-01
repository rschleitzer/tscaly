// Slice 115's TYPE PREDICATE arm of getTypeFromTypeNode — two keywords and no type
// read at all: `asserts x is T` denotes void and `x is T` denotes boolean. It is
// UNPORTED by construction (get-type-predicate-of-signature stands in front of it),
// so the stop TAG is the only witness the arm has.
declare namespace N {
    interface A { x: number; }
    declare function p(x: unknown): x is A;
    declare function q(x: unknown): asserts x is A;
}
