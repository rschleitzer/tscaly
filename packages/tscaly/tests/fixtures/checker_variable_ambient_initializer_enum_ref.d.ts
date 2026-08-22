// Slice 54. A DEFERRED WITNESS, in checker_variable_block_scoped_deferred's
// shape (§3.5cx): it proves nothing today and is here so that the slice which
// ports the expression dimension measures this term instead of discovering it as
// a diff.
//
// ★★★ THE ONE TERM OF checkAmbientInitializer's DISJUNCTION THAT NEEDS TYPES.
// `isInitializerSimpleLiteralEnumReference` asks
// `checkExpressionCached(expr).flags & EnumLike`, and it asks it only of a
// PROPERTY ACCESS or an ELEMENT ACCESS — so for every other initializer shape the
// term is false without a type being computed, which is why the fixture above can
// be complete. The reference answers TS1254 on both lines here (neither `N.a` nor
// `N["a"]` is an enum member); our side answers
// `is-initializer-simple-literal-enum-reference`.
//
// ★ What turns it live: `checkExpressionCached` plus the EnumLike bit of a
// property access's type — i.e. the expression dimension's first real arm, not a
// grammar slice.
//
// ★★ THE REFERENCED NAMESPACE COMES LAST, AND THAT ORDER IS THE FIXTURE'S TAG.
// record_unported keeps the FIRST report, and the walk is in source order — so
// with `N` declared above, the innocent `const a = 1` would report
// `get-symbol-of-declaration` and this unit would say nothing about the term it
// exists for (§3.5cw's shadowed-by-the-walk shape). An ambient namespace hoists,
// so the reference resolves `N.a` either way.
declare namespace P { const g = N.a; }
declare namespace Q { const h = N["a"]; }
declare namespace N { const a = 1; }
