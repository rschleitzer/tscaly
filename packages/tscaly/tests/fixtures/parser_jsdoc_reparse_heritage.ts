// Slice 22 — @implements and @augments, which are the only two tags that write
// into a HERITAGE clause. Three shapes, because the arms differ:
//
//   implements with no clause at all  -> a clause is created
//   implements with a clause already  -> the type is appended to it
//   augments matching the extends     -> its type arguments are filled in
//
// @Filename: heritage.js
/** @implements {I} */
class A {}

/** @implements {J} */
class B implements I {}

/** @augments {Base<string>} */
class C extends Base {}

// The name does NOT match, so nothing is filled in.
/** @augments {Other<string>} */
class D extends Base {}
