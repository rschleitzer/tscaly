#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
#
# compare.py — the case loop of run.sh, as ONE process over TWO batch programs.
#
# ★★★ THIS FILE CHANGES THE COST OF THE MEASUREMENT AND NOT THE MEASUREMENT — the
# same sentence its predecessor opened with, and it was checked the same way: the
# counters, the failures list and every artifact body were compared byte for byte
# against the previous runner over the whole stage-1 corpus before the old shape was
# retired. The history of that runner (the bash loop, the per-unit process model,
# the reference-dump cache, the three levers of 2026-08-19) is in
# CLAUDE-history.md under *The runner's history*.
#
# The shape since 2026-09-02:
#
#   1. `oracle_batch` splits every case with the reference's own splitter and dumps
#      all six reference artifacts of every unit, in `jobs` sequential processes
#      over disjoint case lists, one framed stream each. No unit file, no ref file,
#      no cache — the whole stage-1 reference answers in a few seconds, so there is
#      nothing left to cache.
#   2. Every case and unit goes into the STORE (`tests/out/run.db`, harness.Store) —
#      the one file a run writes, and the one every reader opens.
#   3. `tscaly_dump --batch` answers every compared unit from `jobs` supervised
#      processes; a crash or a hang is blamed on the unit in progress and the
#      process restarted on the rest (harness.run_batch).
#   4. The verdicts are computed here exactly as before — the last column of the
#      oracle cut by FIELD COUNT (`cut_fields` is `cut -d' ' -f1-<keep>`, nothing
#      else), UNPORTED is not a pass, an accepted deviation must still be listed,
#      `no-tree` is a defect — and written to the store beside the artifacts.
#
# ★ ONE CHANGE OF EVIDENCE FORMAT, stated because it is one: the first line quoted
# into a failure message used to come from diff(1) run on two files. There are no
# files now, so it comes from `harness.diff_lines`, which prints diff's normal
# format (`3c3`, `5a6`, `7,8d6`) from the same two line lists. A green run has no
# failures and is unaffected; a red one reads the same head from a different pen.
#
# ★ THE REPORT IS ORDER-STABLE: results are keyed (case index, unit index, artifact)
# and folded in that order, whatever the chunks did.

import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import harness as H  # noqa: E402


def verdict_of(ctx, key, art, keep, ours_rc, ours_out, ref_rc, ref_out):
    """→ (verdict, message, cut, diff) — the rules of the previous runner, unchanged."""
    if ours_rc == H.TIMED_OUT:
        return "TIMEOUT", f"{art}/{key}: our dumper fell silent for {ctx.timeout}s", None, None
    if ref_rc == H.TIMED_OUT:
        return "TIMEOUT", (f"{art}/{key}: the ORACLE fell silent for {ctx.timeout}s"
                           " — suspect the harness, not the port"), None, None
    if ours_rc != 0:
        return "FAIL", f"{art}/{key}: our dumper exited {ours_rc}", None, None
    if ref_rc == 3:
        if (key, art) in ctx.accepted:
            return "REFCRASH", f"{art}/{key}", None, None
        return "FAIL", (f"{art}/{key}: the ORACLE panicked inside the reference"
                        " (exit 3) and no accepted.txt entry argues it"), None, None
    if ref_rc != 0:
        return "FAIL", (f"{art}/{key}: the ORACLE exited {ref_rc}"
                        " — suspect the harness, not the port"), None, None
    if H.has_line_prefix(ours_out, b"UNPORTED 0 no-tree "):
        return "FAIL", (f"{art}/{key}: no-tree — the parser answered null with NO"
                        " unported record, which is a port defect and not an"
                        " unported construct"), None, None
    if H.has_line_prefix(ours_out, b"UNPORTED "):
        return "UNPORTED", None, None, None
    cut = H.cut_fields(ref_out, keep) if keep > 0 else ref_out
    is_acc = (key, art) in ctx.accepted
    if cut == ours_out:
        return ("STALE" if is_acc else "MATCH"), None, cut, None
    if is_acc:
        return "ACCEPTED", None, cut, None
    diff = H.diff_bytes(ref_out, ours_out)
    first = diff.split(b"\n", 1)[0].decode("utf-8", "surrogateescape")
    return "FAIL", f"{art}/{key}: {first}", cut, diff


class Ctx:
    pass


def main():
    ctx = Ctx()
    out = os.environ["TSCALY_OUT"]
    ctx.accepted = H.load_accepted(os.environ["TSCALY_ACCEPTED"])
    sub_prefix = os.environ["TSCALY_SUB_PREFIX"]
    pkg_prefix = os.environ["TSCALY_PKG_PREFIX"]
    ts_prefix = os.environ.get("TSCALY_TS_PREFIX", "")
    filt = os.environ.get("TSCALY_FILTER", "")
    jobs = int(os.environ.get("TSCALY_JOBS") or min(16, os.cpu_count() or 8))
    stage = int(os.environ.get("TSCALY_STAGE") or 1)
    ctx.timeout = float(os.environ.get("TSCALY_TIMEOUT") or 60)
    profile = os.environ.get("TSCALY_PROFILE")
    wall = {}

    cases = [line.rstrip("\n") for line in sys.stdin if line.strip()]

    selected = []
    for case_file in cases:
        name = case_file
        if ts_prefix and name.startswith(ts_prefix):
            name = "submodule/" + name[len(ts_prefix):]
        elif name.startswith(sub_prefix):
            name = name[len(sub_prefix):]
        elif name.startswith(pkg_prefix):
            name = name[len(pkg_prefix):]
        if name.endswith(".ts"):
            name = name[:-3]
        name = name.replace("/", "_")
        if filt and filt not in name:
            continue
        selected.append((case_file, name))

    seen_keys = {}
    for case_file, name in selected:
        if name in seen_keys:
            print(f"compare.py: two cases map to one key {name!r}:\n"
                  f"    {seen_keys[name]}\n    {case_file}\n"
                  "  One would overwrite the other's artifacts and verdict. Give the"
                  " key space another separator before running this corpus.",
                  file=sys.stderr)
            return 2
        seen_keys[name] = case_file

    store = H.Store(H.store_path(out), create=True)
    store.put_meta("stage", stage)
    store.put_meta("filter", filt)
    store.put_meta("started", time.strftime("%Y-%m-%dT%H:%M:%S"))
    store.put_meta("oracle_stamp", os.environ.get("TSCALY_ORACLE_STAMP", ""))

    def progress(what, n, total):
        if stage >= 2:
            print(f"  {what} {n}/{total}", file=sys.stderr, flush=True)

    # ── phase A: the reference, split and six dumps per unit, in one stream per chunk ──
    t0 = time.time()
    ref = H.run_oracle(f"{out}/oracle_batch", out, selected, jobs, ctx.timeout)
    wall["oracle"] = time.time() - t0
    progress("oracle", len(ref), len(selected))

    counters = {}
    for art in H.ART_NAMES:
        for k in ("matched", "unported", "failed", "accepted", "stale", "timeout", "refcrash"):
            counters[f"{k}_{art}"] = 0
    for k in ("cases_seen", "skip_jsx", "skip_other", "json_compared", "js_compared",
              "tsx_compared", "jsx_compared", "jsdoc_bearing", "js_diag_units",
              "js_diag_lines", "symbol_bearing", "bind_diag_units", "bind_diag_lines"):
        counters[k] = 0
    failures, stales, refcrashes = [], [], []

    # ── phase B: the store, and the list of units our side has to answer ──
    t0 = time.time()
    compared = []          # (ci, idx, key) in corpus order
    to_dump = []           # (path, content) for tscaly_dump --batch
    split_fail_by_case = {}
    for ci, (case_file, name) in enumerate(selected):
        counters["cases_seen"] += 1
        c = ref.get(name)
        if c is None:      # cannot happen: run_oracle answers every case it was given
            c = {"split_rc": 1, "split_err": b"the oracle answered nothing for this case", "units": []}
        store.put_case(ci, name, case_file, c["split_rc"], c["split_err"])
        if c["split_rc"] != 0:
            detail = c["split_err"].split(b"\n", 1)[0].decode("utf-8", "replace")
            split_fail_by_case[ci] = f"split/{name}: {detail}"
            counters["failed_tokens"] += 1
            counters["failed_ast"] += 1
            continue
        unit_count = len(c["units"])
        for u in c["units"]:
            skip = H.classify_unit(u["name"])
            if unit_count == 1:
                key = name
            else:
                key = name + "@" + u["name"].lstrip("/").replace("/", "_")
            store.put_unit(ci, u["idx"], u["name"], u["path"], key, skip is None, u["content"])
            if skip is not None:
                counters["skip_other"] += 1
                continue
            bucket = H.kind_bucket(u["name"])
            if bucket:
                counters[bucket + "_compared"] += 1
            for art in H.ART_NAMES:
                rc, rout, rerr = u["refs"][art]
                store.put_ref(ci, u["idx"], art, rc, rout, rerr)
            compared.append((ci, u["idx"], key))
            to_dump.append((u["path"], u["content"]))
    store.commit()
    wall["store-ref"] = time.time() - t0
    by_path = {p: cu for (p, _), cu in zip(to_dump, compared)}

    # ── phase C: our side, one batch process per chunk ──
    t0 = time.time()
    ours = H.run_batch(f"{out}/tscaly_dump", "", to_dump, f"{out}/chunks", jobs, ctx.timeout)
    wall["ours"] = time.time() - t0
    progress("ours", len(ours), len(to_dump))

    # ── phase D: verdicts ──
    t0 = time.time()
    results = {}       # (ci, idx, art) → (verdict, message, key)
    for path, content in to_dump:
        ci, idx, key = by_path[path]
        rc, body, err = ours.get(path, (1, b"", b"the dumper answered nothing for this unit"))
        parts = H.split_dump(body) if rc == 0 else None
        if rc == 0 and parts is None:
            rc, err = 1, b"malformed --batch answer: a section separator is missing"
        for art, keep in H.ARTIFACTS:
            oout = parts[art] if parts else b""
            walk = diags = None
            if parts and art == "types":
                st = H.split_types(oout)
                if st is None:
                    rc_a, oout = 1, oout
                    err_a = b"malformed types section"
                else:
                    walk, diags, oout = st
                    rc_a, err_a = 0, b""
            else:
                rc_a, err_a = rc, err
            store.put_ours(ci, idx, art, rc_a, oout, err_a, walk, diags)
            a = store.artifact(ci, idx, art)
            v, msg, cut, diff = verdict_of(ctx, key, art, keep, rc_a, oout, a["ref_rc"], a["ref"] or b"")
            store.put_verdict(ci, idx, art, v, msg, cut, diff)
            results[(ci, idx, art)] = (v, msg, key)
    store.commit()

    art_order = H.ART_NAMES
    by_case = {}
    for k in results:
        by_case.setdefault(k[0], []).append(k)
    for ci in range(len(selected)):
        if ci in split_fail_by_case:
            failures.append(split_fail_by_case[ci])
            continue
        keys = sorted(by_case.get(ci, ()), key=lambda k: (k[1], art_order.index(k[2])))
        seen_units = []
        for k in keys:
            verdict, message, key = results[k]
            art = k[2]
            if verdict == "MATCH":
                counters[f"matched_{art}"] += 1
            elif verdict == "STALE":
                counters[f"matched_{art}"] += 1
                counters[f"stale_{art}"] += 1
                stales.append(f"{art}/{key}")
            elif verdict == "UNPORTED":
                counters[f"unported_{art}"] += 1
            elif verdict == "ACCEPTED":
                counters[f"accepted_{art}"] += 1
            elif verdict == "REFCRASH":
                counters[f"refcrash_{art}"] += 1
                refcrashes.append(message)
            else:
                if verdict == "TIMEOUT":
                    counters[f"timeout_{art}"] += 1
                counters[f"failed_{art}"] += 1
                failures.append(message)
            if art == "jsdoc":
                seen_units.append((k[0], k[1]))
        # The corpus-shape counters, read off the REFERENCE dumps as before.
        for ci_u, idx in seen_units:
            j = store.artifact(ci_u, idx, "jsdoc")
            if j and j["ref"]:
                counters["jsdoc_bearing"] += 1
            a = store.artifact(ci_u, idx, "ast")
            if a and a["ref"]:
                n = sum(1 for line in a["ref"].split(b"\n") if line.startswith(b"J "))
                if n:
                    counters["js_diag_units"] += 1
                    counters["js_diag_lines"] += n
            s = store.artifact(ci_u, idx, "symbols")
            if s and s["ref"]:
                syms = binds = 0
                for line in s["ref"].split(b"\n"):
                    if line.startswith(b"s "):
                        syms += 1
                    elif line.startswith(b"B "):
                        binds += 1
                if syms:
                    counters["symbol_bearing"] += 1
                if binds:
                    counters["bind_diag_units"] += 1
                    counters["bind_diag_lines"] += binds
    wall["verdicts"] = time.time() - t0

    store.put_meta("finished", time.strftime("%Y-%m-%dT%H:%M:%S"))
    store.close()

    with open(f"{out}/counters.sh", "w") as fh:
        for k in sorted(counters):
            fh.write(f"{k}={counters[k]}\n")
    if profile:
        print("\n  --- TSCALY_PROFILE ---", file=sys.stderr)
        for k, v in sorted(wall.items()):
            print("  phase %-10s %8.1f s wall" % (k, v), file=sys.stderr)
    with open(f"{out}/failures.txt", "w", errors="surrogateescape") as fh:
        for f in failures:
            fh.write(f + "\n")
    with open(f"{out}/stales.txt", "w") as fh:
        for s in stales:
            fh.write(s + "\n")
    with open(f"{out}/refcrashes.txt", "w", errors="surrogateescape") as fh:
        for r in refcrashes:
            fh.write(r + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
