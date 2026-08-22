// Slice 55. checkParameter's parameter-property block, whose SECOND report is
// the only one of the three this port can reach: `!(IsConstructorDeclaration(fn)
// && NodeIsPresent(fn.Body()))` — a parameter property on anything that is not a
// constructor with a body.
//
// ★★ THE FUNCTION DECLARATION IS THE ONLY HOST THE WALK REACHES, and that is why
// this fixture is a pair of functions rather than the class the diagnostic is
// really about. checkClassDeclaration stops at checkCollisionsForDeclarationName,
// so no member's parameters are walked yet — the same shape from a constructor
// overload is in checker_parameter_this_deferred.ts, where it waits with the rest
// of the family.
//
// ★ The third line is the NEGATIVE half and it is not a redundant one: a
// parameter DECORATOR is a modifier too (ModifierFlagsDecorator), and reading the
// block's guard as "has any modifier" instead of the five-flag
// ParameterPropertyModifier mask would report on it. `@dec` is the only parameter
// modifier outside the mask, so it is the whole negative population.
declare function dec(...args: any[]): void;
function f(readonly b: number) {}
declare function g(public c: number): void;
function h(@dec d: number) {}
