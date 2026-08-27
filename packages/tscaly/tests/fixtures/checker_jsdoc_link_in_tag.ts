// SLICE 78: the link is in a TAG's comment and nowhere else. checkSourceElement
// Worker calls checkJSDocComments TWICE per JSDoc — once for the comment itself
// and once for every tag — and a port walking only the first would let this one
// through.
/**
 * The prose carries no link at all.
 * @see somewhere and then {@link I}
 */
interface I { [k: string]: any; [j: string]: any; }
