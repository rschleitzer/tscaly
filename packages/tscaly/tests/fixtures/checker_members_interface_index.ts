// SLICE 85. The members chapter's first shape: a non-generic interface free of
// `this`, so its declared type carries no ObjectFlagsReference and
// resolveStructuredTypeMembers takes the class-or-interface arm.
//
// It has an index signature, so getIndexInfosOfType answers a non-empty list and
// checkIndexConstraints gets PAST its first two lines — which is the one place in
// this slice where the walk reaching further is visible as a stop of its own.
interface I {
    [k: string]: string;
    a: string;
}
