// The lazy JSDoc parse runs on a FRESH parser (resolveJSDoc → getParser +
// initializeState), so the only context flags standing when the comment is read
// are the ones the SCRIPT KIND sets. NodeFlagsAmbient (1<<23) is put there by
// parseSourceFileWorker for a declaration file and must NOT reach a JSDoc node:
// the reference's carry 1<<22 alone, ours carried 1<<22|1<<23.
//
// Only the jsdoc yardstick can see this — the tree, the spans and the kinds all
// agree, and the disagreement is one bit in one word.

/** doc */
declare var x: number;

/** @see y */
declare function f(): void;

/** {@link x} */
interface I { a: number }
