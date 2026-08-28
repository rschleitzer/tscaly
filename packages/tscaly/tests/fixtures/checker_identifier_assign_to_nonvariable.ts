// Slice 91. checkIdentifier's assignment-target block — the six-code chain, in
// the reference's own ORDER.
//
// ★★★ THE SCOPE IS NOT DECORATION. A top-level name of a SCRIPT file is merged
// into GLOBALS upstream, and this port's walk skips a global source file's locals
// (is_global_source_file, slice 79's g10) — so the same lines written at the top
// level resolve to NOTHING here, answer errorType, and report not one of these
// codes. The function body is what makes the symbols findable, and it is the
// difference between a fixture that gates this block and one that gates the
// globals table.
//
// ★★★ THE LAST TWO DECLARATIONS ARE WHAT MAKES THE ORDER MEASURABLE, and the
// first draft of this fixture did not have them. A chain is only an ordering
// claim where some symbol carries TWO of its flags; with one flag apiece, every
// permutation of the six tests answers the same six codes and the battery's
// order row came back UNGATED. A MERGED declaration is the input the claim needs:
// `E` is an enum and a namespace and must answer *enum*, `h` is a function and a
// namespace and must answer *function*.
function outer() {
  function f() {}
  f = 1;
  class C {}
  C = 2;
  enum E { A }
  E = 3;
  namespace N { export const q = 1; }
  N = 4;

  enum E2 { A }
  namespace E2 { export const r = 1; }
  E2 = 5;

  function h() {}
  namespace h { export const s = 1; }
  h = 6;
}
