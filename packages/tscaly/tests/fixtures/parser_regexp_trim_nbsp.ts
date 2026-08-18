// The trim DECODES, so a multi-byte trailing space steps back by its own size
// — the one place in the re-scan that is not a byte read. U+00A0 is two bytes.
var h = /ab ;
var i = 1;
