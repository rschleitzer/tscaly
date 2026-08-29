// Slice 96 — checkQualifiedName, the SECOND head, which ends in the same function
// as the first.
//
// ★★★ IT IS LIVE CODE WITH NO INPUT IN THIS CORPUS, AND THE FIXTURE IS HERE TO
// SAY SO RATHER THAN TO HIDE IT: `check-qualified-name` was **0 events over 0
// units** at stage 1 before this slice, because a QualifiedName reaches
// checkExpression only from shapes whose own chapter stops first — the entity
// name of an `import x = A.B` goes through resolveEntityName, and `typeof Q.value`
// is a TypeQuery whose arm is not ported. The two shapes below are exactly those
// two, and each stops at its own chapter's wall.
//
// ★ It is transcribed anyway because the two heads are ONE function below their
// first three lines, and a head that is missing when its input arrives is a
// silent wrong answer rather than a stop.
export {}

declare namespace Q {
    interface Inner { a: number }
    const value: number
}

import Alias = Q.Inner

declare const t: typeof Q.value

function useAlias(x: Alias): number {
    return x.a
}
