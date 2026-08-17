// The `this` parameter's modifier report spans the FIRST modifier's whole
// range, TRIVIA INCLUDED — the reference passes `modifiers.Nodes[0].Loc` with
// no skipRangeTrivia, which every neighbouring site does apply. The newline
// before `public` is what makes the two spellings differ.
class C {
  m(
    public this) {}
}
