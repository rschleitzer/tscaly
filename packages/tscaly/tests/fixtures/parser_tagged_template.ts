// The tagged template's four slots: tag, questionDotToken, typeArguments,
// template — in that order, with the LIST third.
declare function t(s: TemplateStringsArray, ...v: any[]): string;

// Tag plus a no-substitution template: the template child is a literal, not a
// TemplateExpression.
t`plain`;

// Tag plus a template WITH substitutions.
t`x${1}y`;

// A member expression as the tag, so the tag slot is a whole subtree.
o.p`x`;

// Chained: a tagged template is itself a left-hand-side expression, so it can
// be tagged again.
t`a``b`;

// The tag is a call result.
t()`x`;
