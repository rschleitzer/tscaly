// Slice 54. The THIRD code of the definite-assignment term — the catch-all,
// which needs a `!` that is otherwise entirely legal and an AMBIENT context to
// refuse it in.
//
// ★★ IT HAS TO BE A NAMESPACE RATHER THAN A `declare let d!: number` for
// checker_variable_using_ambient's reason one slice back: the flag has to arrive
// by PROPAGATION. A `declare` on the statement would set the same flag, but this
// file is a `.d.ts`, where the top level is ambient anyway and the modifier is
// the redundant spelling — the namespace is the shape that also works in a `.ts`.
declare namespace N { let d!: number; }
