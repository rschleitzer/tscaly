// The tristate that §3.5j records: `({ x })` and `([ x ])` are UNKNOWN, so the
// speculative parse runs and walks into a binding pattern. That entry says
// `({ x: 1 })` reports unported "even though the parenthesized object literal
// it turns out to be parses perfectly here" — this is the slice that closes it,
// so both readings must now come out right.
var a = ({ b }) => b;
var c = ([d]) => d;
var e = ({ f: 1 });
var g = ([h]);
