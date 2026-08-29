// The computed-name arm builds an ELEMENT access upstream and is a stop here, for
// the reason isMatchingReference's own arm gives: matching one needs
// tryGetElementAccessExpressionName, and a wrong `false` would make a real
// assignment invisible.
declare const key: unique symbol;
class Computed {
    [key]: string;
    constructor() {
        this[key] = "x";
    }
}
