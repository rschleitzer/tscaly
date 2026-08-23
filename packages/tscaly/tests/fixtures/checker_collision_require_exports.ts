// Slice 59. The one LIVE report of the three "generated code" collision checks:
// a top-level declaration in a MODULE whose name is one of the two the
// down-level module transform reserves.
//
// ★★★ IT IS LIVE BECAUSE OF THE PROGRAM'S ANSWER AND NOT THE OPTION'S.
// checkCollisionWithRequireExportsInGeneratedCode returns at
// `GetEmitModuleFormatOfFile(...) >= ModuleKindES2015`, and the oracle's stub
// program answers ModuleKindNone for every file — which is BELOW ES2015, so the
// check runs. The option-derived value (Checker.module_kind) is ES2022 and would
// have made this fixture silent; §3.5cy's rule read in the direction that bites.
//
// ★★ THE MODULE-NESS IS THE OTHER HALF AND checker_collision_require_script.ts is
// its negative: the report needs `IsSourceFile(GetDeclarationContainer(node)) &&
// IsExternalOrCommonJSModule(parent)`, so the same two declarations in a SCRIPT
// say nothing at all. `export {}` is what makes this file a module — the smallest
// external-module indicator there is.
//
// ★ Both declarations report, and the check is asked of BOTH spellings per name
// (require, exports) in one disjunction, so the arm each of them stops at is
// irrelevant to the report: record_unported marks and continues.
//
// ★★ THE THIRD DECLARATION IS THE CONTAINER TEST'S NEGATIVE and is silent: a
// class inside a NAMESPACE has a ModuleBlock for its declaration container, not
// the SourceFile, so nothing the module transform emits at the top level can
// collide with it. It is the only witness this suite has for that term.
export {};
class require {}
enum exports {}
namespace N { export class exports {} }
