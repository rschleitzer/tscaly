// slice 37 — the three remaining EXTERNAL-only readings, in a file that is a
// CommonJS module and nothing else.
//
//   the dotted @typedef synthesizes a ModuleDeclaration, which is declared
//   through declareSourceFileMember — `IsExternalModule`, so it lands in the
//   file's LOCALS and not in its exports, even though the same predicate read as
//   the disjunction would make it implicitly exported
//
//   `export as namespace` reports "may only appear in module FILES" here, which
//   is the arm before the declaration-file one: widen the test and the message
//   number changes rather than disappearing
//
//   `declare module "m" {}` at top level is an AUGMENTATION only when the file
//   is an external module — IsModuleAugmentationExternal — so here it declares a
//   module of its own instead
// @Filename: extonly.js
exports.a = 1;
/** @typedef {string} Ns.Alias */
export as namespace X;
declare module "m" {}
