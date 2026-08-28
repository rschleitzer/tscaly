// getSuggestedBooleanOperator, which is the arithmetic arm's first step BELOW
// checkNonNullType and therefore slice 90's: both operands must be BooleanLike,
// which the true/false keywords answer without a symbol table. Three of the six
// spellings suggest something (`|` -> `||`, `^` -> `!==`, `&` -> `&&`) and the
// three compound ones do too; `<<` is in the same switch arm and suggests
// NOTHING, so it falls through to checkArithmeticOperandType and is the control
// that says the report is the SUGGESTION and not the arm.
true | false;
true ^ false;
true & false;
true << false;
