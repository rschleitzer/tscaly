// getNameFromJsxElementAttributesContainer's THIRD answer, TS2608: a container with
// more than one property is an error, reported on the container's own declaration.
declare namespace JSX {
    interface ElementAttributesProperty { props: any; other: any }
    interface IntrinsicElements { div: any }
}
declare class C { props: { a: number } }
const a = <C />;
