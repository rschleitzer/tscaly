// Slice 59. The collision head reached through checkImportBinding, and the
// type-only arm of needCollisionCheckForIdentifier is what the second line pins.
//
// ★★★ THE NODE THE HEAD SEES IS THE IMPORT **CLAUSE**, not the declaration: a
// default import passes the clause, so GetDeclarationContainer has to walk
// THROUGH it (KindImportClause is one of its six transparent kinds) to reach the
// SourceFile. Without that arm the container would be the import declaration and
// the report would not happen.
//
// ★★ A TYPE-ONLY IMPORT ERASES, so it cannot collide with anything: the second
// line is silent while the first reports TS2441. That is
// IsTypeOnlyImportOrExportDeclaration inside needCollisionCheckForIdentifier, and
// this pair is its only witness — the three import kinds it asks about are
// exactly the three kinds checkImportBinding is handed.
//
// ★ Both lines also carry a module specifier nothing resolves, so the reference
// adds a "cannot find module" the port cannot produce; diagcheck's relation is a
// subsequence, which is what makes a fixture with an unresolvable import usable
// at all.
export {};
import require from "./a";
import type exports from "./b";
