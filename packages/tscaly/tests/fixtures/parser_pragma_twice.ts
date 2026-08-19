// ★★★ finishSourceFile runs a SECOND time when the file is reparsed for a
// top-level await, and the pragma pass runs with it — so both TS1084s appear
// TWICE. The dedup is against the LAST diagnostic only, which is why one bad
// directive would be swallowed and two are not.
/// <reference />
/// <reference foo="b" />
export {};
var a = ;
var b = await;
var c = ;
