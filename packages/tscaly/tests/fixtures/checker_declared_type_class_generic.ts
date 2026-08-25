// The ORDER proof, as a fixture. checkTypeParameters runs before
// checkExportsOnMergedDeclarations in both arms, so a GENERIC class is claimed by
// the type-parameter row and never reaches the declared-type head at all. That is
// why the symbol-flag histogram measured zero TypeParameter units at a head whose
// switch has an arm for exactly that.
class G<T> {
    a: T;
}
