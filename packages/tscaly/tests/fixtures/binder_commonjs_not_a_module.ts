// slice 37 — setCommonJSModuleIndicator's GUARD. A file that is already an ES
// module has an external module indicator, so `module.exports = 1` there
// declares NOTHING: the arm returns before it reaches the exports table, and the
// two CommonJS locals are never declared either.
//
// This is also the one place the split between IsExternalModule and
// IsExternalOrCommonJSModule can be seen from the outside — the file has a module
// symbol because of the `export`, not because of the assignment.
// @Filename: esm.js
export const x = 1;
module.exports = 2;
exports.y = 3;
