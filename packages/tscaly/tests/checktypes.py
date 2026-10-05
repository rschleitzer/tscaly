#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
#
# checktypes.py — the CHECKER oracle's own gate, and checkdump.py's argument one
# phase later.
#
# ★★★ WHY AN INSTRUMENT NEEDS ONE. Four yardsticks compare two dumps, so a defect
# in either half shows up as a disagreement. The types dump cannot be read that way
# for as long as our half reports `unported` for every unit — which is the whole
# checker dimension — so the reference half would otherwise be unchecked by the
# suite itself. checkdump.py earned its place on its first run (24 of 296 fixtures
# referenced a symbol index the dump never defined); this is the same argument for
# an oracle that is strictly more machinery: a STUB program of forty methods, a
# type walk TRANSCRIBED from the reference's own baseline walker, and one exclusion
# that is ours.
#
# Four checks, each a claim the dump makes:
#
#   SHAPE        every line is `C <pos> <end> <code>` or `T <kind> <pos> <end>
#                <type>`; the numbers parse; a type string is never empty; a
#                diagnostic code is positive.
#   SPANS        0 <= pos <= end <= len(file). A span outside the file is the
#                class §3.5bw records for an approximated one: a wrong answer that
#                looks like a right one.
#   ORDER        every C line precedes every T line, and the C lines are
#                nondecreasing in pos. The first is the dump's own layout; the
#                second is the reference's (GetDiagnostics sorts), and it is
#                asserted because a port that answered diagnostics in DISCOVERY
#                order would otherwise differ from the reference on every unit
#                that has two of them — a difference that reads as a wrong span
#                rather than as a wrong order.
#   DETERMINISM  N runs byte-identical. The checker memoises into maps and the
#                stub program hands it a fixed file list, so nothing here is
#                supposed to depend on iteration order — which is exactly the kind
#                of claim that stays true until it does not.
#
# ★ WHAT IT DELIBERATELY DOES NOT CHECK: that a TYPE is right. Nothing here can
# know that, and a gate pretending to would be worse than none (the
# rule: a checker that cannot fail is worse than no checker). The types are
# compared against our port, one slice at a time, by the yardstick itself.
#
# Usage:
#   packages/tscaly/tests/checktypes.py [--oracle PATH] [--runs N] [FILE ...]
#
# With no FILE arguments it checks all of tests/fixtures. The oracle defaults to
# tests/out/oracle_types, which tests/run.sh builds — this script does not build
# it, and says so rather than answering about a binary that is not there.

import os
import subprocess
import sys

PKG = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def dump(oracle, path):
    proc = subprocess.run([oracle, path], stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE)
    if proc.returncode == 3:
        # The reference panicked. That is a MEASURED class of its own (accepted.txt
        # carries the argument, compare.py gates it) and not a defect in the dump,
        # so it is reported and skipped rather than counted as a failure.
        return None, "REFCRASH"
    if proc.returncode != 0:
        return None, f"the oracle exited {proc.returncode}: " \
                     f"{proc.stderr.decode('utf-8', 'replace').strip()}"
    return proc.stdout, None


def problems_of(out: bytes, size: int):
    """The problems this dump has, as a list of sentences. Empty is a pass."""
    problems = []
    seen_t = False
    last_c = -1
    for n, line in enumerate(out.split(b"\n"), 1):
        if not line:
            continue
        parts = line.split(b" ", 4)
        kind = parts[0]
        if kind == b"C":
            if seen_t:
                problems.append(f"line {n}: a C line after a T line")
            if len(parts) < 4:
                problems.append(f"line {n}: a C line with {len(parts)} fields")
                continue
            try:
                pos, end, code = int(parts[1]), int(parts[2]), int(parts[3])
            except ValueError:
                problems.append(f"line {n}: a C line whose numbers do not parse")
                continue
            if code <= 0:
                problems.append(f"line {n}: diagnostic code {code}")
            if pos < last_c:
                problems.append(f"line {n}: C lines out of order ({pos} after {last_c})")
            last_c = pos
        elif kind == b"T":
            seen_t = True
            if len(parts) < 5:
                problems.append(f"line {n}: a T line with {len(parts)} fields")
                continue
            try:
                k, pos, end = int(parts[1]), int(parts[2]), int(parts[3])
            except ValueError:
                problems.append(f"line {n}: a T line whose numbers do not parse")
                continue
            if k <= 0:
                problems.append(f"line {n}: node kind {k}")
            if not parts[4]:
                problems.append(f"line {n}: an empty type string")
        else:
            problems.append(f"line {n}: neither a C nor a T line")
            continue
        if not (0 <= pos <= end <= size):
            problems.append(f"line {n}: span {pos}..{end} outside 0..{size}")
    return problems


def main(argv):
    oracle = os.path.join(PKG, "tests/out/oracle_types")
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
        print(f"checktypes.py: no oracle at {oracle} — run tests/run.sh first, which"
              " builds it.\nThis is a missing input, not a result.", file=sys.stderr)
        return 2

    if not files:
        fx = os.path.join(PKG, "tests/fixtures")
        files = sorted(os.path.join(fx, n) for n in os.listdir(fx)
                       if n.endswith((".ts", ".tsx")))

    bad_shape = bad_det = failed = refcrash = 0
    for path in files:
        size = os.path.getsize(path)
        out, err = dump(oracle, path)
        if err == "REFCRASH":
            refcrash += 1
            continue
        if err:
            failed += 1
            print(f"  {os.path.basename(path)}: {err}")
            continue
        problems = problems_of(out, size)
        if problems:
            bad_shape += 1
            print(f"  INVARIANT {os.path.basename(path)}: " + "; ".join(problems))
        for _ in range(runs - 1):
            again, err = dump(oracle, path)
            if err or again != out:
                bad_det += 1
                print(f"  NONDETERMINISTIC {os.path.basename(path)}"
                      f"{': ' + err if err else ''}")
                break

    total = len(files)
    print(f"checktypes: {total} files, {runs} runs each — "
          f"{bad_shape} invariant failures, {bad_det} nondeterministic, "
          f"{failed} could not be dumped, {refcrash} with no reference answer")
    return 1 if (bad_shape or bad_det or failed) else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
