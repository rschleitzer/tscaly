# tools/bench — the port on a real workload

VS Code type-checked by tsc, tsgo and this port. Everything here runs OUTSIDE
the yardsticks; the yardsticks decide correctness, this measures time and
memory.

## ⚠ Read first

The port's footprint on the whole of VS Code is 9.4 GB with four checkers and
7.8 GB with one; building it peaks at 5.7 GB. Run a measurement only under
`runwatch.sh`, with a footprint limit well below the machine's memory, and
never while `build.sh` or a yardstick runs.

## Setup (outside the repository)

```bash
mkdir -p ~/repos/bench/bin && cd ~/repos/bench
git clone --depth 1 https://github.com/microsoft/vscode.git
(cd vscode && npm ci --ignore-scripts --no-audit --no-fund)
(cd <repo>/packages/tscaly/_submodules/typescript-go && go build -o ~/repos/bench/bin/tsgo ./cmd/tsgo)
python3 <repo>/packages/tscaly/tools/bench/mkscenario.py vscode vscode-paths.scenario --paths-only
```

`--ignore-scripts` skips the post-install steps, so the Electron typings are
missing: every compiler sees the same input and reports the same errors.

The scenario holds the ABSOLUTE paths of the default libraries in this
checkout's submodule. Make it anew when the checkout moves: an old scenario
then names libraries that are not there, and the port reports `Cannot find
global type 'Array'` and nine more instead of the project's errors.

## Measure

```bash
cd ~/repos/bench/vscode
/usr/bin/time -l ../bin/tsgo -p src/tsconfig.json --noEmit
/usr/bin/time -l ../bin/tsgo -p src/tsconfig.json --noEmit --singleThreaded
/usr/bin/time -l node --max-old-space-size=16384 node_modules/typescript/bin/tsc6 -p src/tsconfig.json --noEmit

cd <repo>
packages/tscaly/tools/bench/build.sh ~/repos/bench/bin/tscaly
cd ~/repos/bench
TSCALY_CHECKERS=4 <repo>/packages/tscaly/tools/bench/runwatch.sh vscode 900 16000 -- \
  ./bin/tscaly --bench-batch vscode-paths.scenario
```

`--paths-only` writes the file names without their texts; tscaly_exec reads a
text from disk the first time something asks for it.

`--bench-batch` replays the scenario without the file trees, the snapshots and
the shadow build that the driver yardstick needs (`--batch`).

`TSCALY_CHECKERS` is the number of checkers that check the files in parallel
(default one). `TSCALY_PROGRESS=1` prints `check <index> <path>` as each file
is checked, so a run that ends early says how far it came
(`grep -c '^check ' vscode.out`). The diagnostics are in the `==== OUTPUT`
block of `vscode.out`, in pretty format.

## Measured 2026-10-16

Apple M4 (four performance and six efficiency cores), 24 GB, macOS 26, freshly
restarted. VS Code at `0a9c4d28` (19 259 scenario files), tscaly at `5b47d46`
(0.1.3) built with Scaly 0.2.15, tsgo built from the submodule (typescript-go
7.0.2), tsc 6.0.3 on node 22. `/usr/bin/time -l`, footprint = its `peak memory
footprint`. One warm-up run, then rounds alternating between the binaries; the
median of each column and, in brackets, the range.

| | wall | user | sys | footprint |
|---|---|---|---|---|
| tsc 6.0.3 (3 runs) | 68.88 s (68.82–68.91) | 80.55 s | 2.2 s | 9.6 GB |
| tsgo (6 runs) | 6.85 s (6.43–7.16) | 34.26 s (29.21–37.33) | 1.8 s | 8.0 GB (7.74–8.06) |
| tsgo `--singleThreaded` (3 runs) | 17.87 s (17.78–18.29) | 21.01 s (20.42–24.62) | 0.9 s | 7.0 GB (6.90–7.14) |
| tscaly, 4 checkers (6 runs) | **4.90 s** (4.68–5.04) | **16.58 s** (15.73–17.15) | 2.8 s | 9.4 GB |
| tscaly, 1 checker (3 runs) | 10.34 s (10.33–10.37) | 13.12 s (13.08–13.14) | 2.6 s | 7.8 GB |
| tscaly, 4 checkers, PGO (3 runs) | **4.03 s** (3.98–4.03) | **13.29 s** (13.22–13.36) | 2.6 s | 9.4 GB |
| tscaly, 1 checker, PGO (3 runs) | 8.51 s (8.51–8.52) | 10.80 s (10.74–10.86) | 2.6 s | 7.8 GB |

Every tscaly run reports tsgo's 359 errors — the same file, line, column, code
and text — and one checker and four print byte-identical output. tsc 6.0.3
reports the same 359 and six more, implicit-`any` cycles (`TS7022`, `TS7024`)
in one test file.

With four checkers the port takes 0.72 of tsgo's wall time and half its user
time, and needs 1.4 GB more memory; with PGO, 0.59 of the wall time and 0.39 of
the user time. On one thread each, the port takes 0.58 of tsgo's wall time
(0.48 with PGO). The sys time is the page faults of the footprint.

## Building the compilers

The port and tsgo built from their sources on the same machine, 2026-10-16,
the median of three runs of `/usr/bin/time -l`. CPU is the user and system
time of every process of a build, memory the largest resident set of any one
process. A clean build starts with the language's standard library already
compiled.

- tscaly at `1fb6050`: `scaly build packages/tscaly/0.2.0/tscaly_exec.scaly`,
  with and without `--release`, Scaly 0.2.15. Its three packages are 326 000
  lines of Scaly: `tsbase` 69 000, `tscaly` 236 000 (the checker alone
  154 000), `tsdriver` 21 000.
- tsgo from the submodule (`2bd066d87`): `go build ./cmd/tsgo`, Go 1.26.6;
  276 000 lines of the module's own Go in 72 packages, the checker's package
  60 000.

| build | wall | CPU | memory |
|---|---|---|---|
| tscaly, release | 38.0 s | 36.7 s | 5.5 GB |
| tscaly, debug | 30.7 s | 40.6 s | 5.7 GB |
| tsgo | 44.4 s | 188.2 s | 2.0 GB |
| tsgo, `-p 1` | 54.7 s | 164.4 s | 2.0 GB |

From scratch the port builds in less wall time than tsgo and with a fifth of
its CPU. It needs almost three times the memory: the compiler is one process
that holds a whole package, and a release build the whole program. A debug
build generates the code of a large package in parts, in worker processes,
so its CPU exceeds its wall time. (`-p 1` builds one Go package at a time;
the Go compiler still runs its back end on several threads.)

After a change:

| changed | tscaly, release | tscaly, debug | tsgo |
|---|---|---|---|
| nothing | 0.5 s | 0.5 s | 0.5 s |
| the checker (a comment line appended) | 35.6 s | 24.6 s | 7.4 s |

tsgo compiles the checker's package again and links. The port compiles the
whole package the checker belongs to again, 236 000 lines, planned on one
thread; `tsbase` and `tsdriver` come from the cache, `tsdriver` because it is
keyed on the interface of `tscaly`, which a change inside a body leaves as it
was. A release build then optimizes and generates the code of the whole
program again, as one module: that is the binary measured above.

tsc is not in these tables. Its build type-checks the compiler and bundles
it as JavaScript; no machine code is made until node runs it, so its few
seconds do not answer the same question.

## Profile-guided optimization

Two switches of `scaly build`: an instrumented build, trained on the scenario,
and a build with the profile. The training run uses one checker. The profile
needs the `llvm-profdata` of the LLVM the toolchain is built on (21; on macOS
Homebrew's `llvm@21`). Measured above, 2026-10-16: the instrumented build takes
46 s, the training run 8 s, the build with the profile 84 s.

```bash
ulimit -s 65520
mkdir -p ~/repos/bench/pgo
cd <repo>
scaly build packages/tscaly/0.2.0/tscaly_exec.scaly --pgo-train -o ~/repos/bench/bin/tscaly_pgogen
(cd ~/repos/bench && LLVM_PROFILE_FILE=$PWD/pgo/tscaly-%p.profraw \
  ./bin/tscaly_pgogen --bench-batch vscode-paths.scenario > /dev/null)
llvm-profdata merge -o ~/repos/bench/pgo/tscaly.profdata ~/repos/bench/pgo/*.profraw
scaly build packages/tscaly/0.2.0/tscaly_exec.scaly --pgo ~/repos/bench/pgo/tscaly.profdata -o ~/repos/bench/bin/tscaly_pgo
```

PGO stays out of the default build: name it whenever its rows are quoted.
