// Slice 20 — every arm of parseJsxAttribute / parseJsxAttributeValue.
//
// ★ The valueless attribute is the one that makes the Initializer slot's null
// real: `<a disabled />` has an attribute with ONE child, and the child count is
// what the tree dump compares.
//
// ★ The string value is scanned by ScanJsxAttributeValue as a JSX ATTRIBUTE
// string, which is not the ordinary string scan: a backslash is an ordinary
// character there and a line break does not terminate the literal. Both are
// below, and both would be a diagnostic under the ordinary rules.
// @Filename: attributes.tsx
const a = <input disabled />;
const b = <input type="text" />;
const c = <input type='text' />;
const d = <input value={v} />;
const e = <input label=<b /> />;
const f = <input {...props} />;
const g = <input data-testid="x" aria-label="y" />;
const h = <input x:y="ns" />;
const i = <input title="a\b\n not an escape" />;
const j = <input title="first
second" />;
const k = <input a="1" b={2} c {...r} d='3' />;
// The space around `=` is what ScanJsxAttributeValue skips itself, so that
// token_start lands on the opening quote rather than on trivia.
const l = <input type = "spaced" />;
// @Filename: spreadvalue.tsx
// ★ `{...x}` as an attribute VALUE, which is NOT the spread attribute one line
// up: parse_jsx_attribute_value routes into parse_jsx_expression with
// in_expression_context = true, and that is what stops the DotDotDot token from
// being read there. So the `...` has to be parsed as part of an expression, and
// the reference reports it. The child form, `<div>{...items}</div>`, is in
// parser_jsx_element.ts and takes the other branch of the same `if`.
const m = <input v={...x} />;
