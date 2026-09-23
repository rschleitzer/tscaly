# tools/bench — the port on a real workload

The Hejlsberg demo: VS Code type-checked by tsc, tsgo and this port. Everything
here runs OUTSIDE the yardsticks; the yardsticks decide correctness, this measures
time and memory.

## ⚠ Read first

**A full VS Code run peaked at a 23 GB footprint on a 24 GB machine and swapped**
(2026-09-16). Run it only under `runwatch.sh` with a footprint limit well below
the machine's memory, never while `build.sh` or a yardstick runs, and prefer a
sub-project while the port's memory is what it is.

## Setup (outside the repository)

```bash
mkdir -p ~/repos/bench && cd ~/repos/bench
git clone --depth 1 https://github.com/microsoft/vscode.git
(cd vscode && npm ci --ignore-scripts --no-audit --no-fund)
(cd <repo>/packages/tscaly/_submodules/typescript-go && go build -o ~/repos/bench/tsgo ./cmd/tsgo)
```

`--ignore-scripts` skips the post-install steps, so the Electron typings are
missing: every compiler sees the same input and reports the same ~355 errors.

## Measure

```bash
cd ~/repos/bench/vscode
/usr/bin/time -l ../tsgo -p src/tsconfig.json --noEmit --extendedDiagnostics
/usr/bin/time -l ../tsgo -p src/tsconfig.json --noEmit --singleThreaded
/usr/bin/time -l node --max-old-space-size=16384 node_modules/typescript/bin/tsc6 -p src/tsconfig.json --noEmit

cd <repo>
packages/tscaly/tools/bench/build.sh ~/repos/bench/tscaly_exec_o2
python3 packages/tscaly/tools/bench/mkscenario.py ~/repos/bench/vscode ~/repos/bench/vscode.scenario
cd ~/repos/bench
TSCALY_PROGRESS=1 <repo>/packages/tscaly/tools/bench/runwatch.sh vscode 1800 16000 -- \
  ./tscaly_exec_o2 --bench-batch vscode.scenario
```

`--paths-only` writes the file names without their texts; tscaly_exec reads a text
from disk the first time something asks for it (vs/editor: 2.7 → 1.9 GB).

`--bench-batch` replays the scenario without the file trees, the snapshots and the
shadow build that the driver yardstick needs (`--batch`); on a one-file config that
is 1.66 → 0.92 GB of harness alone.

`TSCALY_PROGRESS=1` prints `check <index> <path>` as each file is checked, so a
run that ends early says how far it came (`grep -c '^check ' vscode.out`). The
diagnostics are in the `==== OUTPUT` block of `vscode.out`, in pretty format.

## Measured 2026-09-16 (M-series, 10 cores, 24 GB)

| | wall | memory |
|---|---|---|
| tsc 6.0.2 | 63.8 s | 5.2 GB RSS, 8.8 GB peak (dies at node's default 4 GB heap) |
| tsgo 7.0.2, default | 9.4 s | 7.2 GB RSS, 7.9 GB peak |
| tsgo `--singleThreaded` | 19.3 s | 6.3 GB |
| tscaly `-O2` | 492 s, swapping | 23.1 GB peak |

That run reported 709 errors: all 355 of tsgo's, text-identical, and 354 more that
are port defects (an earlier version of this line read the intersection as equality).
The time is not a comparison yet — most of it was the swap.

## Measured 2026-09-17 (same machine, `--paths-only` scenario)

| | wall | CPU | memory |
|---|---|---|---|
| tscaly after the memory work | 470 s | 392 s | 10.85 GB footprint |
| tscaly after the project-size indexes (slice 312) | 105.5 s | 97 s | 11.2 GB footprint |

630 errors: tsgo's 355 and 275 port defects (the `@xterm/addon-*` typings' self-augmenting
`declare module`, JSON modules outside the scenario, and what follows from them).

## Measured 2026-09-23 (same machine, idle, tree at `5a82fcd5`)

The whole of VS Code, `--bench-batch vscode-paths.scenario`, tsgo built from the
submodule (`-p src/tsconfig.json --noEmit`, default settings). One warm-up run, then
rounds alternating between the binaries; `/usr/bin/time -l`, footprint = its
`peak memory footprint`. Every tscaly run reports tsgo's 355 errors — the same file,
line, column and code — and `TSCALY_CHECKERS=1` and `=4` print identical text.

**The default build** (`build.sh`, LTO, no PGO):

| | wall | user | sys | footprint |
|---|---|---|---|---|
| tsgo | 6.55 / 7.21 s | 30.5 / 35.7 s | 1.9 / 2.5 s | 7.6 / 7.8 GB |
| tscaly, `TSCALY_CHECKERS=4` | **5.22 / 4.81 s** | **16.2 / 16.3 s** | 3.0 / 2.9 s | 8.7 GB |
| tscaly, one checker (the default) | 10.72 / 10.43 s | 13.1 / 13.0 s | 2.4 / 2.4 s | 7.2 GB |

**With PGO** (the recipe below, trained on this scenario with one checker; a second
series the same evening):

| | wall | user | sys | footprint |
|---|---|---|---|---|
| tsgo | 6.19 / 6.51 s | 27.8 / 30.1 s | 1.9 / 1.9 s | 7.9 / 7.7 GB |
| tscaly, 4 checkers, no PGO | 5.13 / 5.01 s | 16.3 / 16.9 s | 3.1 / 3.0 s | 8.7 GB |
| tscaly, 4 checkers, **PGO** | **3.95 / 4.17 s** | **13.1 / 13.5 s** | 2.7 / 3.2 s | 8.7 GB |
| tscaly, one checker, PGO | 8.63 / 8.24 s | 10.5 / 10.5 s | 2.3 / 2.4 s | 7.2 GB |

Against 2026-09-18 (6.0 s against tsgo's 6.5 s, four checkers) the wall clock moved
with the parse pool, binding on the pool and file discovery inside the parse tasks;
the footprint with four checkers came down from 9.2 to 8.7 GB and is still about
0.9 GB above tsgo's. The sys time is the page faults of that footprint. PGO takes
another fifth off wall and user time and leaves the output and the memory unchanged
— it stays out of the default build (below); name it whenever these rows are quoted.

## Measured 2026-09-23 on the second Mac (M1 Pro, 8P+2E, 32 GB)

A fresh VS Code clone (`0a9c4d28`, 19 259 scenario files, 359 errors in both
compilers, identical file, line, column and code), the default build, three
alternating rounds. The first series found `invoke_once`'s linear walk of the
visit table in 93 % of all samples — VS Code's newer sources run one inference
over far more than "a handful" of pairs — and the table has an index since:

| | wall | user | sys | footprint |
|---|---|---|---|---|
| tsgo | 8.01–8.16 s | 36.5–40.0 s | 2.1–2.4 s | 7.7–8.1 GB |
| tscaly x4, linear visit table | 20.92–21.07 s | 37.4–37.6 s | 3.8–3.9 s | 9.3 GB |
| tscaly x1, linear visit table | 29.54–29.87 s | 32.9–33.3 s | 3.4–3.7 s | 7.7 GB |
| tscaly x4, indexed | **6.51–6.53 s** | 22.4–23.4 s | 3.9 s | 9.4 GB |
| tscaly x1, indexed | 14.62–15.00 s | 18.3–18.9 s | 3.6–3.7 s | 7.8 GB |

Output byte-identical across both builds and both checker counts. The profile
after the index is flat (the top entry, `AddressIndex::find`, at about 6 %).

## Profile-guided optimization — a reserve for the demo, not the default build

Tried 2026-09-18 and kept out of every default build on purpose: the port ships as
`.ll`, and a reviewer who builds it should measure what we measure without a
training run. Bring it out for the real demo only, and name it whenever it is used.

| VS Code, three alternating rounds, output identical | user | real |
|---|---|---|
| today's bench build | 10.56 s | 12.3 s |
| `opt` told the host triple | 10.04 s | 12.0 s |
| host triple + PGO trained on VS Code | 8.15 s | 9.7 s |

The profile transfers: trained on VS Code alone, the TypeScript repository's own
`src/compiler` (305 files, 22 errors = tsgo) goes 0.89 → 0.71 s user.

```bash
source tools/llvm-env.sh
T=-mtriple=$("$LLC" --version | awk '/Default target/{print $3}')
RT=$LLVM_PREFIX/lib/clang/20/lib/darwin/libclang_rt.profile_osx.a
LTO_OPT_FLAGS="$T --pgo-kind=pgo-instr-gen-pipeline" LINK_EXTRA=$RT \
  packages/tscaly/tools/bench/build.sh ~/repos/bench/bin/tscaly_pgogen
(cd ~/repos/bench && LLVM_PROFILE_FILE=$PWD/pgo/tscaly-%p.profraw \
  ./bin/tscaly_pgogen --bench-batch vscode-paths.scenario > /dev/null)
"$LLVM_PREFIX/bin/llvm-profdata" merge -o ~/repos/bench/pgo/tscaly.profdata ~/repos/bench/pgo/*.profraw
LTO_OPT_FLAGS="$T --pgo-kind=pgo-instr-use-pipeline --profile-file=$HOME/repos/bench/pgo/tscaly.profdata" \
  packages/tscaly/tools/bench/build.sh ~/repos/bench/bin/tscaly_pgo
```

★ The triple is required, not optional: the seed's IR carries none, and the
instrumentation then emits COMDATs that MachO cannot lower (`llc` aborts). ★ Take the
triple from the host (`llc --version`), never write one in — the same build must work
on an x86_64 machine. ★ The CPU Bottlenecks shares of `tools/xctrace-bottleneck.py`
cannot compare two builds: one build read 46 % and 35 % useful in two recordings.
Compare alternating user times.
