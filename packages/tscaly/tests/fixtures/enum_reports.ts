// Slice 116: the enum's own reports, one line each — a numeric member NAME
// (TS2452), a member with no initializer after a computed one (TS1061), a
// COMPUTED member name (TS2452's neighbour), a forward reference (TS2651), and
// the two const-enum value reports (TS2478 for NaN, TS2477 for an infinity).
//
// ★ The ambient enum is here because its members are COMPUTED rather than
// auto-numbered — the reference's own comment says so at the test that decides
// it, and the arm is one `if` above the auto-value one.
//
// ★★ IT MEASURES THROUGH diagcheck AND NOT THROUGH THE YARDSTICK: `Err2`'s
// computed member ends in checkTypeAssignableTo, which is a chapter away, so the
// unit stops before its T section. The C section is the whole point of the file
// and diagcheck compares it as a subsequence.
enum Err { 1.0 = 1 }
enum Err2 { A = f(), B }
enum Err3 { A, ["x"]: 1 }
declare function f(): number;
enum Fwd { A = B, B = 1 }
const enum Bad { N = 0 / 0, I = 1 / 0 }
declare enum Amb { A, B = 1, C }
