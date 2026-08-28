// SLICE 86. The Reference arm taken by an INTERFACE rather than by a class, which
// is the half of it slice 85's non-generic interface could not reach: a generic
// interface is given a thisType too, so allTypeParameters is [T, thisType] against
// the padded [T, I] and it resolves through resolveTypeReferenceMembers exactly as
// a class does. The parameter is unused on purpose — a `T` in member position is a
// TypeReference node and stops in §3.11's globals table before the members are
// asked for at all.
interface I<T> {
    [k: string]: string;
}
