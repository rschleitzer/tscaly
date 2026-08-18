// Slice 20 — the namespaced name, in both positions it can occur, plus the one
// rule that makes it a separate node rather than a colon in a name:
// `<a:b.c>` does NOT continue into the dot. parseJsxElementName returns as soon
// as it has a JsxNamespacedName, deliberately, so that the `.` is reported by the
// attribute list instead — `a:b.c` is not valid syntax and the reference chooses
// where to say so.
// @Filename: namespaced.tsx
const a = <a:b></a:b>;
const b = <a:b />;
const c = <div x:y="1" />;
const d = <a:b.c></a:b>;
