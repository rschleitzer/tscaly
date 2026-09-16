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

tscaly reproduced all 355 of tsgo's diagnostics text-identically. The time is not
a comparison yet — most of it was the swap.
