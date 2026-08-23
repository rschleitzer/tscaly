// Slice 59. The two AMBIENT tests of this family, which are one function apart and
// answer the same question about different things.
//
// ★★ `declare class require {}` is refused by needCollisionCheckForIdentifier —
// an ambient declaration emits nothing, so there is no emitted name to collide —
// and that arm is asked of every one of the seven reserved spellings. Drop it and
// this line reports TS2441.
//
// ★★ `declare class Object {}` is refused one function later, by
// checkCollisionsForDeclarationName's own `node.Flags&NodeFlagsAmbient == 0`
// around checkClassNameCollisionWithObject — the function itself has no ambient
// test, so the head is the only thing keeping this line silent. Drop THAT and it
// reports TS2725.
//
// ★ Both lines are silent on our side and the reference adds its own duplicate-
// identifier complaints about `Object` against lib.es5; diagcheck's subsequence
// relation is what lets a fixture whose reference answer is longer than ours be
// used at all.
export {};
declare class require {}
declare class Object {}
