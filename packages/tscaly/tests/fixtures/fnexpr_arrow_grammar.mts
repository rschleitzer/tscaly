// Slice 100: checkGrammarArrowFunction, whose two reports are the reason this
// file has the `.mts` extension — the first of them fires ONLY in a `.mts` or
// `.cts` file, and the test is a case-sensitive suffix on the whole path.
//
// ★★ THE SECOND REPORT NEEDED NO LINE MAP. `startLine != endLine` over the two
// ends of one `=>` token is a question about the text between them, and the walk
// that answers it is ecma_lines_differ. A line break inside the token's leading
// trivia is exactly what makes the two differ.
export {}

// One type parameter, no constraint, no trailing comma: the reserved syntax.
const reserved = <T>(t: T) => t

// The three shapes that are NOT reserved: two parameters, a trailing comma, and
// an explicit constraint.
const two = <T, U>(t: T, u: U) => t
const comma = <T,>(t: T) => t
const constrained = <T extends object>(t: T) => t

// A line terminator before the arrow.
const broken = (x: number)
    => x
