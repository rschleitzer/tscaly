// A class merged with a namespace, so the symbol carries two declarations and
// checkTypeParameterListsIdentical — which runs AFTER the static type in
// checkClassLikeDeclaration — reports instead of returning on its
// `len(declarations) == 1` guard. It is the one shape whose stop is BETWEEN the
// static type and checkFunctionOrConstructorSymbol.
class Foo {}
namespace Foo {
    export const x = 1;
}
