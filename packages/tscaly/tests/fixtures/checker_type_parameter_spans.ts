// Slice 60. The two reports of checkTypeParameters' loop body, chosen so that
// their SPANS disagree.
//
// ★★★ A FIXTURE WITHOUT A MODIFIER OR A CONSTRAINT CANNOT TELL THEM APART.
// TS2706 spans the whole PARAMETER (`c.error(node, …)`) and TS2300 spans the NAME
// alone (`c.error(node.Name(), …)`), and on a bare `<T = string, U>` those two are
// the same three characters. Here the ordering report has to cover `in out U`
// including its modifiers, and the duplicate report has to cover the bare `V` of
// `V extends number` and not its constraint.
export {};
interface I<T = string, in out U> { x: T, y: U }
interface J<V extends string, V extends number> { z: V }
