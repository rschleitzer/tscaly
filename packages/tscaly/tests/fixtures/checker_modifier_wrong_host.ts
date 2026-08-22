// Slice 49. Four arms that reject a modifier on the wrong KIND of declaration,
// each with a code of its own — the half of checkGrammarModifiers that asks
// about the node rather than about the other modifiers.
//
//   abstract   TS1242  abstract modifier can only appear on a class method or
//                      property declaration
//   readonly   TS1024  readonly modifier can only appear on a property
//                      declaration or index signature
//   accessor   TS1275  accessor modifier can only appear on a property declaration
//
// ★ The `const` arm's TS1248 is the fourth of the group and has NO fixture,
// because `const` never reaches checkGrammarModifiers on one of these kinds: the
// parser reads a leading `const` as a variable declaration list, so `const
// interface I {}` is a variable named `interface` and not an interface with a
// modifier. It is the one report in the group that lands on the NODE rather than
// on the keyword, i.e. through GetErrorRangeForNode's declaration-NAME path —
// which is what the class and enum arms of a later slice will exercise.
abstract var a: number;
readonly var b: number;
accessor var c: number;
