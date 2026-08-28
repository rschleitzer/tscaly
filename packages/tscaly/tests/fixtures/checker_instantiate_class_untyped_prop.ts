// SLICE 86. isThislessVariableLikeDeclaration's SECOND arm: no type annotation and
// an initializer is NOT thisless, where no annotation and no initializer is. One
// property, one mechanism — the minting branch reached from the property side
// rather than from the method side.
class C {
    [k: string]: any;
    a = 1;
}
