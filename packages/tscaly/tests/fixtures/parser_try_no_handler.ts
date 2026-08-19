// A `try` with neither catch nor finally: the reference reports its OWN message
// here, TS1472 ("'catch' or 'finally' expected"), not the generic TS1005. The
// yardstick compares the CODE, so "both are diagnostics and both stop the parse
// at the same token" is not an argument for using the generic one. §3.5bn.
try { };
