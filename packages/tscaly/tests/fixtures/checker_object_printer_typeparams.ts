// Slice 111. The signature's TYPE-PARAMETER list: the bare name, the constraint and
// the default — and the constraint is written from the TYPE, where the reference may
// reuse the annotation's own node.
declare const plain: <T>(x: T) => T;
declare const constrained: <T extends string>(x: T) => T;
declare const objconstraint: <T extends { a: number }>(x: T) => T;
declare const defaulted: <T = string, U>(x: T) => T;
