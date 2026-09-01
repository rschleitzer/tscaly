// Slice 105's chapter from the side that ANSWERS: getDeclaredTypeOfTypeAlias
// computes the alias's own annotation and getTypeFromTypeAliasReference hands it
// back, so a reference to an alias now has a type where the walk used to stop.
//
// ★★ THE ASSIGNMENTS ARE THE INSTRUMENT. An alias that answers and an alias that
// stops are both silent on the checker yardstick — the dump walk stops one arm up
// — so each name is USED in a position whose relation reports: `number` from
// `Al`, `number` through `Chain`, and `string` from `Merged`. A wrong declared
// type is a wrong TS2322, and a missing one is a stop.
//
// ★★ `Merged` is the input that makes `core.Find` a mechanism rather than an
// index: its FIRST declaration is the namespace and its second is the alias, so a
// control taking declaration zero reads a ModuleDeclaration, whose Type() is nil.
//
// ★ `Chain` is here for the memo as well as for the type: the second reference to
// `Al` goes through links.declaredType without re-entering the body.
declare namespace Merged { }
type Merged = string;

type Al = number;
type Chain = Al;

declare let m: Merged;
declare let a: Al;
declare let b: Chain;

function f(): void {
    let p: string = a;
    let q: string = b;
    let r: number = m;
    let ok: number = a;
}
