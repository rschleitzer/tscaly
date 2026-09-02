// scanner.IsIntrinsicJsxName's SECOND disjunct: a tag name containing a hyphen is
// intrinsic whatever its case, so `<My-Widget />` is looked up in
// JSX.IntrinsicElements rather than resolved as a component reference.
// ★The initial must be UPPERCASE or the row measures nothing — a lowercase
// `my-widget` is already intrinsic through the FIRST disjunct, which is what g14
// measured on the battery's second run.
declare namespace JSX {
    interface Element { readonly brand: "jsx" }
    interface IntrinsicElements { "My-Widget": {} }
}
const a = <My-Widget />;
