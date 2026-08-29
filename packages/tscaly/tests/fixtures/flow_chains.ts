// An optional chain is bound as `a && a.b`: the ROOT of the chain builds the
// first condition and everything above it is the true branch. A non-null
// assertion is in the chain but is not its root.
declare const o: { b?: { c?: number; f?(): number }, arr?: number[] } | undefined;

function chains(i: number) {
    o?.b;
    o?.b?.c;
    o?.b!.c;
    o?.arr?.[i];
    o?.b?.f?.();
    if (o?.b?.c) { o.b.c; }
    return (o?.b).c;
}
