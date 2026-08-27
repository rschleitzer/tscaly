// SLICE 79: the MODULE BLOCK arm of namesShareScope, and the second of its four
// kinds to get a witness.
//
// A namespace body is a ModuleBlock, so the `let` and the hoisted `var` share the
// namespace's scope and the reference is silent. ★The two remaining arms are
// measured rather than witnessed: KindSourceFile has its own fixture beside this
// one, and KindModuleDeclaration is UNREACHABLE — a VariableStatement's parent is a
// Block, a ModuleBlock, a SourceFile or a CaseBlock, never a ModuleDeclaration.
namespace N {
    let n1;
    {
        var n1;
    }
}
