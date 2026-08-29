// A branch label whose antecedents agree. getTypeAtFlowBranchLabel's early-out
// -- "if the type at a particular antecedent path is the declared type and the
// reference is known to always be assigned, there is no reason to process more
// antecedents" -- is what keeps the union out of this shape.
function branches(p: number, q: boolean) {
    let n: number = p;
    if (q) {
        n = 1;
    } else {
        n = 2;
    }
    let a = n;
    if (q) {
        n = 3;
    }
    let b = n;
    return a;
}
