// slice 41 — every private member KIND, all four of them in one class and
// therefore all four `%FE#1@…`. What differs is the symbol FLAGS, not the naming
// route: a static property, a method, a get/set PAIR merged onto one symbol, and
// an `accessor` field.
//
// ★ The get/set pair is the one worth having: two declarations on one symbol, so
// the dump prints one entry with two `d` lines — and if the name were built per
// declaration rather than per name they would be two symbols with equal names in
// one table, which the table itself would never complain about.
class D {
    static #s = 1;
    #priv() { return 1; }
    get #g() { return 1; }
    set #g(v) {}
    accessor #acc = 1;
}
