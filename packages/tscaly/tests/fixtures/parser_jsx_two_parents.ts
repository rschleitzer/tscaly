// "JSX expressions must have one parent element": the recovery hangs the second
// element off a BinaryExpression whose operator is a zero-width CommaToken. The
// reference builds that token with the FACTORY and assigns its Loc directly, so
// it never passes through finishNode — it carries neither the context flags nor
// ThisNodeHasError. Under the JSX script kind ours carried
// NodeFlagsJavaScriptFile (1<<16); same kind, same span, one bit apart. §3.5bo.
// @Filename: twoparents.jsx
const x = <div></div><span></span>;
