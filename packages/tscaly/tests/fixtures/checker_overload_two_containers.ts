// ★★★ THE SAME-PARENT TEST, and a symbol whose declarations sit in TWO
// containers is the only thing that can see it. Two namespace blocks of the same
// name merge, and `f` inside them is one EXPORT symbol with two declarations
// whose parents are different ModuleBlocks — so the "not immediately following"
// question is not asked of them at all, and asking it would invent a report on
// the first declaration.
//
// ★★★ AND IT IS THE FIXTURE THAT PROVES THE **TWO** CALLS AT THE FUNCTION SITE
// ARE TWO SYMBOLS, measured rather than argued: the unit carries three reports,
// two of them at the same span, and removing the export-symbol call leaves two.
// An exported declaration's LOCAL symbol lives in its own block, so there are two
// of those with one declaration each — one report apiece — while the EXPORT
// symbol carries both declarations and reports once more on the last of them. A
// port making only the local call prints two lines where three are expected.
namespace N {
    export function f(a: string): void;
}
namespace N {
    export function f(a: number): void;
}
