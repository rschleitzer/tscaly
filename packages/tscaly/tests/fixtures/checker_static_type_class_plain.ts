// The 2 916-unit shape one statement further on than slice 66 left it: a class
// with no type parameters and no heritage clause. getTypeOfSymbol dispatches on
// SymbolFlagsClass into getTypeOfFuncClassEnumModule, whose worker mints an
// ANONYMOUS object type — the class's static side — and asks
// getBaseTypeVariableOfClass, which answers nil because the base constructor
// type of a class with no `extends` is undefinedType. So the arm stops at
// checkFunctionOrConstructorSymbol.
class C {
    a: string;
}
