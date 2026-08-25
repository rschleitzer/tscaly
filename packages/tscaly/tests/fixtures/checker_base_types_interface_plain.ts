// The 1 411-unit shape one call further on: an interface with no `extends`.
// checkInheritedPropertiesAreIdentical asks getBaseTypes, which pushes a
// resolution frame, walks the declarations finding no heritage element, pops,
// and memoises an EMPTY list — so the answer is `< 2` and the assignability
// loop below it runs zero times. What stops the arm is checkIndexConstraints,
// i.e. resolveDeclaredMembers: the members dimension rather than the base one.
interface I {
    a: string;
}
