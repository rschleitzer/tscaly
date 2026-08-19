// The argument store is a MAP, so a repeated name overwrites: `pragma.Args` is
// `map[string]PragmaArgument` and the loop assigns into it. A flat table whose
// lookup answers the FIRST match keeps the wrong one, and only the two
// arguments whose VALUE is read can show it — no-default-lib, which swallows
// the directive when it is "true", and resolution-mode, whose value decides
// TS1453.
//
// First line: the reference reads "true", swallows the directive and says
// nothing; first-wins reads "false" and reports TS1084.
// Second line: the reference reads "bogus" and reports TS1453 over it;
// first-wins reads "import" and says nothing.
/// <reference no-default-lib="false" no-default-lib="true" />
/// <reference types="a" resolution-mode="import" resolution-mode="bogus" />
