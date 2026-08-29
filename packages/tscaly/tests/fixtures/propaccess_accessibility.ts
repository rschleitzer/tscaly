// Slice 96 — checkPropertyAccessibility, whose fourth test is the exit almost
// every access in the corpus takes and whose PRIVATE arm is the one this slice
// finishes. The reports carry `symbolToString` arguments upstream; this port's C
// section is `pos end code`, so the code and the span are the whole diagnostic.
export {}

class WithPrivate {
    private secret: number = 1
    protected shared: number = 2
    public open: number = 3
}

// TS2341 — private and only accessible within the class.
function outsidePrivate(w: WithPrivate) {
    return w.secret
}

// Inside the declaring class the same access is allowed, which is what makes the
// report above a claim about the LOCATION rather than about the member.
class InsidePrivate extends WithPrivate {
    read(): number {
        return this.open
    }
}

// The public member never reaches the accessibility half at all.
function outsidePublic(w: WithPrivate): number {
    return w.open
}
