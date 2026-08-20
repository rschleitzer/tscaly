declare namespace JSX {
    interface IntrinsicElements { div: any; span: any }
}
const a = <div id="one" tabIndex={2} data-x xlink:href="u" />;
const b = <span id="two" id="three" {...a} />;
