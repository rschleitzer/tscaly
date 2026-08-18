// The twin of parser_import_meta_module.ts, and it gates the NAME half of
// IsImportMeta: the flag IS set — `import.metal` sets it, being neither `defer`
// nor a call — so the walk RUNS and has to answer no. Get the name test wrong
// and this file becomes a module, `await` becomes an AwaitExpression, and the
// tree differs.
//
// ★ The KEYWORD half is NOT gated here, and a control is what said so:
// `new.target` fails the name test anyway, so breaking the keyword changed
// nothing. It lives in parser_import_meta_new_meta.ts, where the name agrees.
const m = import.metal;
function f() { return new.target; }
const a = await;
