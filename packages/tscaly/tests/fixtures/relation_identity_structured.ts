// Slice 117's TS2403 shape: two declarations of one variable whose types are
// IDENTICAL and STRUCTURED. `isTypeIdenticalTo` used to stop in is_related_to_ex,
// and reading that stop's `false` as *not identical* reported TS2403 on 37
// stage-2 units. The identity relation now goes into the recursion instead.
// ★It stops at `get-variances` here rather than at `properties-identical-to`,
// because `I<{s:string}>` twice is two references to the SAME generic target and
// the variance arm is asked before the members are.
interface I<T> { s: T; }
declare var x: I<{ s: string }>;
declare var x: I<{ s: string }>;
