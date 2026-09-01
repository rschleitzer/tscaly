// Slice 102: The `+` and `+=` arm — the non-strict StringLike gate in front of
// checkNonNullType, the three strict forks and the any/error tail.
var numPlus = 1 + 2;
var strPlus = "a" + "b";
var mixedPlus = "a" + 1;
var bigPlus = 1n + 2n;
var anyLeft: any = 1;
var anyPlus = anyLeft + anyLeft;
var anyStr = anyLeft + "a";
var bigMixed = 1n + 1;
var acc: number = 0;
