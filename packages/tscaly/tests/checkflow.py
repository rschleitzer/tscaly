#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
#
# checkflow.py — the FLOW oracle's own gate (slice 92).
#
# ★★★ WHY AN INSTRUMENT NEEDS ONE, AND WHY THIS ONE'S ARGUMENT IS NOT
# checkdump.py's. That gate exists because our half of the binder dump reported
# `unported` for every unit while the binder was being ported, so the reference
# half was unchecked by the suite itself. This dump is compared on 18 219 of
# 18 223 units from the day it lands, so a defect in either half already shows up
# as a disagreement — for the CONTENT. What a disagreement cannot check is the
# dump's own CONTRACT, because both producers were written from the same reading
# and a shared misunderstanding compares equal.
#
# Two independent checks, and each is a claim about the format rather than about
# the graph:
#
#   INVARIANTS   every flow id that is REFERENCED — by an `f` line's four slots,
#                by an `N` line's antecedent or antecedent list, by a `w`/`l`
#                payload — is also DEFINED by an `N` line; ids are dense from 0;
#                every `N` line whose node column is -2 has exactly one `w` line
#                and one whose column is -3 exactly one `l` line, and no other
#                line has either; an `N` line's stated antecedent COUNT equals the
#                number of ids that follow it.
#   DETERMINISM  N runs over the same file produce byte-identical output. It is
#                not the formality it is for the symbols dump: the ids here are
#                interned in ENCOUNTER order over a walk plus a growing worklist,
#                and a Go map anywhere in that path would make the numbering vary
#                between runs while every single run stayed internally consistent.
#
# ★★★ AND THE GATE IS SHOWN TO BITE RATHER THAN ASSERTED TO — a refuter that
# cannot fire is worse than none. Four injections into a real
# dump of `flow_try.ts`, each of which must produce exactly its own sentence:
#
#   drop one `N` line                 -> "flow ids referenced but never defined:
#                                         [2]" AND "not dense from 0"
#   overstate an antecedent count      -> "flow id 2 says 9 antecedents and lists 2"
#   add an `l` line for a plain node   -> "an `l` line for flow id 0, which is not
#                                         a reduce label"
#   add an `r` line with no bits set   -> "an `r` line with no reachability bit set"
#
# All four fire and the unpatched dump is clean.
#
# ★★★ THE ID DENSITY IS THE LOAD-BEARING ONE. Both sides mint ids by walking the
# tree and then processing the worklist in increasing order, and the ORDER is what
# the comparison actually tests — so a hole in the numbering would mean one side
# reached a flow node the other never did, on a dump that still parses. It is the
# same defect checkdump.py found in the symbols oracle's first draft, one artifact
# over.
#
# Usage:
#   packages/tscaly/tests/checkflow.py [--oracle PATH] [--runs N] [FILE ...]
#
# With no FILE arguments it checks all of tests/fixtures. The oracle defaults to
# tests/out/oracle_flow, which tests/run.sh builds — this script does not build
# it, and says so rather than answering about a binary that is not there.
# ★ Point `--oracle` at `tests/out/tscaly_flow` to run the identical contract
# against OUR half, which is the cheapest way to find out whether a disagreement
# is a wrong graph or a broken dump.

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
    wants_w, wants_l = set(), set()
    has_w, has_l = {}, {}
    problems = []

    for raw in out.split(b"\n"):
        if not raw:
            continue
        # ★ An UNPORTED line is a legal dump: every producer prints it and
        # returns, and a unit that reports one makes no claim at all.
        if raw.startswith(b"UNPORTED "):
            return []
        f = raw.split(b" ")
        rec = f[0]
        try:
            if rec == b"f":
                # f <kind> <pos> <end> <flow> <endFlow> <returnFlow> <fallthrough>
                if len(f) != 8:
                    problems.append(f"an `f` line with {len(f)} fields, not 8")
                    continue
                for v in f[4:8]:
                    if int(v) >= 0:
                        refs.add(int(v))
            elif rec == b"r":
                # r <kind> <pos> <end> <flags>
                if len(f) != 5:
                    problems.append(f"an `r` line with {len(f)} fields, not 5")
                elif int(f[4]) == 0:
                    problems.append("an `r` line with no reachability bit set")
            elif rec == b"N":
                # N <id> <flags> <nodeKind> <nodePos> <nodeEnd> <antecedent> <n> <a…>
                if len(f) < 8:
                    problems.append(f"an `N` line with {len(f)} fields, fewer than 8")
                    continue
                i = int(f[1])
                if i in defined:
                    problems.append(f"flow id {i} is defined twice")
                defined.add(i)
                kind = int(f[3])
                if kind == -2:
                    wants_w.add(i)
                elif kind == -3:
                    wants_l.add(i)
                if int(f[6]) >= 0:
                    refs.add(int(f[6]))
                n = int(f[7])
                ants = f[8:]
                if len(ants) != n:
                    problems.append(f"flow id {i} says {n} antecedents and lists {len(ants)}")
                for a in ants:
                    refs.add(int(a))
            elif rec == b"w":
                # w <id> <kind> <pos> <end> <clauseStart> <clauseEnd>
                if len(f) != 7:
                    problems.append(f"a `w` line with {len(f)} fields, not 7")
                    continue
                i = int(f[1])
                has_w[i] = has_w.get(i, 0) + 1
                refs.add(i)
            elif rec == b"l":
                # l <id> <target> <n> <a…>
                if len(f) < 4:
                    problems.append(f"an `l` line with {len(f)} fields, fewer than 4")
                    continue
                i = int(f[1])
                has_l[i] = has_l.get(i, 0) + 1
                refs.add(i)
                refs.add(int(f[2]))
                n = int(f[3])
                ants = f[4:]
                if len(ants) != n:
                    problems.append(f"reduce label {i} says {n} antecedents and lists {len(ants)}")
                for a in ants:
                    refs.add(int(a))
            else:
                problems.append(f"unknown record {rec.decode()!r}")
        except (IndexError, ValueError):
            problems.append(f"malformed line: {raw.decode('utf-8', 'replace')!r}")

    missing = sorted(refs - defined)
    if missing:
        problems.append(f"flow ids referenced but never defined: {missing}")
    if defined and sorted(defined) != list(range(len(defined))):
        problems.append("flow ids are not dense from 0")
    for i in sorted(wants_w):
        if has_w.get(i, 0) != 1:
            problems.append(f"flow id {i} is a switch clause with {has_w.get(i, 0)} `w` lines")
    for i in sorted(wants_l):
        if has_l.get(i, 0) != 1:
            problems.append(f"flow id {i} is a reduce label with {has_l.get(i, 0)} `l` lines")
    for i in sorted(set(has_w) - wants_w):
        problems.append(f"a `w` line for flow id {i}, which is not a switch clause")
    for i in sorted(set(has_l) - wants_l):
        problems.append(f"an `l` line for flow id {i}, which is not a reduce label")
    return problems


def main(argv):
    oracle = os.path.join(PKG, "tests/out/oracle_flow")
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
        print(f"checkflow.py: no oracle at {oracle} — run tests/run.sh first, which"
              " builds it.\nThis is a missing input, not a result.", file=sys.stderr)
        return 2

    if not files:
        fx = os.path.join(PKG, "tests/fixtures")
        files = sorted(os.path.join(fx, n) for n in os.listdir(fx)
                       if n.endswith((".ts", ".tsx", ".js")))

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
    print(f"checkflow: {total} files, {runs} runs each — "
          f"{bad_inv} invariant failures, {bad_det} nondeterministic, "
          f"{failed} could not be dumped")
    return 0 if bad_inv == bad_det == failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
