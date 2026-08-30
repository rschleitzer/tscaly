// Slice 106. getTypeParameterModifiers' FOLD — the one shape in which reading
// declaration ZERO and folding every declaration answer differently.
//
// ★★★ IT EXISTS BECAUSE THE CORPUS'S ONLY MERGED TYPE PARAMETER CANNOT
// DISCRIMINATE, AND THAT IS MEASURED RATHER THAN ASSUMED.
// checker_type_parameter_duplicate.ts writes `interface I<in out U, U>`, whose
// symbol really does carry TWO declarations — the symbol dump reads `d 1 169 12
// 20` and `d 1 169 21 23` — so the input for the fold has been in the corpus since
// slice 60. It still gates nothing, twice over: the modifiers sit on declaration
// ZERO, and `in out` is INVARIANCE, the one annotation pair whose whole arm is a
// return. §3.5v's first row, and its answer is this file.
//
// ★★ THE MODIFIER IS ON THE SECOND DECLARATION, WHICH IS THE WHOLE POINT. Folding
// answers `in`; reading declaration zero answers nothing; and because the parent
// is a TYPE ALIAS whose declared type is a type parameter, the difference is a
// TS2637 rather than a line of the stop log.
//
// ★ The duplicate itself is a TS2300 from the binder and is not this file's
// subject — it is the price of the only shape in which one type-parameter symbol
// has two declarations at all.
export {};
type L<M, in M> = M;
