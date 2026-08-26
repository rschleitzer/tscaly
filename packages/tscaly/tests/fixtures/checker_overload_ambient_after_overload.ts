// ★★★ THE AMBIENT RESET OF previousDeclaration, and the order is the whole
// fixture: the ambient declaration comes AFTER a non-ambient body-less one, with
// a statement between them. The reset fires on the ambient node's OWN iteration
// and clears the pending previous declaration before the consecutiveness question
// is asked — which is the reference's comment made observable ("ambient
// declarations can be interleaved"). Drop the reset and the earlier overload is
// read as the start of a non-consecutive block and reports.
//
// ★ Putting the ambient declaration FIRST does not test it: previousDeclaration
// is assigned at the END of every iteration, ambient or not, so the reset is only
// ever visible on the declaration that PRECEDES an ambient one.
function k(a: number): void;
var separator = 1;
declare function k(a: string): void;
