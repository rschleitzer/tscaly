// Slice 96's three walls, one shape each, so the work list can price them apart.
//
//   the optional CHAIN            `check-property-access-chain`
//   the PRIVATE identifier        `check-private-identifier-property-access`
//   a name that is NOT a member   `global-object-property-augment` and then
//                                 `report-nonexistent-property`
//
// The last pair is this chapter's own statement about §3.11: a name absent from
// the members table cannot be REPORTED absent without `globalObjectType`, so the
// reference's whole second half sits behind one lib type. The reference reports
// TS2339 on `missingMember` and this port does not, which is a LOSS and therefore
// a legal subsequence — the yardstick's half, not diagcheck's.
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
