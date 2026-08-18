// Slice 20 — the fragment, which is its own three nodes (JsxOpeningFragment,
// JsxFragment, JsxClosingFragment) and the reason those two are `Token` arms with
// no record: `<>` and `</>` carry no field and no child.
// @Filename: fragment.tsx
const a = <></>;
const b = <>text</>;
const c = <>{value}</>;
const d = <><span /><span /></>;
const e = <div><></></div>;
const f = <><div>a</div>b</>;
