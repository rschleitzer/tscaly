// SLICE 81: the fixture that makes the marker's RETRACTION observable, which no
// other file here can do.
//
// getResolvedTypeParameterDefault writes resolvingDefaultType into the memo before
// computing the default, and this port has a path the reference does not: a stop
// underneath leaves that marker in the slot. One ask cannot see it — the ask that
// stopped is the one that skips the TS2716 test — so the witness has to be a type
// parameter check_type_parameter runs TWICE, and a MERGED interface is that shape:
// two declarations, and the second ask would read the marker as a recursive entry
// and INVENT a TS2716 the reference does not report.
//
// ★ The default is a type REFERENCE on purpose: it is what makes the first ask stop
// (`get-type-from-type-node 184`), and without a stop there is no marker to leave
// behind.
interface MergedDefault<T = Later> { a: number }
interface MergedDefault<T = Later> { b: number }
interface Later { c: number }
