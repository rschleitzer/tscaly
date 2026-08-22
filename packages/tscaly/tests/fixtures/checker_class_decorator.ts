// Slice 51. checkDecorators past its guard — the report this slice places, and
// the reason the guard is ported rather than the whole function: a class with no
// decorator returns at the first line and the check continues to
// checkCollisionsForDeclarationName, which is where nearly every class in the
// corpus lands.
//
// ★ It has to be the FIRST statement of the unit to be observable at all: the
// unported report keeps the first, and every other declaration kind that could
// introduce `dec` reports before it.
@dec class C {}
