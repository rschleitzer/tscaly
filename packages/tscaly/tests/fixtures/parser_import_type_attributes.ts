// `with { … }` inside the parentheses — the caller parseImportAttributes has
// carried its `skipKeyword` parameter for, unused, since slice 8. Inside
// `import(…)` the clause is `, with: { … }`, so the keyword and the colon are
// read by parseImportType and the brace by parseImportAttributes.
type A = import("m", { with: { type: "json" } });
type B = import("m", { with: { type: "json" }, });
type C = import("m", { with: {} });
