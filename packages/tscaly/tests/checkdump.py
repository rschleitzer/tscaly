#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
#
# checkdump.py — the BINDER oracle's own gate.
#
# ★★★ WHY AN INSTRUMENT NEEDS ONE. The other three yardsticks compare two dumps
# and a defect in either half shows up as a disagreement. The symbols dump cannot
# be read that way yet — our half reports `unported` for every unit while the
# binder is being ported — so for as long as that lasts the reference half is
# unchecked by the suite itself. This script checks it against its own contract
# instead, and it EARNED its place: the first draft of `oracle/symbols.go`
# referenced symbol indices it never defined on 24 of 296 fixtures, because a
# locals table can name a symbol no walked node owns and those got their index
# while the tables were already being printed. Reading the code did not find that;
# this did.
#
# Two independent checks, and each is a claim about the dump:
#
#   INVARIANTS   every symbol index that is REFERENCED is also DEFINED by an `s`
#                line; indices are dense from 0; every table is declared exactly
#                once, its ids are dense from 0, and its `count` equals the number
#                of `e` lines that follow it; every table id that a node or a
#                symbol names is printed.
#   DETERMINISM  N runs over the same file produce byte-identical output. The
#                reference's SymbolTable is a Go map whose iteration order is
#                deliberately randomised, so this is what makes "the tables are
#                sorted by name" a checked claim rather than an intention — and
#                the sort is the ONE normalisation this dump has.
#
# Usage:
#   packages/tscaly/tests/checkdump.py [--oracle PATH] [--runs N] [FILE ...]
#
# With no FILE arguments it checks all of tests/fixtures. The oracle defaults to
# tests/out/oracle_symbols, which tests/run.sh builds — this script does not build
# it, and says so rather than answering about a binary that is not there.

import os
import subprocess
import sys

PKG = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def dump(oracle, path):
    proc = subprocess.run([oracle, path], stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE)
    if proc.returncode != 0:
        return None, f"the oracle exited {proc.returncode}: " \
                     f"{proc.stderr.decode('utf-8', 'replace').strip()}"
    return proc.stdout, None


def invariants(out: bytes):
    """The problems this dump has, as a list of sentences. Empty is a pass."""
    defined, refs = set(), set()
    named_tables = []                 # table ids a node or a symbol points at
    declared, counted, entries = {}, {}, {}
    current = None
    problems = []

    for raw in out.split(b"\n"):
        if not raw:
            continue
        f = raw.split(b" ")
        rec = f[0]
        try:
            if rec == b"n":
                # n <kind> <pos> <end> <sym|-> <locals|->
                if f[4] != b"-":
                    refs.add(int(f[4]))
                if f[5] != b"-":
                    named_tables.append(int(f[5]))
            elif rec == b"s":
                # s <idx> <flags> <parent|-> <vdPos|-> <vdEnd|-> <members|-> <exports|-> <name>
                defined.add(int(f[1]))
                if f[3] != b"-":
                    refs.add(int(f[3]))
                for v in (f[6], f[7]):
                    if v != b"-":
                        named_tables.append(int(v))
            elif rec == b"d":
                refs.add(int(f[1]))
            elif rec == b"x":
                refs.add(int(f[1]))
                refs.add(int(f[2]))
            elif rec == b"t":
                current = int(f[1])
                declared[current] = declared.get(current, 0) + 1
                counted[current] = int(f[2])
                entries.setdefault(current, 0)
            elif rec == b"e":
                refs.add(int(f[1]))
                if current is None:
                    problems.append("an `e` line before any `t` line")
                else:
                    entries[current] += 1
            elif rec in (b"f", b"c", b"B"):
                pass
            else:
                problems.append(f"unknown record {rec.decode()!r}")
        except (IndexError, ValueError):
            problems.append(f"malformed line: {raw.decode('utf-8', 'replace')!r}")

    missing = sorted(refs - defined)
    if missing:
        problems.append(f"symbol indices referenced but never defined: {missing}")
    if defined and sorted(defined) != list(range(len(defined))):
        problems.append("symbol indices are not dense from 0")
    for tid, n in sorted(declared.items()):
        if n != 1:
            problems.append(f"table {tid} is declared {n} times")
    for tid, n in sorted(counted.items()):
        if entries.get(tid, 0) != n:
            problems.append(f"table {tid} says {n} entries and has {entries.get(tid, 0)}")
    unprinted = sorted(set(named_tables) - set(declared))
    if unprinted:
        problems.append(f"table ids named but never printed: {unprinted}")
    if declared and sorted(declared) != list(range(len(declared))):
        problems.append(f"table ids are not dense from 0: {sorted(declared)}")
    return problems


def main(argv):
    oracle = os.path.join(PKG, "tests/out/oracle_symbols")
    runs = 3
    files = []
    i = 1
    while i < len(argv):
        if argv[i] == "--oracle":
            oracle = argv[i + 1]; i += 2
        elif argv[i] == "--runs":
            runs = int(argv[i + 1]); i += 2
        else:
            files.append(argv[i]); i += 1

    if not os.access(oracle, os.X_OK):
        print(f"checkdump.py: no oracle at {oracle} — run tests/run.sh first, which"
              " builds it.\nThis is a missing input, not a result.", file=sys.stderr)
        return 2

    if not files:
        fx = os.path.join(PKG, "tests/fixtures")
        files = sorted(os.path.join(fx, n) for n in os.listdir(fx)
                       if n.endswith((".ts", ".tsx")))

    bad_inv = bad_det = failed = 0
    for path in files:
        out, err = dump(oracle, path)
        if err:
            failed += 1
            print(f"  {os.path.basename(path)}: {err}")
            continue
        problems = invariants(out)
        if problems:
            bad_inv += 1
            print(f"  INVARIANT {os.path.basename(path)}: " + "; ".join(problems))
        for _ in range(runs - 1):
            again, err = dump(oracle, path)
            if err or again != out:
                bad_det += 1
                print(f"  NONDETERMINISTIC {os.path.basename(path)}"
                      f"{': ' + err if err else ''}")
                break

    total = len(files)
    print(f"checkdump: {total} files, {runs} runs each — "
          f"{bad_inv} invariant failures, {bad_det} nondeterministic, "
          f"{failed} could not be dumped")
    return 0 if bad_inv == bad_det == failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
