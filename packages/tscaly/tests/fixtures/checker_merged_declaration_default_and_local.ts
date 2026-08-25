// Slice 65. A merge that lands in BOTH intersections at once, which is the only
// shape that can measure the ORDER of the two reports.
//
// ★★★ checker_merged_declaration_default_export.ts CANNOT SEE THE ORDER. There the
// exported accumulator is empty, so `commonDeclarationSpacesForExportsAndLocals` is
// zero and swapping the two `if`s changes nothing — the first fixture written for
// the report tested the report and not the choice. Here all three accumulators are
// non-empty: the default export contributes Type|Value, the exported namespace
// Namespace|Value and the local namespace Namespace|Value, so a namespace
// declaration's spaces meet the default intersection AND the exports-and-locals
// one. The reference answers TS2652 for all three declarations, six reports over
// two runs — so with the order swapped every one of them becomes TS2395.
//
// ★★ SIX REPORTS FROM THREE DECLARATIONS, and that is the once-guard again: the
// class and the namespaces are different KINDS, so the first of each runs the whole
// reporting loop and each run reports on all three.
export default class C {}
export namespace C { export var a = 1; }
namespace C { export var b = 2; }
