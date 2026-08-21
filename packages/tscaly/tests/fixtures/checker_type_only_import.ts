// slice 46 — the shape that makes the checker crash, as a fixture rather than a
// footnote.
//
// `import type { A } from './x'` is one line of valid TypeScript and a nil
// dereference inside the reference's checker: the clause is an
// `ast.IsTypeDeclaration` with named bindings and NO name, so getTypeOfNode takes
// its type-declaration arm and getSymbolOfDeclaration answers nil. The types
// oracle carries the one exclusion that stands in front of it
// (isNamelessTypeOnlyImportClause), and this fixture is what makes that exclusion
// MEASURABLE: take it away and this unit stops having a reference answer.
//
// ★ The neighbours are here for the same reason the exclusion is narrow: a value
// import is no type declaration, and a DEFAULT type import has a name and
// therefore a symbol. Both must keep answering.
import type { A } from './x';
import type B from './y';
import { C } from './z';

let a: A;
let b: B;
let c = C;
