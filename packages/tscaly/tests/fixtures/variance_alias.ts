// Slice 106. checkTypeParameterDeferred's TYPE-ALIAS arm, and the objectFlags
// test that decides it.
//
// ★★★ THE ARM IS ONE CONDITION WITH TWO SIDES AND THE CORPUS ONLY HAD ONE.
// `parser_types_generic.ts` carries `type F<in T> = T` three times over, which is
// the side that REPORTS — an alias whose declared type is neither Anonymous nor
// Mapped. Nothing anywhere reaches the side that does NOT, so without this file
// the test reads as a formality and a control that forced it TRUE would move
// nothing.
//
// ★★ THE FOUR SILENT ALIASES ARE SILENT FOR TWO DIFFERENT REASONS AND ONLY THE
// STOP LOG TELLS THEM APART: a declared type this port CAN build and that carries
// ObjectFlagsAnonymous is the reference's own answer, while a declared type it
// stops on leaves the mark moved and the report is withheld. Both print nothing
// in the C section, which is why the mark's control is the row that separates
// them — with the mark dropped, an errorType has objectFlags 0 and every one of
// them INVENTS a TS2637.
//
// ★★★ `Bad` IS WHAT MAKES THE LOSS VISIBLE IN THE REFERENCE'S OWN DUMP. Fn and
// Obj pass the alias arm AND the variance comparison, so the reference is silent
// on them for a reason this port cannot claim; `Bad` uses a COVARIANT parameter
// contravariantly, so the reference answers TS2636 exactly where this port
// records `create-marker-type` — one line of the C section that is the wall,
// named by the instrument on both sides.
export {};
type Prim<in T> = T;
type Fn<in T> = (x: T) => void;
type Obj<out T> = { x: T };
type Bad<out T> = (x: T) => void;
type Mapped<in T> = { [K in keyof T]: T[K] };
