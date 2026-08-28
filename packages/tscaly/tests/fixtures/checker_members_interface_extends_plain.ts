// SLICE 85. The base loop with NOTHING to inherit but properties: no index
// signature anywhere, so checkIndexConstraints returns at its first line and the
// whole arm completes. What this fixture pins is the loop RUNNING — it is the
// only shape here that calls getPropertiesOfType and addInheritedMembers.
interface A {
    a: string;
}
interface B extends A {
    b: string;
}
