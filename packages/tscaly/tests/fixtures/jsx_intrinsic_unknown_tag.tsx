// getIntrinsicTagSymbol's "Wasn't found" arm, TS2339. ★It is a MARKER fixture: the
// reference reaches the report through `getPropertyOfType`, whose miss falls back
// to a lookup on the global `Object` — and that fallback is this port's
// `global-object-property-augment` wall, one chapter over. The slice that removes
// it owns this row.
declare namespace JSX {
    interface IntrinsicElements { div: any }
}
const bad = <span />;
