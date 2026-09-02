// checkGrammarJsxElement's second report, TS17000, and it is the only one of the
// two that fires on the INITIALIZER's span rather than on the name's.
declare namespace JSX {
    interface IntrinsicElements { div: any }
}
const a = <div id={} />;
