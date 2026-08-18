// Slice 20 — the JSX grammar's three shapes and the child kinds, which is the
// baseline for everything else in this family.
//
//   self       parseJsxOpeningOrSelfClosing... takes the `/` branch and the
//              opening node IS the result — no children, no closing tag
//   element    the opening/children/closing triple
//   dotted     a tag name is a PropertyAccessExpression chain, built by
//              parseJsxElementName rather than by the expression ladder
//   this       `<this>` is a KeywordExpression, not an identifier named `this`
//
// The child kinds are all here too: JsxText, JsxExpression, a nested element and
// a nested self-closing element.
// @Filename: element.tsx
const a = <div />;
const b = <div></div>;
const c = <div>hello</div>;
const d = <div>{value}</div>;
const e = <div><span>inner</span></div>;
const f = <div><br /></div>;
const g = <a.b.c></a.b.c>;
const h = <this></this>;
const i = <div>before{x}after<span /></div>;
const j = <div>{...items}</div>;
const k = <div>{}</div>;
