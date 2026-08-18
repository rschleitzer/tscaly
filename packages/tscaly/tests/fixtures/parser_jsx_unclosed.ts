// Slice 20 — parseJsxChild's EndOfFile arm, which is the one place the report is
// deliberately NOT at the position the parser is at: the end of a file is useless
// information, so the span covers the unclosed TAG NAME instead.
//
//   element   JSX_element_0_has_no_corresponding_closing_tag (17008), on `div`
//   fragment  JSX_fragment_has_no_corresponding_closing_tag (17014), on the whole
//             opening fragment rather than on a name it does not have
//   fragclose `<>…</div>` — the closing token is there but it is not `>`, which is
//             the fragment's own message,
//             Expected_corresponding_closing_tag_for_JSX_fragment (17015)
// @Filename: element.tsx
const a = <div>
// @Filename: fragment.tsx
const b = <>
// @Filename: fragclose.tsx
const c = <>text</div>;
// @Filename: spaced.tsx
// ★ The one unit with TRIVIA between `<` and the tag name, which is the only way
// the trivia skip in the report's start can matter — the reference's own comment
// names this shape: "We want the error span to cover only 'Foo.Bar' in
// < Foo.Bar >". Without it that skip is UNGATED, and the verdict is UNCOVERED
// rather than unreachable (§3.5v).
const d = < div.sub >
