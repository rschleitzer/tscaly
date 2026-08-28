// GetImmediatelyInvokedFunctionExpression: the parenthesis walk, and the test
// that the call's EXPRESSION is the node the walk came up through.
//
// It is here as a NEGATIVE record. Nothing in this port walks into a function
// EXPRESSION's body, so no signature is ever asked for one and the iife term is
// unreachable — the whole file stops at checkCallExpression, twice. The fixture
// is what makes a control row aimed at that term a measurement rather than an
// assertion.
(function (a, b) {
    return;
})(1);
declare function take(f: () => void): void;
take(function () {
    return;
});
