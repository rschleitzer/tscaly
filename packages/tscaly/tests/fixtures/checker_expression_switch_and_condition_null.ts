// Two arms whose type the reference CONSUMES, so each stops one question later
// than the dispatch: an `if` condition reaches checkTruthinessOfType and a
// switch's clause reaches isTypeEqualityComparableTo — and the second needs BOTH
// the subject's type and the clause's, which is why the switch is over `null`
// too. Whichever reports first is the file's tag; the point of the file is that
// neither row says `check-expression` any more.
if (null) {
}
switch (null) {
    case null:
        break;
}
