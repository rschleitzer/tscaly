// Slice 58. TS2439 — `Import or export declaration in an ambient module
// declaration cannot reference module through relative module name`, and the
// path predicate it needs.
//
// ★★★ THIS FILE IS NOT AN EXTERNAL MODULE, and that is the whole condition. The
// suppression in front of the report is isTopLevelInExternalModuleAugmentation,
// which asks whether the enclosing `declare module "m"` is an AUGMENTATION —
// through ast.IsModuleAugmentationExternal, whose SourceFile arm answers
// `IsExternalModule(file)`. With no top-level import or export here the file is a
// global script, `declare module "m"` is a declaration rather than an
// augmentation, and the report fires. Its twin
// checker_ambient_module_augmentation_relative.d.ts is the same three statements
// in a file that IS a module, and there the report is suppressed — the pair is
// the gate, because either file alone cannot tell a working suppression from a
// missing report.
//
// ★★ WHAT COUNTS AS RELATIVE IS tspath's, not intuition's: `.`-prefixed AND
// rooted disk paths, because neither is searched for in node_modules. The fourth
// line is a bare specifier and must stay silent; the third is the rooted case and
// must not.
declare module "m" {
    import a from "./a";
    export { b } from "../b";
    import c = require("/rooted");
    import d from "bare";
}
