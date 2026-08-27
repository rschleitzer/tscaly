// SLICE 81: TS2313, the report getBaseConstraintOfType exists to produce — and
// the fixture that shows it CANNOT FIRE YET, which is the slice's own measurement
// rather than an omission.
//
// Every circular constraint has to name a type parameter, so its constraint
// declaration is a TypeReference — and the type-node table's TypeReference arm is
// the work list's own head (`get-type-from-type-node 184`, 160 units), which needs
// resolveEntityName and therefore the globals table (§3.11). So
// getConstraintFromTypeParameter stops underneath, check_type_parameter's mark
// sees it, and no diagnostic is derived from an incomplete answer. The reference
// reports two TS2313 here; this port reports neither, which a SUBSEQUENCE cannot
// see — the battery's g-rows are what price it.
type Mutual<T extends U, U extends T> = T;
type SelfConstrained<T extends T> = T;
