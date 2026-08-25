// Slice 65. getEffectiveDeclarationFlags' two AMBIENT terms, and this file measures
// them in OPPOSITE DIRECTIONS — which is why they are one fixture.
//
// ★★★ INSIDE `declare module "m"` NOTHING REPORTS, and that is the term working.
// An ambient export context makes every declaration in it an export without an
// `export` keyword, so `export interface I {}` and `interface I {}` are two exports
// and their spaces never meet. Remove `flags |= ModifierFlagsExport` and this pair
// INVENTS TS2395 twice — a report the reference does not make, which is the only
// direction diagcheck can see.
//
// ★★★ INSIDE `declare global` THE SAME PAIR DOES REPORT, and that is the fourth
// conjunct working. `!(IsModuleBlock(n.Parent) && IsGlobalScopeAugmentation(n.Parent.Parent))`
// exempts a global augmentation's body from the implicit export, so `G` really is
// one export and one local and TS2395 fires twice. Drop the exemption and both
// reports disappear. **One term is measured by a report that must not appear and
// the other by one that must, four lines apart in the same function.**
//
// ★★ THE TWO TS2669s ARE NOT THIS SLICE'S AND ARE THE REASON THE FILE IS A SCRIPT.
// `declare global` at the top level of a non-module file is *augmentations for the
// global scope can only be directly nested in external modules or ambient module
// declarations* — checkModuleDeclaration's last arm, ported in this slice too, and
// it is what fixes the file's shape: add an `export {}` and the global blocks stop
// reporting and `is_global_source_file` stops being exercised.
//
// ★ The third block is the negative control for the second: `H` is declared twice
// with no `export` at all, so both declarations are local either way and the
// exemption cannot be seen in it.
declare module "m" {
    export interface I {}
    interface I {}
}
declare global {
    export interface G {}
    interface G {}
}
declare global {
    interface H {}
    interface H {}
}
