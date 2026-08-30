// Slice 60. checkTypeParameterDeferred's population — the one arm the deferred
// drain has, reached through checkNodeDeferred.
//
// ★★★ SLICE 106 MADE THIS FILE LIVE WITHOUT TOUCHING A CHARACTER OF ITS INPUT.
// The sentence that stood here — *the deferred arm does not execute at all*, with
// check_source_file's early return as its reason — was true when slice 60 wrote it
// and stopped being true in slice 100, which lifted that return. Nothing re-read
// it. The `in T` below now reaches checkTypeParameterDeferred, takes the marker
// route and records `create-marker-type 8192`; the reference answers TS2636 on it
// (*type ... is not assignable to type ... as implied by variance annotation*),
// which is the variance machinery this port stops in front of.
//
// ★★ A CLAIM ABOUT REACHABILITY IS A CLAIM ABOUT SOMEBODY ELSE'S LINE, and that is
// why it expired unnoticed. The mechanism it rested on lives in check_source_file,
// six slices away, and its removal WAS written down — at its own line, which is
// slice 104's rule correctly applied. What no rule covers is the other direction:
// the two headers that sentence invalidated (this one and the deferred check's own)
// had nothing pointing at them from the line that moved.
//
// ★★ THE GUARD IS A KIND TEST ON THE PARENT AND IT CLOSES THREE QUARTERS OF THE
// FUNCTION: a type parameter of a function, a method or a signature falls through
// every arm, so the deferred check is the reference's own no-op for it. An
// INTERFACE is one of the three parents that owe the machinery, which is why this
// fixture is an interface and not a function.
export {};
interface I<in T> { x: T }
