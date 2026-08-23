// Slice 61. checkTypePredicate's first report, TS1228, and the seven-kind list
// that decides it.
//
// ★★★ getTypePredicateParent IS A KIND TEST PLUS AN IDENTITY TEST, and the
// identity half is what a fixture has to reach: the predicate must BE the parent's
// return-type annotation. A CONSTRUCTOR TYPE is the cheapest witness for the kind
// half — the reference's list is arrow function, call signature, function
// declaration, function expression, function type, method declaration and method
// signature, and a `new (…) => x is T` is none of them.
//
// ★★ IT IS A `c.error` AND NOT A GRAMMAR ERROR, so it is not suppressed on a file
// with parse diagnostics — the one report of this slice for which that is true.
//
// ★ The function type on the first line is the negative half: the same syntax in a
// position the list admits must stay silent, and without it the arm could report
// unconditionally and still look right.
export {};
declare const legal: (x: unknown) => x is string;
declare const illegal: new (x: unknown) => x is string;
