// slice 40 — the shapes AROUND the pattern, all of which leave the arm's answer
// alone. The test is `IsBindingPattern(decl.Name())` and nothing else: an
// initializer, a rest token, an optional-looking default and a nested pattern all
// still take the anonymous route, and the index still counts positions.
//
// ★ The nested elements are bound by the BindingElement arm, not by this one, so
// `b` and `c` are ordinary function-scoped variables however deep they sit. The
// pattern node itself never becomes a symbol.
function f({ a: { b, c } }: { a: { b: number; c: number } }) {
    return b + c;
}

function g([[d], [e]]: number[][]) {
    return d + e;
}

function h({ i } = { i: 1 }, ...[j]: number[]) {
    return i + j;
}

// ★ A rest parameter whose name is a pattern is index 1 like any other position.
function k(a: number, ...[l, m]: number[]) {
    return a + l + m;
}
