// SLICE 81: an OBJECT-TYPE constraint, which is the arm that proves
// is_constrained_type's surprise.
//
// Upstream ConstrainedType is embedded by StructuredType, so a type literal's
// anonymous type IS constrained and does not take getResolvedBaseConstraint's
// early exit: it pushes a resolution frame and walks into computeBaseConstraint's
// tail, whose whole body is `return t`. The type literal itself is slice 80's
// work, which is why this line is only now a constraint that resolves.
declare function withObjectConstraint<T extends { a: number }>(x: T): T;
declare function withEmptyConstraint<T extends {}>(x: T): T;
