// Slice 91. onSuccessfullyResolvedSymbol's THIRD block — TS2372 and TS2373 — and
// the two resolver arms that feed it.
//
// ★★★ THE ARMS WERE OMITTED UNDER §3.5ao AND THIS SLICE IS THE READER THAT
// EXPIRES THAT NOTE. `case KindParameter` and `case KindBindingElement` set only
// `associatedDeclarationForContainingInitializerOrBindingName`, whose one reader
// is this callback — so until a caller passed a message, both arms were provably
// unobservable and both were left out.
function f(a = a) {}
function g(b = c, c = 1) {}
