// Slice 116: the constant EVALUATOR (internal/evaluator/evaluator.go), through
// the one caller TypeScript has for it — an enum member's initializer.
//
// Every arm of `evaluate` that this port can reach is here: the three prefix
// operators, the twelve binary ones, a string literal, a numeric literal, the
// two entity forms (an identifier and a qualified reference) and the string
// concatenation that stringifies a number on the way. `**` is included with an
// exact result on purpose — jsnum's Exponentiate is the one operator that does
// not agree with the reference to the bit, and its note says why.
//
// ★ NO TEMPLATE LINE, and that is a wall rather than an omission: `C = \`t${1}\``
// stops at check-template-expression, which is checkExpression's chapter and not
// this one, so a template initializer takes the whole unit's answer away. The
// evaluator's template arm therefore has no input in this corpus.
enum E { A = 1 + 2, B = "a" + "b", D = 1 / 0, X = 0 / 0, F = -1, G = ~0, H = 7 % 3, I = 2 ** 3 }
enum Ref { P = 1, Q = P << 2, R = Ref.P | Q }
declare let a: E.A;
declare let b: E.B;
declare let c: E.D;
declare let d: Ref.R;
declare let e: E.X;
