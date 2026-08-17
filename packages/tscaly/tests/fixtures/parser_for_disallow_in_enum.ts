// This is the fixture that makes slice 7's one UNREACHABLE control reachable.
//
// parse_enum_member clears DisallowInContext around the member's initializer,
// and slice 7 recorded that removing the clear "changes nothing … because
// DisallowInContext is only ever SET by a `for` initializer and `for` is
// unported in its entirety". It is not any more: a function expression inside
// a for initializer inherits the flag, so the enum member carries 1 << 10 and
// its initializer must not.
for (var f = function () { enum E { A = 1 } };;) ;
