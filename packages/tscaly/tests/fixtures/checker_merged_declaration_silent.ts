// Slice 65. The merges the head must say NOTHING about, and it is the half of the
// merged-declaration check that no positive fixture can measure.
//
// ★★★ EVERY LINE HERE IS A NEGATIVE CONTROL WITH A DIFFERENT REASON, which is why
// they are one file: a port that reported on every merge would pass
// checker_merged_declaration_export_mix.ts and this one is what catches it.
//
//   C   an exported class merged with an UNINSTANTIATED namespace — the class
//       occupies Type|Value, the namespace Namespace alone, and the spaces do not
//       meet. This is the row that makes getDeclarationSpaces' module arm a
//       measurement: drop its instance-state test and the namespace claims Value
//       as well, which invents a report here.
//   D   the same merge in the other ORDER, with the namespace instantiated — the
//       class comes FIRST, so checkModuleDeclaration's `node.Pos() <
//       first.Pos()` is false and TS2434 does not fire. Reverse the comparison and
//       this line reports while checker_namespace_merged_before_class.ts goes
//       quiet.
//   ov  a namespace merged with an OVERLOAD SET. getFirstNonAmbientClassOrFunctionDeclaration
//       wants a function declaration WITH A BODY, so the two signatures are skipped
//       and the implementation is found — and it is still above the namespace, so
//       nothing reports either way. Recorded as what it is: the term is transcribed
//       and this corpus cannot separate the two readings.
export {};
export class C {}
namespace C {}

class D {}
namespace D { export var y = 1; }

function ov(a: number): void;
function ov(a: string): void;
function ov(a: any): void {}
namespace ov { export var z = 1; }
