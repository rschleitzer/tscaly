// ★★★ THE LAST DIRECTIVE WINS, AND THIS FILE IS THE ONLY INPUT THAT CAN SAY SO.
// processPragmasIntoFields keeps its position test under the comment *"_last_ of
// either nocheck or check in a file is the winner"*, and the port's own note used
// to claim nothing here reads that.
//
// ★★★ It was read the other way FIRST, and the mistake is §3.5's struct-embedding
// entry from the wrong side: the single-line pragma arm builds `ast.Pragma{Comment
// Range: commentRange, Name: pragmaName}` with no TextRange, so `pragma.TextRange.
// Pos()` looks like a zero value and the test looks like it can never fire. It
// cannot be a zero value — `Pragma` EMBEDS `CommentRange`, which embeds
// `core.TextRange`, so that IS the comment's own range, promoted. A named field
// cannot be promoted, so nothing in the ported text carries the hint.
//
// So this file is NOT checked: the `@ts-nocheck` below wins and the parameter
// gets no TS7006. Under the first-wins reading it does, and this is the one
// fixture that goes red.
// @ts-check
// @ts-nocheck
function f(a) { }
