// The reduce label: a finally block is reached five ways and an analysis walking
// PAST it may consider only two, so the reference injects a node carrying an
// alternate antecedent list. All three shapes are here — try/catch,
// try/finally and try/catch/finally — plus the one whose end is unreachable.
function tryCatch(n: number) {
    try {
        n = 1;
    } catch (e) {
        n = 2;
    }
    return n;
}

function tryFinally(n: number) {
    try {
        return 1;
    } finally {
        n++;
    }
}

function tryCatchFinally(n: number) {
    try {
        n = 1;
    } catch (e) {
        return 2;
    } finally {
        n = 3;
    }
    return n;
}

function finallyEndsUnreachable() {
    try {
        return 1;
    } finally {
        throw new Error();
    }
}
