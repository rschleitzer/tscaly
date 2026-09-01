// A stage-2 finding of slice 115: a member declared with SINGLE quotes is printed with
// single quotes. The flag rides on the SYNTHESIZED literal
// (createPropertyNameNodeForIdentifierOrLiteral stamps TokenFlagsSingleQuote from
// isSingleQuotedStringNamed) and getLiteralText reads it off the node, which is what
// the note in write_property_name_of_symbol used to deny.
//
// ★ `c` is the control: the same shape in DOUBLE quotes must stay double. And `b` is
// the ESCAPE half — inside a single-quoted name a double quote is written BARE, because
// the quote character is the escape TRIGGER and not the escape table.
declare namespace N {
    let a: { 'stage-0': number };
    let b: { 'has"double': number };
    let c: { "stage-1": number };
    let d: { 'has\'apostrophe': number };
}
