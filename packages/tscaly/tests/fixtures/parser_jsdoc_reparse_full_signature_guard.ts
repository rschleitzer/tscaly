// Slice 22 — the `full_signature` slot on a SIGNATURE MEMBER, which is the one
// stored field of this slice that `child_at` deliberately does not visit,
// because the reference's ForEachChild for these four kinds does not either.
// Its ONE reader is the guard in the @template / @param / @returns arms.
//
// So the tag that FILLS it produces nothing visible at all, and the only way to
// see it is through what it SUPPRESSES on a neighbouring tag — §3.5ao's rule
// used as a fixture design rather than as a warning:
//
//   m()  @type fills the slot, so the @template beside it is dropped
//   n()  no @type, so the same @template DOES give a type parameter
//
// Take the slot away and m() grows a <U>, which is control c45.
// @Filename: guard.js
interface I {
    /**
     * @type {(a: string) => void}
     * @template U
     */
    m()

    /**
     * @template V
     */
    n()
}
