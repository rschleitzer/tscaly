// Slice 113: checkAndReportErrorForExtendingInterface. It is its own file because
// the fork is only reached when the name MISSES, and a fixture that stops earlier
// never gets there — which is what the battery's first run reported.
interface Iface { a: number; }
class Impl extends Iface {}
