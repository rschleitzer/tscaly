// ★★★ THE PIN ON THE BODY WALK, and it is the only kind of witness there is: no
// dump prints "the body was entered". The function takes NO parameter — so
// checkSignatureDeclaration reports nothing and the arm reaches its own end — and
// carries no overload, so the symbol check is silent. What is left is the body,
// and the `var` inside it is the first construct in the unit that reports at all.
//
// Without the walk this unit answers `get-return-type-from-annotation`, the tag
// of the line AFTER the body; with it, `get-type-of-variable-or-parameter-or-
// property`, from inside. The difference between the two IS the walk.
function w(): void {
    var v = 1;
}
