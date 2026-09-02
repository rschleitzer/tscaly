// checkJsxExpression's own report, TS2609 — a `{...x}` CHILD whose type is neither
// any nor an array. It is the one diagnostic in this chapter that belongs to the
// expression rather than to the element.
declare namespace JSX {
    interface IntrinsicElements { div: any }
}
declare const n: number;
const a = <div>{...n}</div>;
