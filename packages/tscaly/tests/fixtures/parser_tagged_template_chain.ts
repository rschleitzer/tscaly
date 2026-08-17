// The OptionalChain flag on a tagged template is read STRAIGHT off the tag's
// flags — `tag.Flags&NodeFlagsOptionalChain != 0` — where the property-access
// and element-access rests next to it call tryReparseOptionalChain instead.
// That is the reference's own distinction, so it needs a case where the two
// answer differently: here the tag `a?.b` already carries the flag, so the
// tagged template inherits it and every node in the chain has 1 << 5.
a?.b`x`;

// ... against a tag that carries no such flag, so the tagged template gets none.
a.b`x`;

// ★ The line that actually separates the two readings, and the reason the first
// two do not: tryReparseOptionalChain differs from a plain flag read ONLY for a
// NonNullExpression whose descendant carries the chain. `a?.b!` is exactly that
// — its own flags are clear, its child's are set — so the reference leaves both
// it and the tagged template WITHOUT the flag, while a reparse would set it on
// both. Two nodes, one bit, and nothing else in the file can show it.
a?.b!`x`;
