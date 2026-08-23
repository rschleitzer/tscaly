// Slice 59. checkClassNameCollisionWithObject — the function slice 58's work list
// called a stop ("the global symbol"), which resolves nothing and is two terms.
//
// ★★★ THE REPORT IS LIVE AND THE FORMAT IS WHY: `name.Text() == "Object" &&
// GetEmitModuleFormatOfFile(...) < ModuleKindES2015`, and the stub program
// answers ModuleKindNone. Under the option-derived ES2022 this file would be
// silent. It is also the only report of this family that needs no container and
// no module-ness — a plain script says it too.
//
// ★★ THE AMBIENT TWIN IS THE HEAD'S OWN TEST, not the function's: the class-like
// branch of checkCollisionsForDeclarationName asks
// `node.Flags&NodeFlagsAmbient == 0` before calling it, so `declare class Object`
// is silent. (needCollisionCheckForIdentifier refuses an ambient declaration too,
// which is the same fact one function over and is what keeps the require/exports
// check off it.)
class Object {}
declare class Object2 {}
