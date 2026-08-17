// parseDecoratedExpression — the `@` arm of the PRIMARY expression, i.e. a
// decorated class EXPRESSION. It is the one place a class expression carries
// modifiers, which is what makes the comment on parse_class_expression a §3.5p
// claim that slice 12 had to correct.
declare const d: any;

const x = @d class { };
const y = (@d class Named { });
