// In a DECORATOR context a `[` opens a computed property name, not an element
// access — parseMemberExpressionRest refuses it unless a `?.` said otherwise.
// So this is `@d`, then the property named `[1]`, then a separate method.
//
// ★ The guard has been in this port since slice 5 and was UNREACHABLE until
// slice 12: no text could reach it while `@` itself reported unported. A §3.5p
// claim expiring on the slice that owns it.
//
// ★ The line break is what makes this a RED rather than a matched-count gate.
// Without the guard the port reads `@(d[1])` and then needs a member name: with
// `@d [1] = 2;` (the sibling file) the `=` leaves it nowhere to go and the case
// merely turns unported, while here `m()` is a perfectly good member and the
// port completes a tree with one member where the reference has two.
declare const d: any;

class C {
    @d [1]
    m() { }
}
