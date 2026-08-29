// Slice 97: the two walls, each written so the file reaches it and nothing else.
//
// A `this` at the top level of a SCRIPT is `getTypeOfSymbol(globalThisSymbol)`, and
// this port mints no globalThis symbol (§3.11) — so this file is deliberately NOT a
// module, which is the one fixture of this slice that must not carry `export {}`.
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
