// The four iteration statements, each with the label family that makes its
// continue target observable: a `continue` inside a labelled loop points the
// label's continue target at the loop's own, which setContinueTarget does.
function loops(xs: number[], n: number) {
    while (n > 0) {
        n--;
        if (n === 3) continue;
        if (n === 1) break;
    }
    do {
        n++;
    } while (n < 10);
    outer: for (let i = 0; i < n; i++) {
        inner: for (const x of xs) {
            if (x === 1) continue outer;
            if (x === 2) break inner;
        }
    }
    for (const k in xs) {
        k;
    }
    for (;;) {
        break;
    }
}
