// Slice 62. The report checkFunctionOrMethodDeclaration has carried since slice 52
// without a caller, and the ONE shape that reaches it.
//
// ★★★ IT IS REACHABLE ONLY WHEN THE COMPUTED NAME IS **NOT** DYNAMIC, and that is
// an ordering fact rather than a corpus fact. checkGrammarMethod's type-literal
// branch asks the dynamic-name question first, and this port answers it with a
// report — so a `[foo()]` method takes the `is-late-bindable-name` tag and this one
// can never be first. A computed name over a string LITERAL answers false at
// `IsDynamicName`, the grammar check falls through, and
// `check-computed-property-name` is the tag.
//
// ★★ SLICE 52 PREDICTED THE CALLER BY NAME: its header read *the
// computed-property-name arm … belongs to this function's OTHER caller: a method's
// name can be `[Symbol.x]`, a function declaration's cannot.* The report sits at the
// reference's own line, in checkFunctionOrMethodDeclaration, rather than in the
// method arm — which is why a function declaration's tag does not move.
//
// ★ The reference's comment at that line is the whole reason the test is on the
// KIND: *do not use hasDynamicName here, because that returns false for well known
// symbols* — `[Symbol.iterator]` is late-bindable and must still be checked.
export {};
declare const a: { ["k"](): void };
