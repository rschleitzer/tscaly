// Slice 54. The `__esModule` marker term, whose whole interest is that it is
// REACHABLE.
//
// ★★★ ITS FIRST CONJUNCT IS A CONSTANT TRUE UNDER THIS HARNESS, AND THE VALUE
// COMES FROM THE ORACLE'S STUB PROGRAM RATHER THAN FROM AN OPTION'S DEFAULT.
// `program.GetEmitModuleFormatOfFile` answers ModuleKindNone = 0 there, and the
// guard is `< ModuleKindSystem` = 4. The REAL compiler answers ModuleKindES2022
// = 7 for an unset `module` at ES2025, and `7 < 4` is false — so reading
// internal/compiler/program.go instead of tests/oracle/types.go would have got
// this exactly backwards and buried a live report behind a hole that is not
// there.
//
// ★★★ THE SECOND LINE IS THE NEGATIVE HALF AND IT IS ABOUT WHICH NODE IS ASKED:
// the walk reads a binding element's NAME, so `{ __esModule: q }` asks about `q`
// and says nothing. The third line is the same walk one kind along, where an
// array pattern's element name IS the marker.
//
// ★ The reference also reports TS2323 on the first and third lines (a redeclared
// export) — a semantic diagnostic of a dimension this port has none of, which is
// what a SUBSEQUENCE relation is for.
export var __esModule = 1;
export var { __esModule: q } = { __esModule: 1 };
export var [__esModule] = [1];
