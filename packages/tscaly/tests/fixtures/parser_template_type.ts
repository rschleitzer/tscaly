// The template literal TYPE. Same head/middle/tail machinery as the expression
// and a different span node: its first slot is a TYPE, not an expression.
type A = `x${string}y`;
type B = `x${string}y${number}z`;

// A template with no substitution in TYPE position is a LiteralType wrapping a
// NoSubstitutionTemplateLiteral — not a TemplateLiteralType — which is the same
// distinction the expression side draws and a different node.
type C = `plain`;

// The type in a span is a full type, so it can be a union, and the `|` cannot
// be mistaken for the end of the substitution.
type D = `x${"a" | "b"}y`;

// Nested, so parse_template_type_span re-enters through parse_type.
type E = `x${`i${number}j`}y`;
