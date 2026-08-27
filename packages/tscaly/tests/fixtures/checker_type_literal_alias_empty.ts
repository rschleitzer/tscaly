// SLICE 80: the ALIAS half of getTypeFromTypeLiteralOrFunctionOrConstructorTypeNode's
// guard, which is the only reason getAliasSymbolForTypeNode exists here.
//
// `{}` has no members, so the guard's second disjunct decides: an EMPTY type
// literal that an alias names gets its OWN anonymous type, and one that nothing
// names gets the shared emptyTypeLiteralType. The two lines below are that pair,
// and the parenthesized third is the walk-up in the alias lookup — a
// ParenthesizedType between the literal and the alias declaration must not hide
// the alias.
type AliasedEmpty = {};
declare const unaliasedEmpty: {};
type ParenthesizedEmpty = ({});
