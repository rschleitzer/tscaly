// Slice 110: the `export =` half of checkExternalModuleExports — an export
// assignment in a module that also exports values (TS2309), plus TS1203 for an
// export assignment under an ES module target.
declare const thing: number
export = thing
export const other = 1
