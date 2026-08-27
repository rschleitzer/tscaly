// SLICE 82: the second term of the reference's guard, `IsMethodSignatureDeclaration`,
// and the one arm that walks OUT of the chapter with a type in hand. A method
// signature has no body at all, so the flow graph is never asked — 24 units of the
// old row were exactly this shape.
interface WithSignature {
    m(x: number): number;
}
