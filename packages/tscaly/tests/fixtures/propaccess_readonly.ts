// Slice 96 — isAssignmentToReadonlyEntity, and the assignment kind is what puts
// it on the path: its first line answers false for every READ, so the two
// getResolvedSymbol calls below it are never asked about an ordinary access.
export {}

interface Frozen { readonly r: number; w: number }

// TS2540 — cannot assign to a read-only property.
function writeReadonly(f: Frozen) {
    f.r = 1
}

// The writeable neighbour is the control: same shape, same assignment kind, no
// report — so the row above measures `readonly` and not `assignment`.
function writeWriteable(f: Frozen) {
    f.w = 1
}

// A compound assignment is AssignmentKindCompound rather than Definite, which is
// the fork getFlowTypeOfAccessExpression reads first.
function compoundWrite(f: Frozen) {
    f.w += 1
}
