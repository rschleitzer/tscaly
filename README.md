# tscaly

A port of the TypeScript compiler — [microsoft/typescript-go](https://github.com/microsoft/typescript-go),
TypeScript 7 — from Go to [Scaly](https://scaly.io).

Scaly is a language with region-based memory management the compiler infers,
functions it checks to be pure, and loops that run in parallel because of
both. Everything written in Scaly before this was also designed in Scaly.
tscaly is the test on foreign ground: a large program nobody here designed,
with a garbage collector and goroutines in its bones, a golden-master suite
that makes conformance measurable, and published numbers to be measured
against.

What is ported: scanner, parser, binder, checker, the transformers, the
emitter with declaration emit, and the command-line driver. The language
service is not.

## Build

Install Scaly (`curl -fsSL https://scaly.io/install.sh | sh`, or see
[scaly.io/download](https://scaly.io/download/)), then from this directory:

```sh
scaly build packages/tscaly/0.1.0/tscaly_exec.scaly --release -o tscaly_exec
```

The compiler finds the package `tscaly` in `packages/` here and the standard
library in the installation. Compiling the package takes about 6.5 GB of
memory.

## Test

The tests compare the port with the reference, unit by unit, over the
reference's own corpus. They need the submodule and Go (to build the
reference's dump programs):

```sh
git submodule update --init packages/tscaly/_submodules/typescript-go
packages/tscaly/tests/run.sh
```

The runner compares the port with the reference unit by unit in six yardsticks
(scanner, parser, jsdoc, binder, flow, checker) at corpus stage 1;
`TSCALY_STAGE=2` adds the reference's submodule corpus.

## Measure

[`packages/tscaly/tools/bench/`](packages/tscaly/tools/bench/README.md) checks
all of VS Code with tsc, tsgo and this port, and says what was measured,
when, and what it cost — memory included.

## Layout and license

The sources are in `packages/tscaly/0.1.0/`; origin, the pinned upstream
commit and the statement of changes are in
[`packages/tscaly/README.md`](packages/tscaly/README.md).

Apache License 2.0, like the original: see [`LICENSE`](LICENSE) and
[`packages/tscaly/NOTICE.txt`](packages/tscaly/NOTICE.txt).
