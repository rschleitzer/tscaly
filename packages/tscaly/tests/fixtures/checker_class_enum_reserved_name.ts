// Slice 59. The two callers checkTypeNameIsReserved gains in this slice, which
// are the class-like and the enum branch at the bottom of
// checkCollisionsForDeclarationName.
//
// ★★ ONE FUNCTION, TWO MESSAGES: TS2414 *class name cannot be 'any'* and TS2431
// *enum name cannot be 'string'*. The eleven reserved spellings are the ones
// slice 57 ported for the interface and the type alias; what is new here is the
// pair of code arguments and the branch that chooses between them.
//
// ★ A class also gets checkClassNameCollisionWithObject behind the same branch,
// and an enum does not — the `else if` is on the KIND, so the two branches are
// not each other's negation in what they do, only in when they run.
class any {}
enum string {}
