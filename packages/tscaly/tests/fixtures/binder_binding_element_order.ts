declare const src: any;
function f() {
    var { implements = ++eval } = src;
    var [package = arguments++] = src;
}
