// A label nothing references is marked NodeFlagsUnreachable on the LABEL node —
// the binder's mark, which the checker turns into TS7028. A referenced one is
// not, and a label on a plain block has no continue target at all.
function labels(n: number) {
    used: while (n > 0) {
        n--;
        if (n === 1) break used;
    }
    unused: while (n < 10) {
        n++;
    }
    block: {
        if (n === 5) break block;
        n = 6;
    }
    return n;
}
