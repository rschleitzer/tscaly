// Slice 114: getTypeOfAlias. Under this harness the dominant case is the one
// where the module does not resolve: resolveAlias answers unknownSymbol,
// getSymbolFlags answers Property, and getTypeOfSymbol then reads the errorType
// initializeChecker seeds onto that symbol's links — the line whose absence made
// this whole chapter a stop.
//
// ★ THE REPEATED TS2307 AT ONE SPAN IS THE REFERENCE'S OWN COUNT and not a
// duplicate report: resolveAlias resolves the specifier's module, and
// getTypeOfAlias then resolves it AGAIN for `exportSymbol` — a value whose only
// reader is the circular path, computed eagerly because
// getTargetOfAliasDeclaration is what reports. Moving that line inside the branch
// that reads it drops one report per alias, which is control g02.
import { Foo } from "./m";
import Bar from "./m";
Foo;
Bar;
