// Slice 20 — the two mismatch reports, which differ in WHOSE fault the parser
// decides it is.
//
//   plain    `<div></span>` — nobody else's tag matches, so the CLOSING tag is
//            blamed: Expected_corresponding_JSX_closing_tag_for_0 (17002)
//   nested   `<div><span></div>` — the closing tag matches the PARENT's opening
//            tag, so it is the inner OPENING tag that is unclosed:
//            JSX_element_0_has_no_corresponding_closing_tag (17008), reported on
//            `span`
//
// ★ The nested unit is also the only fixture that reaches the RESTRUCTURING path:
// parse_jsx_children stops after the mismatched child, the caller hands the
// `</div>` back to the outer element and gives `<span>` a zero-width missing
// closing tag at the end of its own children. Two synthesized nodes appear in the
// tree that no text produced — an Identifier and a JsxClosingElement, both of
// width 0 — and the outer element's closing tag is the one the inner element had
// already parsed. Nothing is reported for the repair itself.
// @Filename: plain.tsx
const a = <div></span>;
// @Filename: nested.tsx
const b = <div><span></div>;
// @Filename: deep.tsx
const c = <div><span><b>text</div>;
