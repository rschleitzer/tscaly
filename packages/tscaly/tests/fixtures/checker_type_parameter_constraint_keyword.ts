// Slice 60. The other side of checker_type_parameter_default_reference: a
// constraint that is a KEYWORD type, which the reference's own switch has no case
// for (kind_has_no_check_arm), so checkSourceElement walks into it and does
// nothing.
//
// ★★★ THE PAIR IS THE MEASUREMENT. This unit's tag stays at
// `get-symbol-of-declaration` / KindTypeParameter because nothing inside the
// constraint reports, while the TypeReference constraint one line down moves the
// tag to `check` / KindTypeReference. Neither file produces a diagnostic, so a
// yardstick counter cannot separate them and the pin over the two TAGS is the
// whole instrument — the same shape slice 56 needed for the half no diagnostic
// could see.
export {};
function g<T extends string>(): void {}
