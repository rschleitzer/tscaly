// checkGrammarJsxExpression, TS18007 — the whole of it. A comma sequence inside a
// JSX expression is almost always a mistyped array.
// ★The comma must NOT be parenthesised: ast.IsCommaExpression asks the JsxExpression's
// own expression, and a ParenthesizedExpression is not one. The first draft of this
// fixture wrapped it and reached nothing, which is what g18 measured.
declare namespace JSX {
    interface IntrinsicElements { div: any }
}
declare const p: number;
declare const q: number;
const a = <div>{p, q}</div>;
