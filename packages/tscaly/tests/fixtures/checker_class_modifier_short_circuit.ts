// Slice 51. `!c.checkGrammarModifiers(node) && classLikeData.HeritageClauses != nil`
// — the short-circuit whose LEFT side is the call.
//
// ★★ THE MODIFIER CHECK ALWAYS RUNS AND THE HERITAGE WALK DOES NOT. This class
// has both a modifier error and two extends types, and the unit must carry TS1029
// alone: a port that ran the walk anyway would add TS1174 here, and a port that
// skipped the call would lose the TS1029 as well.
declare class A {}
class B {}
declare export class C extends A, B {}
