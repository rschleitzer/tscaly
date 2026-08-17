// An object pattern's element may START with `[` — a computed property name —
// which is why PCObjectBindingElements needs its own list predicate and cannot
// share the array pattern's.
var { [a]: b } = x;
