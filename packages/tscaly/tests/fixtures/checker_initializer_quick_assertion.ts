// getQuickTypeOfExpression's ASSERTION arm — the only arm of that function that
// is not a literal, and the only one whose answer this port can make: `1 as
// string` is getTypeFromTypeNode of a keyword, which slice 69 ported.
//
// * BOTH SPELLINGS ARE HERE because IsAssertionExpression names two kinds — the
// angle-bracket TypeAssertionExpression and the `as` form — and they share one
// body upstream, so a port that took one and forgot the other leaves this file
// green on the arm it did port.
//
// * `1 as const` IS THE NEGATIVE HALF and it is a FILE OF ITS OWN, because
// IsConstTypeReference is what keeps it out of this arm and the exclusion is only
// measurable where the const line is the first-wins one — see
// checker_initializer_quick_assertion_const.ts.
//
// * ★★★ THIS FILE'S OWN TAG IS `check-assertion` WITH THE ARM AND WITHOUT IT, and
// saying so is the point of the header rather than a defect of the fixture:
// check_variable_like_declaration checks the initializer a SECOND time after the
// symbol's type, and that second check is the dispatch's, which reports. So what
// the arm buys is the declaration's TYPE, and the reader that would make it
// visible does not exist yet (getTypeOfNode's expression arm). The battery's g14
// is that statement as a number.
let a = 1 as string;
let b = <number>1;
