// SLICE 78: `{@link X}` in the JSDoc's OWN prose — a JSDocLink node among the
// comment parts, which is where checkJSDocComment reaches resolveJSDocMemberName
// and this port stops.
/** See {@link I} for more. */
interface I { [k: string]: any; [j: string]: any; }
