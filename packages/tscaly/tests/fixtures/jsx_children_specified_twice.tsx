// createJsxAttributesTypeFromAttributesProperty's own report, TS2710 — an explicit
// `children` attribute beside real children, where JSX.ElementChildrenAttribute
// names `children`. It is the one place the attributes type and the CHILD list meet.
declare namespace JSX {
    interface ElementChildrenAttribute { children: any }
    interface IntrinsicElements { div: any }
}
declare const f: any;
const a = <div children={f}>text</div>;
