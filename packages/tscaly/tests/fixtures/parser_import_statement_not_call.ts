// The look-ahead's negative side, which is what keeps an import DECLARATION a
// declaration: the keyword is an expression only when `(` or `<` follows it, and
// the reference's comment names this exact hazard.
import * as x from "m";
export { x };
