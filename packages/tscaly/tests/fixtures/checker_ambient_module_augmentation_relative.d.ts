// Slice 58, and the negative half of checker_ambient_module_relative_import.d.ts
// — the SAME statements in a file that IS an external module, where TS2439 is
// suppressed.
//
// ★★★ THE SUPPRESSION IS NOT A CONDITION, IT IS A DEDUPLICATION, and the
// reference's own comment says so: *we have already reported errors on top level
// imports/exports in external module augmentations in checkModuleDeclaration, no
// need to do this again*. So "nothing here" is the right answer only because
// something else would have spoken — and that something else is not ported, which
// is why this unit's expected checker output is genuinely empty rather than
// merely quiet.
//
// ★★ THE ONE LINE THAT MAKES THIS FILE A MODULE IS THE LAST ONE. Remove it and
// every statement above starts reporting TS2439 — which is the sharpest possible
// statement of what is_module_augmentation_external actually reads: a property of
// the FILE, not of the declaration.
declare module "m" {
    import a from "./a";
    export { b } from "../b";
    import c = require("/rooted");
}
export {};
