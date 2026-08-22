// Slice 49. TS1044 — `{0} modifier cannot appear on a module or namespace
// element` — which the visibility arm and the `static` arm both reach by asking
// the PARENT's kind.
//
// ★★ AT THE TOP LEVEL OF A FILE THE PARENT IS ALWAYS A SourceFile IN THIS SLICE,
// and that is a real bound rather than an accident of the fixture: a statement
// inside a namespace body is reached through checkModuleDeclaration ->
// checkSourceElement(body) -> checkBlock, and the module arm is not ported — so
// the ModuleBlock half of this test has no fixture that can reach it yet. Said
// here so the next slice knows the half it inherits.
public var a: number;
static type T = number;
