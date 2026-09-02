// resolveJsxOpeningLikeElement's `len(signatures) == 0` arm, TS2604, at the TAG
// NAME. A number has neither a construct nor a call signature, so the element type
// is not callable at all.
declare namespace JSX {
    interface Element { readonly brand: "jsx" }
}
declare const C: { x: number };
const a = <C />;
