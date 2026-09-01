// Slice 117 — the SECONDARY declaration, and its type is computed FRESH rather than
// read off the symbol.
//
// ★★★ THAT IS THE WHOLE POINT OF THE PRIMARY/SECONDARY FORK. `t` is the type of the
// SYMBOL, which is the first declaration's; `declarationType` is the widened type of
// THIS node. Folding the two would compare a type with itself and TS2403 could never
// fire. The first pair below differs only in the second annotation.
//
// ★★★ AND `same2` IS THE SHAPE STAGE 2 FOUND. Its two declarations are IDENTICAL and
// STRUCTURED, so `isTypeIdenticalTo` runs into the relation's recursion and STOPS —
// and a stop's `false` read as *not identical* reports TS2403 where the reference is
// silent. The unit is unported and the checker yardstick skips it; only diagcheck,
// whose relation is a subsequence, refuses the extra line.
declare var same: number;
declare var same: number;
declare var differs: number;
declare var differs: string;
interface I<S> { f: <T extends S>(x: T) => void }
var same2: I<{ s: string }>
declare var same2: I<{ s: string }>
var au;
declare var au: number;
