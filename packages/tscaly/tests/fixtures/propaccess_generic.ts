// Slice 96 — the property access whose RECEIVER IS A TYPE REFERENCE, and the
// fixture that exists because stage 2 found what stage 1 and six other fixtures
// could not.
//
// ★★★ `b.foo` on a `B<string>` exited 21 — a null unwrapped as ref inside
// set_structured_type_members — until the Reference arm of TypeData was given the
// `resolved` slot every other object arm already had. Upstream one embedded
// StructuredType serves every object type; here the arms are split, and the arm
// nothing had ever asked for members was missing the slot. The failure had no
// source location and no diagnostic, which is what exit 21 is for.
//
// ★ The member is answered through the INSTANTIATION: `foo: T` on `B<string>`
// answers `string`, and the PROPPIN's symbol-flags column shows the transient
// (instantiated) member rather than the declared one.
export {}

interface B<T> {
    foo: T
    bar: string
}

function readGenericMember(b: B<string>) {
    return b.foo
}

function readPlainMemberOfGeneric(b: B<number>): string {
    return b.bar
}
