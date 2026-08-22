// Slice 55. A DEFERRED WITNESS, in checker_variable_ambient_initializer_enum_ref's
// shape (§3.5cy): every line here is a diagnostic checkParameter is ported for and
// this port cannot reach, and the file is here so that the slice which lands the
// hosts MEASURES them instead of discovering them as a diff.
//
// ★★★ FOUR REPORTS AND ONE CAUSE: the parameter walk has exactly one entry point.
// checkSignatureDeclaration's `c.checkSourceElements(node.Parameters())` is
// reached only from the FunctionDeclaration arm, so a constructor, an accessor,
// an arrow, a construct signature and a constructor type all keep their
// parameters out of reach. The reference answers seven C lines on this file and
// this port answers none — which is a subsequence, and therefore silent, which is
// exactly why the file has to exist.
//
// ★★ WHAT TURNS EACH LINE LIVE, so the successor slice does not re-derive it:
// TS2681 and TS2784 need checkClassLikeDeclaration to walk its MEMBERS (today it
// stops at checkCollisionsForDeclarationName) plus the type walk's construct
// signature and constructor type arms; TS2398 needs the same class walk; TS2730
// needs checkExpression, since an arrow function is an expression and nothing
// walks into an initializer yet.
//
// ★ The three TS2681 routes are deliberately all here: the block is
// `IsConstructorDeclaration || IsConstructSignatureDeclaration ||
// IsConstructorTypeNode`, and a fixture with only the constructor would let two
// thirds of the disjunction be dropped without a unit noticing.
class C {
    constructor(this: C) {}
    get g(this: C): number { return 1; }
    set s(this: C) {}
}
class D { constructor(public constructor: number) {} }
const a = (this: any) => 1;
interface I { new (this: I): I; }
type T = new (this: any) => void;
