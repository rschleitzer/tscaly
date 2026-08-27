// SLICE 82: the SECOND of the two lines checkFunctionDeclaration has been missing
// since slice 52 — checkCollisionsForDeclarationName, ported in slice 59 for the
// class, enum and module arms and never called from here.
//
// ★★★ IT IS §3.5v's FIRST ROW ARRIVING THROUGH THE BATTERY. The control that removes
// the call came back silent against the whole corpus, and the discriminating text is
// one line: a top-level function named `require` in a MODULE, which is what
// checkCollisionWithRequireExportsInGeneratedCode reserves (TS2441). Neither of the
// function's two kind branches can fire for a function declaration — those are
// IsClassLike and IsEnumDeclaration — so the five checks in front of them are the
// whole of what this call site can add, and only this one of the five is live here.
export {};
function require() { }
