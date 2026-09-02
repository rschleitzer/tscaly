// getNameFromJsxElementAttributesContainer's error arm, TS2608, reached through the
// CHILDREN container rather than through the attributes one — which is the half
// this port can reach, because getJsxElementChildrenPropertyName is asked by
// createJsxAttributesTypeFromAttributesProperty on every element.
declare namespace JSX {
    interface Element { readonly brand: "jsx" }
    interface ElementChildrenAttribute { kids: {}; more: {} }
    interface IntrinsicElements { div: {} }
}
const a = <div />;
