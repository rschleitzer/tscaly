// The IsBindingElement and IsBindingPattern arms, which answer through
// getTypeForVariableLikeDeclaration rather than through a symbol — the pattern's own
// type comes from its PARENT and the element's from itself.
var [a, b] = [1, 2];
var { p, q: r } = { p: 1, q: 2 };
