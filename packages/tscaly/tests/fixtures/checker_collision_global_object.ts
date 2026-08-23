// Slice 59. checkCollisionWithGlobalObjectInGeneratedCode, which runs to its last
// line on this file and reports NOTHING — and the fixture exists so that a control
// can make it speak.
//
// ★★★ §3.5ap's RULE APPLIED ON PURPOSE: *a fixture that gates nothing is
// invisible until a CONTROL aims at it*. Every step of this check is ported and
// every step is taken here — the name matches, the kind is not class-like, the
// container is the SourceFile, the file is a module — and the LAST term is
// `format == ModuleKindCommonJS` while the format is ModuleKindNone. So the
// function is measured rather than reported, and the row that substitutes
// CommonJS for the format is what proves the five steps in front of that term are
// right.
//
// ★★ AN ENUM RATHER THAN A CLASS, because this check EXCLUDES class-like nodes:
// a class named `Object` is checkClassNameCollisionWithObject's business (see
// checker_class_name_object.ts) and has a different message. An enum is the
// cheapest declaration that reaches the head and is not a class.
export {};
enum Object {}
