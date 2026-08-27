// SLICE 77: the ONCE-BIT, and it needs THREE declarations rather than two — which
// is the fixture correction the battery forced.
//
// ★★★ WHY TWO IS NOT ENOUGH, and it is a property of this port's guard idiom
// rather than of the chapter. checkInterfaceDeclaration guards its steps with
// `if this.is_unported() <> unported_before  return`, and `is_unported()` is a
// BOOL — *has this unit stopped at all* — not the monotone mark. A merged
// interface makes checkTypeParameterListsIdentical report on EVERY declaration,
// so the first one is the unit's first stop and returns, and every later one finds
// the flag already true, does not return, and runs the tail. With two
// declarations the tail therefore runs exactly ONCE and the once-bit is never
// asked; with three it runs twice and a missing bit reports four TS2374 lines
// instead of two.
//
// ★★ A fixture that cannot make the mechanism fire is indistinguishable from a
// correct one — control g03 came back ungated against the two-declaration version
// and that is how this was found.
interface M { [k: string]: any; [j: string]: any; }
interface M { }
interface M { }
