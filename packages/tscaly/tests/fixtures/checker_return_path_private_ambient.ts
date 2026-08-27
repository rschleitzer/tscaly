// SLICE 82: isPrivateWithinAmbient, the ONE guard in front of TS7010, and the file
// that prices it. A private method of an ambient class has no body and no return
// annotation and gets NO report — the reference's own exemption.
//
// ★ It is the negative half of checker_return_path_class_overload: with the guard
// dropped the port INVENTS a TS7010 here, which is the direction diagcheck catches.
// ★★★ Until the class's member walk landed in the same slice, this file was INERT —
// nothing in this port ever reached a class member's checkFunctionOrMethodDeclaration
// — and the control aimed at it came back silent for a reason that had nothing to do
// with the guard. **A fixture that cannot be reached is indistinguishable from a
// guard that works.**
declare class AmbientHolder {
    private hidden(x: number);
}
