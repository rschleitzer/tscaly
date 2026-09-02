// checkJsxAttribute's second line: `<div hidden />` is sugar for `hidden={true}`,
// so the attribute's type is the TRUE literal and not boolean.
declare namespace JSX {
    interface Element { readonly brand: "jsx" }
    interface IntrinsicElements { div: any }
}
const a = <div hidden />;
