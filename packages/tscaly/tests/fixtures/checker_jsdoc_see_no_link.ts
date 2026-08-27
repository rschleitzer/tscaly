// SLICE 78: the sharp half of the gate. `@see` makes with_jsdoc parse the comment
// EAGERLY even in a TS file, so this unit's JSDoc IS in the cache and the pass
// really does walk its comment parts — and finds no link, so the arm still runs.
//
// A fixture whose JSDoc is absent from the cache could not tell the tightened gate
// from a gate that was simply deleted.
/**
 * @see somewhere
 */
interface I { [k: string]: any; [j: string]: any; }
