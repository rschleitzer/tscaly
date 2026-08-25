// The 2 916-unit shape at stage 2: a class with no type parameters and no
// heritage clause. getDeclaredTypeOfClassOrInterface gives it a `this` type on
// the second term of its disjunction (kind == Class), so isThislessInterface is
// never asked, and the arm then stops at getTypeOfSymbol — the OTHER 4 500-unit
// head, one statement further on.
class C {
    a: string;
}
