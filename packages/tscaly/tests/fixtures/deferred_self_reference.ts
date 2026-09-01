// A stage-2 finding of slice 115, and the only one whose symptom was a CLOCK: an IIFE
// that names the variable it initialises. The quick-type path checks the callee, which
// defers the arrow; the deferred check needs `x`, whose initializer checks the arrow
// again — and this port's deferred list was an ARRAY where the reference's is a SET, so
// the drain re-queued the same node forever. Two stage-2 units did not finish in sixty
// seconds. The gate is that this unit finishes at all.
function g() {
    const x = (() => { x; return 'x'; })();
}
