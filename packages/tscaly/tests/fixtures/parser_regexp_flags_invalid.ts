// An invalid UTF-8 byte where a flag would be. The reference stops the flags
// loop on RuneError; this port stops there too, and the fixture exists to show
// whether that arm is separable from the identifier-part test below it.
var m = /ab/€;
var n = 3;
