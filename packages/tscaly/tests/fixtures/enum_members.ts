// Slice 116: computeEnumMemberValues and the types it feeds — auto-numbering
// from zero, a continuation after an explicit value, a string member, a COMPUTED
// member (no constant value, so createComputedEnumType rather than an enum
// literal), and the single-member enum. ★The COMPUTED member is in
// enum_computed.ts and not here, because its `checkTypeAssignableTo` takes the
// whole unit's T section away — see that file's header.
//
// ★★ THE SINGLE-MEMBER ENUM IS THE ONE THE PRINTER'S ARM IS ABOUT: the union of
// one type IS that type, so `getDeclaredTypeOfSymbol(parent) == t` holds and the
// reference prints the PARENT alone. Read the arm as *a member always prints
// qualified* and this line is what says otherwise.
enum E { A, B, C = 10, D }
enum S { X = "x", Y = "y" }
enum Mixed { N = 1, T = "t" }
enum One { Only }
declare let a: E;
declare let b: E.A;
declare let c: E.D;
declare let d: S;
declare let e: Mixed;
declare let g: One;
declare let h: One.Only;
