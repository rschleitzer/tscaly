// Slice 113: the two branches getSuggestedLibForNonExistentName sits between. `Set`
// is a feature-map key AND a case-only miss away from a name in scope, so the early
// return is what decides between the caller's code and TS2552.
let sET = 1;
Set;
banaba;
let banana = 2;
