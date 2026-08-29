// Slice 98: the call site where the thisArgument is NULL and the function has to
// take one from the target itself — `arg = thisType(target)`. It is reached from
// the class and interface checks, which re-anchor the DECLARED type of the class
// they are checking before comparing it against its base.
//
// ★ It is a fixture of its own because the two halves are independent: the caller
// decides whether an argument arrives, and the function decides what to do when
// none does. A control that drops the fallback leaves every other call site right.
export {}

class Base {
    x: number = 1
}

class Derived extends Base {
    y: number = 2
}

interface IBase {
    a: number
}

interface IDerived extends IBase {
    b: number
}
