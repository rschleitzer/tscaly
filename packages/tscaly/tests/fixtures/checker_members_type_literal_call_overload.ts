// SLICE 85. TWO call signatures under one `%FEcall` symbol. The overload SKIP in
// getSignaturesOfSymbol cannot fire here and this fixture is what says so: the
// skip needs a declaration with a BODY, and a call signature never has one.
declare const overloaded: { (x: string): string; (x: number): string };
