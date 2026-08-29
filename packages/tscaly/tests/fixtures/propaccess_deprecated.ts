// Slice 96 — the deprecation branch, and why it may not be a row: a stop here
// would fire on every property access in the corpus and take the chapter's whole
// product with it. So the three terms are asked in the reference's order and
// `isDeprecatedSymbol` answers false for anything without the tag, which is every
// member below but one.
//
// The suggestion this produces is a COUNT here (slice 70's `suggestion_count`),
// not a line: no artifact in this directory compares a suggestion.
export {}

interface Tagged {
    /** @deprecated use `fresh` */
    stale: number
    fresh: number
}

function readDeprecated(t: Tagged): number {
    return t.stale
}

function readFresh(t: Tagged): number {
    return t.fresh
}
