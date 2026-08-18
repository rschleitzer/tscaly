// Slice 20 — a merge-conflict marker inside JSX children. The marker is TRIVIA in
// the ordinary scan loop and a TOKEN here (ScanJsxTokenEx returns
// ConflictMarkerTrivia), which is why parseJsxChild has an arm for it that ends
// the child list — and why that arm cannot route through the scanner's shared
// conflict_marker_token, whose skip-trivia answer is -1.
// @Filename: conflict.tsx
const a = <div>
<<<<<<< HEAD
  ours
=======
  theirs
>>>>>>> branch
</div>;
