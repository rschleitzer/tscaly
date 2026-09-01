// Slice 117 — the fourth step of the binding-element block: the private/protected
// check on the property a destructuring reads.
//
// ★ It runs on the ELEMENT and reports on the element, which is why `secret` is
// TS2341 here and the enclosing declaration says nothing.
class Holder {
    private secret: number = 1;
    open: number = 2;
}
declare const h: Holder;
const { secret, open } = h;
