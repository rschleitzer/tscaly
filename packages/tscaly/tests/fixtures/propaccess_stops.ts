// Slice 96's three walls, one shape each, so the work list can price them apart.
//
//   the optional CHAIN            `check-property-access-chain`
//   the PRIVATE identifier        `check-private-identifier-property-access`
//   a name that is NOT a member   ANSWERED since slice 127
//
// ★ The third row was `global-object-property-augment` and then
// `report-nonexistent-property` until slice 127, and its note was this chapter's
// statement about §3.11: a name absent from the members table cannot be REPORTED
// absent without `globalObjectType`. The augment landed, so the port now emits the
// same TS2339 on `missingMember` that the reference does — the row is kept because
// it is the POSITIVE control for the other two.
//
// ★ The private access is written through a PARAMETER rather than through `this`,
// deliberately: `this.#hidden` stops at checkThisExpression one call earlier and
// would price the successor instead of this row.
export {}

interface Small { a: number }

function optionalChain(s: Small | undefined) {
    return s?.a
}

class Priv {
    #hidden: number = 1
    read(other: Priv): number {
        return other.#hidden
    }
}

function missingMember(s: Small) {
    return s.zzz
}
