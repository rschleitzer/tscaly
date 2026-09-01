// Slice 104: the UMD half of the merge — `file.GlobalExports`, first-in-wins.
//
// The table is filled only by `export as namespace` and only in a DECLARATION file
// that is an external module (binder.go's bindNamespaceExportDeclaration errors on
// every other placement). Its one reader is block 2 of
// on_successfully_resolved_symbol, TS2686, which the reference produces here.
//
// ★ This file is the measurement that says the merge has no observable product at
// stage 1 yet, and WHY that is an argument rather than an omission: a value-position
// reference is the shape that reaches resolve_name, a declaration file has no value
// expressions, so the only route left is a TYPE QUERY — and that is one stop away,
// `get-type-from-type-query-node`.
export as namespace UMD
export declare var v: number
declare var use: typeof UMD
