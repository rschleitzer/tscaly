// Slice 97: the two walls, each written so the file reaches it and nothing else.
//
// A `this` at the top level of a SCRIPT is `getTypeOfSymbol(globalThisSymbol)`, so
// this file is deliberately NOT a module — the one fixture of this slice that must
// not carry `export {}`.
//
// ★ Slice 97 wrote here that *this port mints no globalThis symbol (§3.11)*, and
// slice 104 mints it: the arm ANSWERS now, out of the resolvedType initialize_checker
// assigns eagerly. What is left of the wall is the PRINTER — an anonymous object
// type with a module symbol is `typeof globalThis` upstream and `type-to-string`
// here — so the THISPIN's name column reads `?` where its arm column reads 6.
const a = this

// A `this` in the constructor of a DERIVED class needs classDeclarationExtendsNull,
// whose third call reports `is-constructor-type` for exactly a class that has a
// base — so TS17009 is unreachable behind a stop two lines above the report rather
// than behind an argument.
class Base { x: number = 1 }
class Derived extends Base {
    constructor() {
        super()
        this.x = 2
    }
}
