// Slice 60. The second half of the pair — see
// checker_type_parameter_constraint_keyword.ts for the argument.
//
// ★ `Foo` is declared in a LATER statement on purpose: the interface's own arm
// reports too (`check-exports-on-merged-declarations`), and with it first the tag
// of the unit would be that report rather than this one. record_unported keeps the
// FIRST, so the order of the statements is part of what this fixture pins.
export {};
function h<T extends Foo>(): void {}
interface Foo { n: number }
