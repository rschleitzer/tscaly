// Slice 60. checkTypeParameterDeferred's population — the one arm the deferred
// drain has, reached through checkNodeDeferred.
//
// ★★★ IT PRODUCES NO DIAGNOSTIC OF OURS AND THE DEFERRED ARM DOES NOT EXECUTE AT
// ALL, and the second half of that sentence is what the battery had to teach twice.
// The reference answers TS2636 on the `in T` below (*type ... is not assignable to
// type ... as implied by variance annotation*), which is the variance machinery this
// port stops in front of. The FIRST draft of this comment said the deferred report
// was merely never FIRST and that removing check_type_parameter's stop would expose
// it; g13 refuted that (the interface's own arm reports before the drain), and
// probing the arm with a diagnostic refuted the weaker claim too — check_source_file
// returns as soon as a statement has reported and the drain sits below that return.
// So what this file witnesses is a mechanism that is in place and unreached, and
// only g14/g15/g16 — which lift that early return as their premise — can see it.
//
// ★★ THE GUARD IS A KIND TEST ON THE PARENT AND IT CLOSES THREE QUARTERS OF THE
// FUNCTION: a type parameter of a function, a method or a signature falls through
// every arm, so the deferred check is the reference's own no-op for it. An
// INTERFACE is one of the three parents that owe the machinery, which is why this
// fixture is an interface and not a function.
export {};
interface I<in T> { x: T }
