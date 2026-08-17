// The HEAD route of the same claim as parser_template_untagged_escape: an
// invalid escape in the head chunk of an untagged template. Matches since slice
// 13b, and red if the re-scan stops passing `!is_tagged_template`.
var b = `\u${1}c`;
