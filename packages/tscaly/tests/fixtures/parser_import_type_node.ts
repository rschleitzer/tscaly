// The import TYPE. Same keyword, a different production and a different node —
// and it sets the same PossiblyContainsDynamicImport bit the call does, which is
// why the two arrive in one slice.
type A = import("m");
type B = typeof import("m");
type C = import("m").X<number>;
type D = typeof import("m").X;
