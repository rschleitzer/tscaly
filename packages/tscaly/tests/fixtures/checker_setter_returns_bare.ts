// The negative twin of checker_setter_returns_value: a bare `return` in a setter
// is legal, so TS2408 must NOT fire. It is what tells the arm's guard
// (`exprNode != nil`) from the arm itself.
class C {
    set x(v: number) {
        return;
    }
}
