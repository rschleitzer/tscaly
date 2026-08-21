// slice 43 — the plainest infer type parameter, and the OTHER arm beside it.
//
// `infer U` inside the extends clause declares into the CONDITIONAL TYPE's own
// locals, a table nothing else in the binder makes: a conditional type is absent
// from GetContainerFlags, so it is not a container, and the table exists only
// because this declaration asked for one. The type alias's locals hold `T` and do
// NOT hold `U` — two tables on two nodes, which is the whole shape of the arm.
//
// ★ The generic function is the else arm of the same switch, unchanged since slice
// 34, and it is here so the fixture states what the slice did NOT change: a
// signature's type parameter goes through declareSymbolAndAddToSymbolTable into
// its container, and `V` lands in the function's locals beside its parameter.
type Unwrap<T> = T extends Array<infer U> ? U : never;

function pick<V>(v: V): V {
    return v;
}
