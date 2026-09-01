// Slice 104: what a MODULE gets out of the table, which is not its own names.
//
// initializeChecker merges the locals of NON-module files only, so `local` below is
// still found by resolve_name's walk exactly as before. What is new here is the two
// symbols NewChecker seeds regardless of the file: `undefined`, whose type is
// assigned in the same run, and `globalThis`.
//
// The TS2322 is the whole slice in one line — it needs the seeded symbol, the
// table, the eager resolvedType assignment and the assignability relation, and
// before this slice the initializer stopped at `resolve-name-not-found` instead.
export {}
var local: number = 1
var fromWalk: number = local
var fromTable: number = undefined
var alsoTable = globalThis
