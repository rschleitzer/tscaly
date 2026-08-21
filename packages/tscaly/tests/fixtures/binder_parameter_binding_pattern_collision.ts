// slice 40 — the name is SPELLABLE, and this is what that costs. The reference
// writes `"__" + strconv.Itoa(index)` as a literal, with ASCII underscores,
// rather than through InternalSymbolNamePrefix — so a source identifier `__0` is
// the same name as the one the binder mints for a destructured parameter.
//
// ★★ Nothing merges, and the reason is the ROUTE and not the name: an anonymous
// declaration is added to no symbol table, so there is nothing for the named
// parameter to collide WITH. Two symbols, one name, one of them in the
// function's locals and one of them nowhere — and no duplicate-identifier
// diagnostic, which is what a table-based collision would have produced.
function f({ a }: { a: number }, __0: number) {
    return a + __0;
}

// ★ The same pair the other way round, so the ORDER of the two declarations
// cannot be what makes the first case work.
function g(__0: number, { b }: { b: number }) {
    return __0 + b;
}
