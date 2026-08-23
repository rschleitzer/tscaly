// Slice 58, and it is a report the slice UNBLOCKED rather than ported: TS1194 at
// the BOTTOM of checkExportDeclaration, reached for the first time because the
// specifier-loop tag stopped returning.
//
// ★★★ THE TWO TS1194s OF THIS FAMILY ARE DIFFERENT LINES WITH THE SAME CODE. One
// is checkExternalImportOrExportDeclaration's, on the module NAME, for
// `export { x } from "m"` in a namespace — checker_import_in_namespace.ts has
// that one. This is the other: no specifier, so the external check is never
// asked, the clause loop stops at checkExportSpecifier, and the report below it
// lands on the whole NODE. Before this slice the arm returned at that loop and
// the report was unreachable; record_unported marks and continues now, which is
// what makes the span the witness — the two are the same code and never the same
// span.
//
// ★★ THE AMBIENT NAMESPACE IS THE OTHER HALF and it must stay silent:
// `inAmbientNamespaceDeclaration` permits exactly this shape in a `declare
// namespace`, and it is the one of the three permitting bools that a plain
// namespace does not get.
namespace N {
    let x = 1;
    export { x };
}

declare namespace M {
    const y: number;
    export { y };
}
