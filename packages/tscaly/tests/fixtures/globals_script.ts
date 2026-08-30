// Slice 104: the globals table's BUILDABLE HALF, seen from the merge loop.
//
// This file is deliberately NOT a module. initializeChecker merges a non-module
// file's top-level locals into the globals table, and resolve_name's walk SKIPS a
// global source file's locals for exactly that reason — so before this slice every
// name below missed on BOTH routes and stopped at `resolve-name-not-found`.
//
// The product is an ABSENCE: two stops that are gone. The TS2322 at the bottom is
// the pin that says the check still runs to the same place.
var top: number = 1
type Alias = number
var viaTable: number = top
var wrongLiteral: number = "no"
function reader(): number { return top }
