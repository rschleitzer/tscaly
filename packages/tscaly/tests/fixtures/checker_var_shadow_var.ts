// SLICE 76: the one shape that REACHES the wall — and SLICE 79 took the wall away,
// so what this file now pins is the finish. A `var` with a type annotation and no
// initializer is the shortest declaration whose type this port can answer, so
// checkVariableLikeDeclaration runs its whole tail and the trailing block calls
// checkVarDeclaredNamesNotShadowed — which passes both of the reference's guards and
// its symbol test, resolves its own name to its own symbol, and says nothing.
//
// ★★ THE TAG IS THEREFORE `type-of-node` NOW, raised by the DUMP walk after the
// CHECK has run to the end, and the move is what slice 79's premise row (g01)
// prices: put the `resolve-name` stop back and this file, plus four of the eight
// others in that battery, report it again.
//
// ★ Why it says nothing rather than reporting: the walk finds the var's OWN symbol
// in its own container's locals — which is the fact that makes almost all of
// resolve_name unreachable from this one caller. See that function's header.
var x: string;
