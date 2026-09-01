// Slice 110, row g04's input: the shape that caught the once-bit defect. TS2309 is
// reported by checkExternalModuleExports, which BOTH checkExportAssignment and the
// source-file worker call — and `a` being undeclared is what makes get_symbol_flags
// stop inside has_exported_members_of_kind, so a once-bit written at the reference's
// place (the end of the function) is skipped and the second caller reports again.
export default 1;
export = a;
export as namespace N;
