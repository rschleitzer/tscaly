// checkPropertyInitialization: the head of the work list from slice 77 to slice
// 94. A non-static property with no initializer, whose type does not admit
// undefined, in a class whose constructor does not definitely assign it -- TS2564
// on the property NAME.
class NoCtor {
    a: string;
    b: number;
}
class CtorMisses {
    c: string;
    constructor() {
    }
}
class Declared {
    d!: string;
    e: string = "x";
    f?: string;
    g: string | undefined;
    static h: string;
}
declare class Ambient {
    i: string;
}
abstract class WithAbstract {
    abstract j: string;
}
