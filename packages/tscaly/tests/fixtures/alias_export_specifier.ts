// Slice 110: checkExportSpecifier — the non-local export report (TS2661) and the
// string-literal module export name, with the reference-marking walk beside them.
export {}
const value = 1
type Only = number
export { value }
export { Only }
export { value as "string name" }
export { undefined as u }
