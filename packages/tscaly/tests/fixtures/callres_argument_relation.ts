// Slice 108. The argument that is NOT assignable — isSignatureApplicable answering
// false through the relation slice 101 built.
//
// ★★★ THIS PORT IS SILENT HERE AND THE REFERENCE REPORTS TS2345, and the silence is
// the measurement: `chooseOverload` passes reportErrors FALSE, so the relation is
// asked with no error node and says nothing, and the pass that DOES report —
// reportCallResolutionErrors — is this slice's wall. **That is also why no head
// message is threaded through the relation: at every call site this chapter has, the
// message would have no reader.**
function f(a: number): void {}
f("no");

function g(a: string): void {}
g(1);
