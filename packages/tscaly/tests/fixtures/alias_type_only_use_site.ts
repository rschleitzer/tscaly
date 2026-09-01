// Slice 114: TS1361/TS1362 — a type-only alias used as a VALUE, and the fork
// between the two codes is the KIND of the declaration that made the alias
// type-only, not anything about the use site.
//
// ★ The last two lines are the NEGATIVE half: IsValidTypeOnlyAliasUseSite says an
// `implements`/`extends`-on-an-interface clause is a valid site, so a type-only
// alias named there may not report.
import type { A } from "./m";
import { type B } from "./m";
A();
B();
interface I extends A {}
