// slice 38 — lookupEntity's `this` branch, and the reason its verdict is a fact
// about the PASS rather than about this text.
//
// `this.a.b = 1` is JSDeclarationKindProperty and not ThisProperty: that kind
// wants `bin.Left.Expression()` to BE the `this` keyword, and here it is
// `this.a`. So the deferred pass runs, getParentOfPropertyAssignment answers
// `this.a`, and lookupEntity takes its `this` branch — which asks
// getThisClassAndSymbolTable.
//
// ★★★ That question is answered against `b.thisContainer`, and the deferred pass
// restores only TWO of the three container registers: bindContainer put
// thisContainer back to nil when the walk of the SourceFile returned, and nothing
// in the pass writes it. So the branch answers null here and at every such
// assignment in the corpus, and the property is not declared. `this.c = 2` on the
// line below is the ThisProperty kind, which is still unported — it is in a
// SEPARATE unit for that reason.
// @Filename: thisexpando.js
class C {
    m() {
        this.a.b = 1;
    }
}
