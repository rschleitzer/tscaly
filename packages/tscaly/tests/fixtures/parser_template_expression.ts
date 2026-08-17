// The template expression, head to tail. `a` gives a head and a tail with one
// span between them; `b` gives a head, a MIDDLE and a tail, which is the only
// thing that makes parse_template_spans loop more than once — a span whose
// literal is a TemplateMiddle is followed by another span.
var a = `x${1}y`;
var b = `x${1}y${2}z`;

// No substitution at all: one NoSubstitutionTemplateLiteral token, no spans and
// no TemplateExpression node. It shares the arm with the string literal.
var c = `plain`;

// An empty substitution chunk on both sides of the `${`, so the head and the
// tail are zero-length text. The nodes are still there.
var d = `${1}`;

// A substitution holding an object literal, so the `}` that closes the literal
// is NOT the `}` that closes the substitution. Only the second one is rewound
// into a template tail.
var e = `x${ { f: 1 } }y`;

// Nesting: the inner template is parsed by the same routine, re-entered from
// inside parse_template_span's expression.
var g = `x${ `i${2}j` }y`;
