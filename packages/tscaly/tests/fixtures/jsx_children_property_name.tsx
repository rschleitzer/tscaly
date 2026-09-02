// getJsxElementChildrenPropertyName's ONE-property answer: with
// JSX.ElementChildrenAttribute declaring `kids`, an attribute of that name is the
// one createJsxAttributesTypeFromAttributesProperty compares its children against.
// Here there are no children, so the comparison does not run and what the fixture
// pins is the NAME lookup itself.
declare namespace JSX {
    interface Element { readonly brand: "jsx" }
    interface ElementChildrenAttribute { kids: {} }
    interface IntrinsicElements { div: {} }
}
const a = <div />;
