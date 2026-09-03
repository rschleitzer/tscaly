// getIntrinsicTagSymbol's "Wasn't found" arm, TS2339. ★It was a MARKER fixture for
// the `global-object-property-augment` wall: the reference reaches the report
// through `getPropertyOfType`, whose miss falls back to a lookup on the global
// `Object`. Slice 127 landed that fallback, so what is left in front of this row is
// the JSX chapter's own wall and not the lookup's.
declare namespace JSX {
    interface IntrinsicElements { div: any }
}
const bad = <span />;
