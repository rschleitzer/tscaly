// Slice 97: the two producers that are NOT the dispatcher. `typeof this.a` parses
// its head as an EntityName, so the node is a KindIdentifier whose text is `this`
// and not a ThisKeyword — checkIdentifier's isThisInTypeQuery line is one producer
// and checkQualifiedName's `IsPartOfTypeQuery && IsThisIdentifier` fork is the
// other. Nothing in this chapter tests the node's kind, which is what lets both
// spellings walk the same path.
//
// ★★★ BOTH ARE UNREACHABLE TODAY AND THE PROOF IS THIS FILE'S STOP LOG:
// `get-type-from-type-query-node` fires one call in front of either of them, so
// neither producer has an input — the same shape slice 96's h02 recorded for
// `check-qualified-name`, and the same shape the arrival detail proves from the
// other side (all 103 stage-1 arrivals were the ThisKeyword). They are wired
// anyway, because the day the type query lands is the day both come alive and a
// stop left standing there would read as an unported chapter.
export {}

class C {
    a: number = 1

    m(): void {
        let t: typeof this.a
    }

    n(): void {
        let u: typeof this
    }
}
