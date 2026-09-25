#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""oracle_cache_check.py -- the refuter of the oracle cache (harness.OracleCache).

    python3 packages/tscaly/tests/oracle_cache_check.py

Runs the real oracle_batch (tests/out/oracle_batch, built by run.sh) over COPIES
of two fixtures in a scratch directory, and asserts the cache's four cases:

  1. a first run answers from the oracle and fills the cache (0 hits);
  2. a second run answers from the cache (all hits), byte-identical;
  3. a changed CASE (its bytes) runs the oracle again for that case only;
  4. a changed STAMP (oracle binaries or reference submodule) runs everything.

A cache that cannot miss would pass 1 and 2; 3 and 4 are what make it a check.
Exit status 0 only if all four hold.
"""
import os
import shutil
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import harness as H  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
ORACLE = os.path.join(HERE, "out", "oracle_batch")
FIXTURES = ["alias_export_specifier.ts", "alias_import_conflicts.ts"]

failures = []


def check(cond, what):
    print(("PASS  " if cond else "FAIL  ") + what)
    if not cond:
        failures.append(what)


def main():
    if not os.path.isfile(ORACLE):
        print("oracle_cache_check: no tests/out/oracle_batch -- run tests/run.sh once first")
        return 2
    work = tempfile.mkdtemp(prefix="oracle_cache_check.")
    try:
        cases = []
        for f in FIXTURES:
            dst = os.path.join(work, f)
            shutil.copy(os.path.join(HERE, "fixtures", f), dst)
            cases.append((dst, f[:-3]))
        out = os.path.join(work, "out")
        os.makedirs(out)

        def run(stamp):
            return H.run_oracle_cached(ORACLE, out, cases, 2, 120, stamp, False, False)

        a1, h1, m1 = run("stamp-A")
        check(h1 == 0 and m1 == len(cases), "first run: every case from the oracle (%d hits)" % h1)
        a2, h2, m2 = run("stamp-A")
        check(h2 == len(cases) and m2 == 0, "second run: every case from the cache (%d hits)" % h2)
        check(a1 == a2, "a cached answer is byte-identical to the fresh one")

        with open(cases[0][0], "a") as fh:
            fh.write("\nconst oracle_cache_check_edit = 1;\n")
        a3, h3, m3 = run("stamp-A")
        check(h3 == len(cases) - 1 and m3 == 1, "a changed case runs the oracle for that case only (%d run)" % m3)
        check(a3[cases[0][1]] != a1[cases[0][1]], "  and its answer is the new one")
        check(a3[cases[1][1]] == a1[cases[1][1]], "  and the untouched case keeps its answer")

        a4, h4, m4 = run("stamp-B")
        check(h4 == 0 and m4 == len(cases), "a changed stamp runs every case (%d hits)" % h4)
    finally:
        shutil.rmtree(work, ignore_errors=True)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
