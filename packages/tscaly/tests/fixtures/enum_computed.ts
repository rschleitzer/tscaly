// Slice 116: the COMPUTED enum member — an initializer the constant evaluator
// cannot answer, which makes the member's type a createComputedEnumType pair
// rather than an enum literal, and makes every member after it report TS1061.
//
// ★★ THIS FILE MEASURES THROUGH diagcheck AND NOT THROUGH THE YARDSTICK, and the
// reason is one line down from the value: the reference's last arm here is
// `checkTypeAssignableTo(checkExpression(initializer), numberType, …)`, which is
// the relation's chapter, so the unit stops and its T section never prints. The
// C section is the whole measurement, and diagcheck compares it as a subsequence.
declare function f(): number;
enum Computed { A = f(), B = 2, C }
enum AllComputed { X = f(), Y = f() }
