// The KEYWORD half of IsImportMeta, and the file exists because a control found
// its absence: `new.meta` is a MetaProperty whose NAME is `meta` and whose
// keyword is `new`, so it is the only shape in which the keyword test is the one
// that decides. The flag is set by `import.metal`, so the walk runs; it must
// still answer no, and this file must therefore NOT be re-parsed as a module.
const m = import.metal;
function f() { return new.meta; }
const a = await;
