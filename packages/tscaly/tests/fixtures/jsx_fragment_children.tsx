// checkJsxFragment, whole: the opening fragment is checked, the children are walked
// and the answer is JSX.Element — or `any` when the element type is an error, which
// is the arm the rest of this corpus takes.
declare namespace JSX {
    interface Element { readonly brand: "jsx" }
    interface IntrinsicElements { div: any }
}
const a = <><div />text{1}</>;
