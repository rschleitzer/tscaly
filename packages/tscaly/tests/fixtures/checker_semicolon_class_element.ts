// A `;` between two class members. checkSourceElementWorker has NO case for a
// SemicolonClassElement, so doing nothing is the reference's whole answer.
class C {
    a: number = 1;
    ;
    b: number = 2;
}
