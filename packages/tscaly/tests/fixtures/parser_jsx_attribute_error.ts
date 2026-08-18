// Slice 20 — parseJsxAttributeValue's LAST line, the only report it makes:
// `= 1` is neither a string, nor `{`, nor `<`, so it is
// `'{' or JSX element expected` (1145) and the attribute gets NO value. The
// number is then read as the next attribute, which is what the recovery in
// parse_list does with a token no arm claims.
// @Filename: attrerror.tsx
const a = <input value=1 />;
