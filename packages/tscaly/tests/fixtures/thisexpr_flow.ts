// Slice 97: `this` is a NARROWABLE reference, so both answering paths end in
// getFlowTypeOfReference — the two-argument entry slice 93 left for its first
// caller. The declared type is the walk's starting point and not its answer.
export {}

class C {
    x: number = 1

    m(): number {
        if (this.x) {
            return this.x
        }
        return 0
    }
}

interface Point { x: number }

function withThis(this: Point | undefined): number {
    if (this) {
        return this.x
    }
    return 0
}
