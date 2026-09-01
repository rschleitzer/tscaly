// The IsTypeDeclaration and IsTypeDeclarationName arms — the declared type rather
// than the type of the symbol, which is the distinction a class NAME makes visible:
// upstream answers `C` for the name and not `typeof C`.
interface I { }
type A = number;
class C { }
