// Slice 64. The two reports of this slice that no instrument can reach, each with
// its own obstacle — the shape slice 63's TS1107 fixture has, one dimension along.
//
// ★★★ BOTH OBSTACLES ARE THE SAME ONE FACT: NOTHING IN THIS PORT WALKS INTO A
// FUNCTION BODY. TS18038 (*for-await cannot be used inside a class static block*)
// needs the static block's body, which checkClassDeclaration stops before; and
// TS1103 (*for-await only within async functions and at the top levels of modules*)
// needs a for-of that is NOT in a top-level context, which is one inside a function
// body. Both lines below parse, both are what the reference reports on, and this
// port says nothing about either.
//
// ★★ THE FIXTURE IS NOT DEAD WEIGHT — IT IS THE PREMISE THE BATTERY LIFTS. g16 of
// controls-slice64.sh adds the body walk as a patch and both reports come alive on
// this unit; without the file the two arms could be deleted and no row would move.
//
// ★ TS1103's RELATED INFORMATION (*did you mean to mark this function as async*) is
// not built by this port, and no yardstick can see the difference: the oracle's C
// section is `pos end code` and nothing else.
class C { static { for await (const a of []) { } } }
function g() { for await (const b of []) { } }
