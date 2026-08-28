// checkClassStaticBlockDeclaration: the grammar modifier check plus the walk into
// the block's own statements.
class C {
    static { let x = 1; }
}
