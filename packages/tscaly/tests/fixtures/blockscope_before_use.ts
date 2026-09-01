// Slice 107. isBlockScopedNameDeclaredBeforeUse's AFTER tail — a declaration that
// comes textually later, and the three codes that follow when the use is not
// deferred.
//
// ★★★ THE THREE REPORTS ARE ONE CONDITION READ THROUGH THE SYMBOL'S FLAGS.
// checkResolvedBlockScopedVariable asks isBlockScopedNameDeclaredBeforeUse once and
// then picks TS2448, TS2449 or TS2450 off `result.Flags`, so a fixture that carried
// only one of them would leave two arms of the report chain with no input at all.
// The fourth arm — a CONST enum — is an OPTION and not a code: it reports only
// under isolatedModules, which is unset here, and is the row `get_isolated_modules`
// exists for.
//
// ★★ THE NEGATIVES ARE THE HALF THAT COSTS SOMETHING. Every use inside a FUNCTION
// is legal however late the declaration is, because isUsedInFunctionOrInstanceProperty
// answers true for it; a port that reported unconditionally would be green on the
// three positives and wrong on the whole corpus, so `later`, `deferred` and
// `stillFine` are here to fail that port.

class C { }
new C();

// The class is declared AFTER the use and the use is not deferred.
new D();
class D { }

// ... but a use inside a function is, however early it stands.
function later() { return new D(); }

enum E { A }
let a = E.A;

// Same for an enum.
let b = F.B;
enum F { B }

function stillFine() { return F.B; }

function deferred() {
    return g;
}
let g = 1;

// A block-scoped variable, the third flag.
function h() {
    x;
    let x = 1;
}
