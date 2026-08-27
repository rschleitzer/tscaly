// SLICE 82: TS7010, and it is the report the t == nil collapse buys.
//
// checkAllCodePathsInNonVoidFunctionReturnOrThrow is a no-op for a function with no
// return annotation — every one of its switch's first three cases is guarded by
// `t != nil` and the fourth by noImplicitReturns, which is unset — so the two
// blocks BEHIND it run, and the second of them is reportImplicitAny for a
// declaration with no return type and NO BODY. That is an overload signature.
//
// ★ report_implicit_any's function-like label has been ported since slice 69 with no
// input at all: its one caller was a signature's PARAMETER. This is the first file
// that reaches TS7010.
function overloaded(x: string);
function overloaded(x: number);
function overloaded(x: any) { return x; }
