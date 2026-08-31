// SLICE 112: the literal widening is decided by isUnitType, so ONE literal
// return widens to its base type and a UNION of two does not — `() => number`
// against `() => "s" | 1`, which reads like a defect until they sit side by side.
function single() { return 1; }
function pair() { return 1; return "s"; }
function implicitUndefined() { if (1) { return 1; } }
