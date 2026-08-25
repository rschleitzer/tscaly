// Slice 65. checkModuleDeclaration's last two arms, TS2435 and TS2436, which are
// the halves of the ambient-external-module branch that are NOT an augmentation.
//
// ★★★ THE THREE ARMS DIFFER IN WHAT THEIR PARENT IS, not in what they declare.
// `declare module "m"` inside a namespace is nested where it may not be; the same
// declaration at the top of a SCRIPT with a relative name is a different
// complaint; and an augmentation — the first arm — is neither, because it has a
// target whose body it checks instead. A file with no export keeps this a script,
// which is what makes the middle arm reachable at all.
//
// ★★ `is_global_source_file` IS THE TEST THAT SEPARATES THEM and it asks the
// BINDER, not the node: whether the file is an external or CommonJS module is a
// property of the FILE. Add an `export {}` here and the second arm stops being
// reachable while the text of every declaration is unchanged.
declare namespace Outer {
    module "nested" {}
}
declare module "./relative" {}
declare module "nonrelative" {}
