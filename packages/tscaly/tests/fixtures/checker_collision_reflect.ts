// Slice 59. recordPotentialCollisionWithReflectInGeneratedCode's guard, the third
// of the three checks ES2025 closes.
//
// ★★ IT IS A SEPARATE FIXTURE FROM WeakMap AND Promise BECAUSE record_unported
// KEEPS THE FIRST TAG: the head calls the three in order, so a file that names two
// of them would witness only the earliest. Slice 56's rule — a fixture that cannot
// be first is not a witness — three times over.
//
// ★ Behind the guard: checkReflectCollision, reading
// NodeCheckFlagsContainsSuperPropertyInStaticInitializer off a class expression's
// members or off a function expression itself. Same nodeLinks table as WeakMap's.
class Reflect {}
