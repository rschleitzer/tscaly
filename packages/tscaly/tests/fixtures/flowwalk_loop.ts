// A loop label with a real back edge. The SINGLE-antecedent label is collapsed
// by the dispatch and never reaches getTypeAtFlowLoopLabel; these do.
function loops(p: number, n: number) {
    let acc: number = p;
    while (n > 0) {
        acc = acc + n;
        n = n - 1;
    }
    let a = acc;
    for (let i = 0; i < 3; i++) {
        acc = i;
    }
    let b = acc;
    return a;
}
