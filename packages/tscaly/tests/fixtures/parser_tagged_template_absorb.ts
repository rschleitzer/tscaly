// `` f<T>`x` `` reaches parse_member_expression_rest as an
// ExpressionWithTypeArguments, and the tagged template ABSORBS it back into one
// node: the tag is `f` and the type arguments become the tagged template's own
// third slot. Without the fold the tag would be the wrapper and the type
// arguments would be its children instead — a different tree with the same
// tokens.
declare function f(s: TemplateStringsArray, ...v: any[]): string;

f<string>`x`;
f<string, number>`x${1}y`;

// The fold is blocked by a `?.`, which is the other arm of the same test.
// Nothing was wrapped on that path, so the type arguments go straight in.
f?.<string>`x`;

// A no-substitution template through the same fold.
f<string>`plain`;
