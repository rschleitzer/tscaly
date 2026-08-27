// Slice 73. A parameter property against a field of the same name — the
// constructor branch of both walks.
//
// ★★★ A PARAMETER PROPERTY DECLARES A CLASS MEMBER THAT IS NOT IN THE MEMBER
// LIST, which is why both loops descend into a constructor's parameters instead of
// looking at the constructor itself. `public a` and the field are ONE symbol with
// two declarations, so the state machine trips, and the report has to land on the
// PARAMETER's name — a span the member walk alone can never produce.
export {};
class C {
    a: number = 1;
    constructor(public a: string) {}
}
