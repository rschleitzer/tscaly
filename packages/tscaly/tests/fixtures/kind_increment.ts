// Slice 102: The `++`/`--` arm of both unary expressions — checkArithmeticOperand
// Type over ONE operand, and the checkReferenceExpression it gates.
var i = 0;
i++;
i--;
++i;
--i;
(0)++;
--(1);
({ a: 1 }).a++;
