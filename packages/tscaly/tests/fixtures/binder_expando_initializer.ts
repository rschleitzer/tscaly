// slice 38 — getInitializerSymbol, the gate that decides whether a name can carry
// expando declarations at all. It reads the symbol's VALUE DECLARATION, and for a
// variable it answers the INITIALIZER's symbol rather than the variable's — so
// `a.x` lands on an anonymous symbol that nothing is named after.
//
// Four rows, in a TypeScript file, so only the arms that are not JavaScript-only
// can fire:
//   fn   a const initialized with a function expression  →  declares
//   ar   a const initialized with an arrow               →  declares
//   lt   a LET initialized with an arrow                 →  nothing: the arm
//        wants `Parent.Flags&Const != 0 || IsInJSFile`, and neither holds
//   C    a TypeScript class declaration                  →  nothing: that arm is
//        `IsInJSFile(declaration) && IsClassDeclaration`
//   Ce   a class EXPRESSION                                →  nothing, and this
//        is the other side of the same JavaScript-only line: IsExpandoInitializer
//        admits a class expression and an empty object literal only under
//        IsInJSFile, so binder_expando_js.ts and this file are one claim read
//        from both ends
//   ob   an empty OBJECT LITERAL                            →  nothing, likewise
const fn = function () {};
fn.x = 1;
const ar = () => {};
ar.x = 2;
let lt = () => {};
lt.x = 3;
class C {}
C.x = 4;
const Ce = class {};
Ce.x = 5;
const ob = {};
ob.x = 6;
