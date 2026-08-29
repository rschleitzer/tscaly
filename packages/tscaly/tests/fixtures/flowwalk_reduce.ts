// The reduce label a `try`/`finally` builds: the label whose antecedent list is
// temporarily replaced while the finally block is analysed, and the stack that
// makes a nested `try` resolve to the INNER push.
function reduced(p: string) {
    let s: string = p;
    try {
        s = "a";
        try {
            s = "b";
        } finally {
            let inner = s;
        }
    } finally {
        let outer = s;
    }
    return s;
}
