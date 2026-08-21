// slice 43 — two conditionals, and which one owns the infer.
//
// ★★★ The predicate is about the PARENT and the walk does not stop at the first
// conditional type. In the first alias `infer A` sits in the INNER conditional's
// CHECK position, which is not a match, so the walk carries on to the OUTER
// conditional — whose extends clause that inner conditional is — while `infer B` is
// the inner one's extendsType and stops there. One nesting, two tables, and the
// two infers land in different ones.
//
// ★ The other two lines are the same question from the other two directions: an
// infer inside a conditional in the TRUE branch belongs to that inner conditional
// (and the outer one gets no table at all), and a conditional in the CHECK position
// keeps its own infer as well — the enclosing conditional, whose extendsType is
// `true`, is not the answer.
type Outer<T> = T extends (infer A extends infer B ? 1 : 2) ? A : B;
type True<T> = T extends string ? (T extends infer C ? C : 1) : 2;
type Check<T> = (T extends infer D ? 1 : 2) extends true ? D : 3;
