// Slice 91. The `arguments` arm — the resolver answers c.argumentsSymbol for the
// name inside any function-like container, and checkIdentifier's third line is
// the only place that symbol is ever compared.
//
// ★★★ THE NESTING IS THE FIXTURE AND THE OBVIOUS SPELLING DOES NOT WORK. TS2815
// needs the name to RESOLVE to argumentsSymbol *and* to sit in a property
// initializer — and the resolver's arm lists MethodDeclaration, Constructor, the
// two accessors, FunctionDeclaration and FunctionExpression, none of which is a
// property declaration or a class static block. So a bare `p = arguments` inside
// a class resolves to nothing at all and the reference answers TS2662 out of
// onFailedToResolveSymbol, one wall further on. The container that owns
// `arguments` has to be OUTSIDE the class that owns the initializer.
class Outer {
  m() {
    class Inner {
      p = arguments;
    }
    return Inner;
  }
}

function ok() {
  return arguments;
}
