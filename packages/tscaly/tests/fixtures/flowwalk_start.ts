// The Start arm's hop into the containing function, and the container-extending
// loop in front of it. A closed-over `const` extends the flow container with no
// stop at all (isConstantVariable answers the first half of the disjunction);
// the outer parameter is reached through the hop.
function outer(p: string) {
    const k: string = p;
    function inner() {
        return k;
    }
    const arrow = () => k;
    return inner() + arrow() + p;
}
