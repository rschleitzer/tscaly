// The `<` half of nextTokenIsOpenParenOrLessThan. A type-argument list after
// `import` is enough to make the keyword an expression, and the call rest reads
// both the arguments and the type arguments.
const a = import<string>("m");
