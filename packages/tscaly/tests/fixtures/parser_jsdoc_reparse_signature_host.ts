// Slice 22 — getFunctionLikeHost answers a SIGNATURE MEMBER, which is the one
// path through it that does not go via an initializer: `fun` stays the
// documented node itself and IsFunctionLikeKind is asked of a method signature,
// a call signature, a construct signature or an index signature. A `.js` file
// may contain an `interface` — badly, and checkJSSyntax says so, but it parses —
// so all four are reachable hosts, and the tags that write a VISIBLE slot on
// them are @template, @param, @this and @returns.
// @Filename: sig.js
interface I {
    /** @template U */
    m(): void

    /** @param {string} a */
    n(a): void

    /** @returns {number} */
    o()

    /** @this {string} */
    p(): void
}

type T = {
    /** @template U */
    (): void

    /** @template U */
    new (): void

    /** @param {string} k */
    [k: string]: number
}
