<!-- SPDX-License-Identifier: Apache-2.0 -->

tscaly
======

A port of the TypeScript compiler from Go to Scaly.

Origin
------

| | |
|---|---|
| Upstream | [microsoft/typescript-go](https://github.com/microsoft/typescript-go) |
| Pinned commit | `2bd066d87f5bafd315be9f40889d0a60b9e58e0b` |
| Release | tag `typescript/v7.0.2` — TypeScript 7.0 |
| Commit date | 2026-07-07 |
| Upstream license | Apache 2.0 (+ `NOTICE.txt`) |

**Statement of changes.** tscaly is a port of microsoft/typescript-go at the
commit above from Go to Scaly. Every file in this package is modified with
respect to its upstream counterpart; no file is a verbatim copy. The port
changes the language, the memory model (region-based memory management in place
of garbage collection), and the core dispatch mechanism (sum types and pattern
matching in place of interface dispatch). Individual files are not annotated
with per-file change logs — this collective statement is the change marking.

Every ported file carries `; SPDX-License-Identifier: Apache-2.0` on its first
line.

Why this port exists
--------------------

Three reasons, in order of weight:

1. **Validation against foreign code.** Everything written in Scaly so far was
   also designed in Scaly. A large algorithm nobody here designed is the test of
   whether the memory and concurrency model carries, or has to grow.
2. **Evidence for the RBMM thesis.** A compiler run is the canonical arena
   workload, and this one has published numbers to be measured against.
3. **Objective correctness.** The upstream golden-master suite makes conformance
   measurable rather than assertable.

Layout
------

```
packages/tscaly/
  LICENSE                  Apache 2.0 — this package only
  NOTICE.txt               attribution, ours + upstream
  README.md                this file
  0.1.0/                   the Scaly sources (package `tscaly`)
  _submodules/
    typescript-go/         pinned reference + test corpus, never copied from
```

The sources sit under `0.1.0/` because the Scaly compiler finds a package at
`packages/<name>/<version>/`. Everything above that level — submodule,
licenses, documents — stays outside the directory the compiler scans.

The submodule
-------------

```sh
git submodule update --init packages/tscaly/_submodules/typescript-go
```

Roughly 339 MB, of which `testdata/` is about 289 MB. It is deliberately **not**
part of a default clone; `--recurse-submodules` stays opt-in, and every script
that walks `packages/` must tolerate the directory being empty.

The submodule serves two purposes at once: it is the reference source for the
line-by-line port, and it is the test corpus. Nothing is copied out of it into
this repository.

License boundary
----------------

tscaly is Apache 2.0. Scaly itself — compiler, runtime, standard library — is
MIT and lives in a repository of its own. Licenses attach to works, so this is
a normal arrangement, but it has one rule that is easy to violate by accident:

> **No code moves out of tscaly into Scaly's compiler, runtime or standard
> library. Concepts and ideas yes; literal code no.**

The direction that is allowed (MIT into Apache) is not the risk. The risk is
that a helper written while porting looks like a standard-library candidate
and gets lifted over, which would relicense a piece of the standard library
without anyone deciding to.
