// The positive control for the whole lookup chain — namespace, exports, Element,
// IntrinsicElements. `div` is a NAMED property, so getIntrinsicTagSymbol takes its
// named arm, TS7026 does not fire, and the element's type is JSX.Element rather
// than the errorType the rest of this corpus answers.
declare namespace JSX {
    interface Element { readonly brand: "jsx" }
    interface IntrinsicElements { div: {} }
}
const ok = <div />;
