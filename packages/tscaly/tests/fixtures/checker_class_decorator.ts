// Slice 51 wrote this for checkDecorators' STOP; slice 134 ported the function
// and the unit is a MATCH. It stays as the smallest decorated class in the
// corpus — `@dec` on a class whose decorator is an undeclared name, so the walk
// runs resolveDecorator, reports the unresolved identifier and resolves an
// untyped call, which is the shortest path through the whole chapter.
//
// ★ The claim slice 51 attached to it is still true and is what makes it a
// coverage fixture rather than a duplicate: a class with NO decorator returns at
// checkDecorators' first line, so nothing else in the corpus reaches the body
// through this shape.
@dec class C {}
