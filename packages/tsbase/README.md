tsbase
======

Part of tscaly, the Scaly port of the TypeScript compiler: the bottom of the port: the constant tables, the scanner, the AST
and the parser with what they need.

The port is three packages, each built over the ones before it — `tsbase`,
`tscaly`, `tsdriver` — so that a change above a package does not compile it
again. Origin, license and layout are described in
[`../tscaly/README.md`](../tscaly/README.md); the license is Apache 2.0, see
[`LICENSE`](LICENSE) and [`NOTICE.txt`](NOTICE.txt).
