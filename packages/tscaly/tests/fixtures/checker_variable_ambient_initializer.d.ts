// Slice 54. checkAmbientInitializer, every arm the corpus can reach, in one
// unit — three reports and three negatives.
//
// ★★★ TWO CODES AND THE CONDITION THAT SEPARATES THEM. An ambient initializer is
// TS1039 (*initializers are not allowed*) unless the declaration is const-like
// AND carries no type annotation, in which case the initializer merely has to be
// a literal and a non-literal is TS1254. So `let c = 1` is refused for being
// `let` and `const d: number = 1` for having a type, while the same value under
// a bare `const` is fine.
//
// ★★ THE THREE NEGATIVES ARE THE THREE KIND TESTS of the disjunction that this
// port CAN answer: a numeric literal, a boolean keyword, and a prefix MINUS over
// a numeric literal. The last is deliberately not ast.is_signed_numeric_literal,
// which admits `+1` as well — the reference's own predicate is minus-only, and
// `+1` here would be TS1254.
declare namespace N1 { const a = 1; }
declare namespace N2 { const b = [1]; }
declare namespace N3 { let c = 1; }
declare namespace N4 { const d: number = 1; }
declare namespace N5 { const e = true; }
declare namespace N6 { const f = -1; }
