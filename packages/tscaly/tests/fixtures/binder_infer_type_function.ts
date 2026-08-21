// slice 43 — the container is NOT the nearest locals container.
//
// ★★★ This is the fixture the arm exists to be told apart by. In
// `T extends (x: infer U) => void ? U : never` there is a locals container
// BETWEEN the infer type and the conditional type — the function type, which holds
// `x` — and `U` goes past it into the conditional's table. A port that declared
// into `b.container`, or into the nearest ancestor that has locals, produces a
// well-formed dump with `U` in the wrong table and nothing else in the corpus says
// so.
//
// ★ The second alias stacks two more of them: a type literal (whose MEMBERS table
// holds `m`) and a method signature (whose LOCALS hold `y`), and both `P` and `Q`
// still land in the one conditional table — so the walk is over PARENTS and not
// over containers, and it does not stop at the first one it meets.
type Arg<T> = T extends (x: infer U) => void ? U : never;
type Ret<T> = T extends { m(y: infer P): infer Q } ? [P, Q] : never;
