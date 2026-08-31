// Slice 113: checkAndReportErrorForExportingPrimitiveType, whose guard is an
// ExportSpecifier — so the fixture has to be a MODULE, where the file's own
// locals are not merged into globals at all.
export { string };
export {};
