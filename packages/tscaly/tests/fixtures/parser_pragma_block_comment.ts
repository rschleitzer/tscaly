// KIND: only a SINGLE-LINE comment can carry a triple-slash directive. The
// reference decides on the comment range's Kind; here the two bytes that open
// it answer the same question, which is why collect_comment_ranges carries no
// kind. Without that test the block comment below reads as a triple-slash
// `<reference>` with no arguments and reports TS1084 — its third character is a
// slash, which is all the tripleSlash test looks at.
/*/ <reference /> */
