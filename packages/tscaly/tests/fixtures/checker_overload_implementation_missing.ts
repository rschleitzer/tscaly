// ★★ THE SIMPLEST SHAPE THAT REACHES reportImplementationExpectedError, and it
// reaches it from the SECOND of the two call sites: the loop leaves
// lastSeenNonAmbientDeclaration pointing at a body-less, non-abstract,
// non-optional declaration, and the block after the loop reports on it. Nothing
// follows the declaration, so subsequentNode is nil and the report lands on the
// NAME (TS2391).
function f(a: string): void;
