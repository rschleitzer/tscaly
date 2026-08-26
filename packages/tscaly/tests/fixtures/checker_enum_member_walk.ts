// Slice 65. The enum's members walk, and the arm it forced into this slice.
//
// ★★★ THE ORDER OF THE ENUMS IN THIS FILE IS THE INSTRUMENT. record_unported keeps
// the FIRST report, and an enum declaration's own stop (computeEnumMemberValues)
// comes after its members walk — so the file's tag is the first thing any of its
// enums says. With the initializer-bearing enum FIRST the tag is
// `check-binary-expression` (`check-expression` before slice 70 gave the dispatch
// its arms, `get-number-literal-type` until slice 71 gave the numeric one a
// type), which is a MEMBER's report; put the plain one first and the
// tag becomes `compute-enum-member-values`, which is the DECLARATION's, and removing
// the members walk then moves nothing. The first draft of this fixture had them the
// other way round and gated nothing.
//
// ★★ AN ENUM MEMBER WITH NO INITIALIZER IS A COMPLETED CHECK. `enum Plain { A, B, C }`
// is finished three times over; `X = 1` stops at the expression, and the
// auto-numbering that would give A its value is not checkEnumMember's business at
// all — computeEnumMemberValues does it from the declaration arm.
//
// ★★ THE MEMBERS WALK IS THE LINE AFTER THE HEAD, so before slice 65 no enum member
// had ever been handed to checkSourceElement. Had checkEnumMember not landed in the
// same slice, every enum in the corpus would have taken the bare `check` tag —
// naming the container's walk as the blocker of the member, and regrowing the row
// slice 64 emptied.
//
// ★ TS18024 is the arm's own report, and its span cannot be got wrong: an EnumMember
// is in error_range_uses_declaration_name, so `c.error(node, …)` and a report on the
// name resolve to the same range. Written as the reference writes it.
export {};
enum WithValues { X = 1, Y = X + 1 }
enum Plain { A, B, C }
enum HasPrivate { #p = 1 }
const enum Konst { K }
