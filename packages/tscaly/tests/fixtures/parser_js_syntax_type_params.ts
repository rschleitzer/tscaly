// Slice 24 — the TYPE-PARAMETER arm, reported at the LIST's range: inside the
// `<` and up to the full start of the `>`, which is why the trailing space in
// `<T >` and the trailing comma in `<T,>` belong to the span and cannot be
// derived from the elements.
//
// The nine hosts are the reference's; five of them are here, which is every
// shape the parser can reach with a type-parameter list in a JavaScript file.
// @Filename: type_params.js
function f<T>() {}

class C<T> {
    m<U>() {}
}

var g = function <V>() {};

var h = <W,>() => {};

function i<T >() {}
