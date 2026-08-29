// Everything after a return, a throw, a break or a continue is unreachable, and
// the binder marks it. A `var` list with no initializer is NOT potentially
// executable and carries no mark; a `let` always is, and a `var` with one is.
function afterReturn(): number {
    return 1;
    var hoisted;
    var initialized = 2;
    let scoped = 3;
    class C {}
    enum E { A }
    namespace N { let q = 1; }
    hoisted;
}

function afterThrow(): never {
    throw new Error();
    afterThrow();
}

function afterBreak(n: number) {
    while (true) {
        break;
        n++;
    }
}
