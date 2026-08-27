// SLICE 81: the base constraint that RESOLVES all the way, which is what the
// retired stop stood in front of. Its sibling
// checker_type_parameter_constraint_keyword is slice 60's, over the same
// declaration shape and for the other half of the arm.
//
// A KEYWORD constraint is the one shape this port can carry through the whole
// chapter: getConstraintFromTypeParameter reads the constraint declaration, the
// type-node table answers it without reporting, and computeBaseConstraint's
// TypeParameter arm hands it to getNextBaseConstraint — where an intrinsic type is
// not a ConstrainedType at all and answers itself one line in. `any` is the third
// line because it is the one constraint the reference REWRITES: not the error
// type and not a mapped type's key, so it becomes `unknown`.
//
// ★ The declarations are interfaces and their members are keyword-typed on
// purpose: a `T` anywhere in the body would be a TypeReference and its row would
// take the unit's tag, which is what the first draft of this fixture measured
// instead of the chapter.
interface WithStringConstraint<T extends string> { a: number }
interface WithNumberConstraint<T extends number> { b: number }
interface WithAnyConstraint<T extends any> { c: number }
