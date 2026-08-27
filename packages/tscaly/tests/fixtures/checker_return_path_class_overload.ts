// SLICE 82: TS7010 on a CLASS member, and the file that made the slice's second
// finding visible.
//
// The battery's g15 predicted an INVENTION — drop isPrivateWithinAmbient and the
// port reports where the reference does not — and came back silent. Chasing that
// silence found the cause one chapter over: checkClassDeclaration's
// `c.checkSourceElements(node.Members())` was not in this file at all, under a note
// reading *the call above always reports, so the MEMBERS of a class stay behind this
// arm*. record_unported marks and does NOT abort, so that line runs upstream
// whatever the class arm did — the same shape slice 77 lifted out of
// checkInterfaceDeclaration.
class OverloadedMember {
    m(x: string);
    m(x: number);
    m(x: any) { return x; }
}
