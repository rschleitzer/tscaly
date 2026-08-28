// The three logical operators answering their LEFT operand's type — slice 90's
// only product that a type is, and the first answer this chapter has ever given.
// `false && x` asks Truthy of falseType and does not have it, `true || x` asks
// Falsy of trueType and does not have it, and `1 ?? x` asks EQUndefinedOrNull of
// a number literal under strictNullChecks and does not have it — so all three
// answer the left side unchanged, without a union.
//
// The second group is the complement and it STOPS: nullType has Falsy and
// EQUndefinedOrNull, so `||` and `??` reach getUnionType, while `&&` does not
// and answers nullType. One shape, three facts, two outcomes.
false && 1;
true || 1;
1 ?? 2;
null || 1;
null ?? 1;
null && 1;
