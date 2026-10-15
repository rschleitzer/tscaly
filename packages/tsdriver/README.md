tsdriver
========

Part of tscaly, the Scaly port of the TypeScript compiler: the top of the port: the compiler options, the program host,
incremental state and tsc's execute, watch and build.

The port is three packages, each built over the ones before it — `tsbase`,
`tscaly`, `tsdriver` — so that a change above a package does not compile it
again. Origin, license and layout are described in
[`../tscaly/README.md`](../tscaly/README.md); the license is Apache 2.0, see
[`LICENSE`](LICENSE) and [`NOTICE.txt`](NOTICE.txt).
