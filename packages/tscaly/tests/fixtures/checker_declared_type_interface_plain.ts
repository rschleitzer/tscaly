// The 1 411-unit shape: an interface with neither type parameters nor a heritage
// clause. It is the only shape in this slice that reaches isThislessInterface,
// and the answer is true — no `this` in the body, no bases — so the interface
// gets NO `this` type and its declared type carries no ObjectFlagsReference.
interface I {
    a: string;
}
