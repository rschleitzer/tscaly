// parseEntityNameOfTypeReference passes Type_expected (1110) where a bare
// parseEntityName reports Identifier_expected (1003). The import type is what
// surfaced it — a qualifier is one of the reference's callers — but the defect
// was never about imports, and this file is where it is gated on its own.
type A = ;
type B = a.;
