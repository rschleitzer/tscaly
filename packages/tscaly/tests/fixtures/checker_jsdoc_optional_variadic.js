// The two JSDoc type kinds checkSourceElementWorker's JSDoc label does NOT name.
// Its case list is NonNullable, Nullable, All and TypeLiteral; an OptionalType
// (`number=`) and a VariadicType (`...number`) have no case at all.
/**
 * @param {number=} a
 * @param {...number} b
 */
function f(a, b) { }
