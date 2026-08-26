// ★★ TS2393, reported on EVERY function declaration of the symbol rather than on
// the second one — the loop sets a flag and the block after it walks the list
// again. That is also why `functionDeclarations` is a second walk in this port
// rather than a list: the two loops read the same filtered sequence.
function d(a: string): void { }
function d(a: number): void { }
