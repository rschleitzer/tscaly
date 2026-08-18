// slice 17, the keyword SWITCH rather than the suggestion. `is` written with an
// escape is still the `is` arm upstream, with its own span ending at the
// current token's start — read off the source it matches no arm and falls
// through to the generic message. The escaped keyword also carries
// Keywords_cannot_contain_escape_characters, which is next_token's and is
// unchanged by this slice.
\u0069s T
