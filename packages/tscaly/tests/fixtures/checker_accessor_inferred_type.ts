// SLICE 112: getTypeOfAccessors — a getter's body inference is getReturnTypeFromBody,
// and the unannotated setter's TS7032 beats the getter's TS7033 because the
// reference's chain is an `else if`.
class A { get p() { return 1; } }
class B { get q(): string { return "s"; } }
class C { set r(v) { } }
