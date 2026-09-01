// Slice 113: checkAndReportErrorForUsingNamespaceAsTypeOrValue, both arms — an
// uninstantiated namespace used as a value and the same name used as a type. Its
// own file for checker_name_not_found_interface.ts's reason.
namespace Ns { export type Z = number; }
let nv = Ns;
type Nt = Ns;
