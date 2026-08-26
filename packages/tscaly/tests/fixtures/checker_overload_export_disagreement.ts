// ★★ checkFlagAgreementBetweenOverloads' Export arm (TS2383). someNodeFlags and
// allNodeFlags are an OR and an AND over the same declarations, so their XOR is
// exactly the set of flags some but not all of them carry — here `export`.
//
// ★ The canonical overload is the IMPLEMENTATION when it shares a container with
// the first overload, which it does here, so the deviation is measured against
// the un-exported body and the exported signature is what reports.
export function h(a: string): void;
function h(a: number): void;
function h(a: any): void { }
