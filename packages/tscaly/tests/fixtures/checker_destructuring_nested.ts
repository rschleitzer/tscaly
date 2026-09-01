// Slice 117 — a NESTED pattern, where the parent of a binding element is another
// binding element rather than a variable declaration.
//
// ★★ getTypeForBindingElementParent then recurses through
// getTypeForVariableLikeDeclaration on the OUTER element, so the inner element's
// type is an indexed access over an indexed access. The cached resolvedType path
// is what keeps that from being quadratic, and it is read only under
// CheckModeNormal.
declare const src: { outer: { inner: number; other: string } };
const { outer: { inner, other } } = src;
