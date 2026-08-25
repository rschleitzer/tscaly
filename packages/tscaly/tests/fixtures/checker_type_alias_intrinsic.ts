// Slice 65. The type-alias arm's own report, TS2795, and it is the first thing this
// file has ever said BELOW checkExportsOnMergedDeclarations.
//
// ★★★ THE ARITY IS PART OF THE NAME'S LICENCE. Two shapes are legal and they do not
// overlap — no type parameters and the name `BuiltinIteratorReturn`, or exactly one
// and a name in intrinsicTypeKinds — so all four lines below are wrong in a
// different way: a licensed name at the wrong arity, an unlicensed name at each
// arity, and an unlicensed name with two parameters.
//
// ★★ THE TWO LEGAL SHAPES ARE HERE TOO, and they are what makes the report a
// measurement rather than a transcription: a port that reported on every
// `intrinsic` would pass a fixture that held only the errors.
type BuiltinIteratorReturn = intrinsic;
type Uppercase<S extends string> = intrinsic;
type Uppercase0 = intrinsic;
type BuiltinIteratorReturn1<T> = intrinsic;
type NotIntrinsic<T> = intrinsic;
type NotIntrinsic2<T, U> = intrinsic;
