// The two runs a decorator may appear in. The reference's parseModifiersEx
// admits `[...leadingDecorators, ...leadingModifiers, ...trailingDecorators]`
// and builds ONE list holding both kinds in source order, so what these lines
// gate is the ORDER the class node's children come out in.
//
// Having both runs at once is illegal and is left to the CHECKER, which is why
// the second line parses here with no diagnostic. The guard that stops a THIRD
// run is a diagnostic and therefore lives in parser_decorator_two_runs.ts.
declare const d: any;

@d export class A { }
export @d class B { }
@d abstract class C { }
@d var v = 1;
