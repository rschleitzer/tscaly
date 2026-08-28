// SLICE 86. resolveBaseTypesOfClass' one reachable question. A class WITH an
// `extends` clause never reaches the flags guard: getBaseConstructorTypeOfClass
// stops one call earlier, at isConstructorType.
class B {
}
class C extends B {
    [k: string]: any;
}
