// Slice 50, and it is the second half of a fixture slice 49 could only write
// half of. `checker_modifier_namespace_element.ts` reports TS1044 — `{0} modifier
// cannot appear on a module or namespace element` — with the statement's parent a
// SourceFile, and its comment says the ModuleBlock half *has no fixture that can
// reach it yet*. This is that fixture: the block arm landed, so a statement inside
// a namespace body is checked and its parent IS a ModuleBlock.
//
// ★ `namespace A.B` also exercises the module arm's recursion into a body that is
// a MODULE DECLARATION rather than a module block — the dotted form nests one
// declaration inside the other — which is the same shape the JSDoc reparser
// builds for a dotted `@typedef` name.
namespace A.B { public var x: number; }
