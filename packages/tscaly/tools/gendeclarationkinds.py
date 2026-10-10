#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
#
# gendeclarationkinds.py — generate tscaly/DeclarationKinds.scaly, the port of
# `ast.IsDeclarationNode`.
#
# ── Why this is generated and not written ────────────────────────────────────
#
# The reference's predicate is three tokens long:
#
#     func IsDeclarationNode(node *Node) bool { return node.DeclarationData() != nil }
#
# and it is not a question about the KIND at all. `DeclarationData()` is an
# interface method with a nil default; a node answers non-nil exactly when its
# data STRUCT embeds `DeclarationBase`, directly or through one of the shared
# bases (`FunctionLikeBase`, `ClassLikeBase`, `NamedMemberBase`,
# `AccessorDeclarationBase`, …). So the answer is a property of the node LAYOUT,
# and the layout lives in a GENERATED file upstream
# (internal/ast/ast_generated.go, "Code generated … DO NOT EDIT").
#
# ★★★ A HAND-WRITTEN KIND LIST WOULD BE WRONG IN BOTH DIRECTIONS, AND SLICE 47
# SAID SO BEFORE ANYONE LOOKED. Its checker header deferred the whole
# `grammar-source-file-declare` arm on exactly this ground — *a missing kind drops
# a TS1046 the reference reports, an extra one invents a diagnostic where a plain
# statement stands* — and the derived list is what shows how right that was. Seven
# of the fifty-six declaration kinds are ones no reader would guess:
# `BinaryExpression`, `CallExpression`, `ObjectLiteralExpression`,
# `NoSubstitutionTemplateLiteral`, `SemicolonClassElement`, `JsxAttributes` and
# `SourceFile` all embed `DeclarationBase` (the first four so that a JavaScript
# expando assignment, a `require` call, an object literal and a tagged template
# can each own a symbol). And `StringLiteral`, which sits one line away from
# `NoSubstitutionTemplateLiteral` in every other predicate in the file, does NOT.
#
# ── How the derivation works, and why it is checked twice ────────────────────
#
# Two independent readings of the same file have to agree before a kind is
# emitted, because the derivation has two halves and each can fail on its own:
#
#   the LAYOUT half   the struct-embedding graph, transitively closed over
#                     `DeclarationBase`. Verified against a SECOND PRODUCER with
#                     `--verify`, which writes a probe into the reference's own
#                     package and asks Go's `reflect` — `FieldByName` follows
#                     embedded fields, so the language itself answers the same
#                     question our text parse does.
#
#   the PAIRING half  which Kind a struct is built with. `ast_generated.go` is
#                     laid out in banner-delimited sections, one per node type,
#                     and each section carries up to two witnesses: the FACTORY
#                     (`f.newNode(KindX, data)`) and the PREDICATE
#                     (`func IsX(node *Node) bool { return node.Kind == KindX }`).
#                     186 of the 195 kinds have both and none of them disagree.
#                     ★ The nine with only a predicate are exactly the sections
#                     whose factory takes the kind as a PARAMETER —
#                     `NewBindingPattern(kind, …)`, `NewForInOrOfStatement`,
#                     `NewCaseOrDefaultClause`, `NewJSDocParameterOrPropertyTag`
#                     and `SourceFile`, whose struct and factory are hand-written
#                     in ast.go — so the missing witness is a property of the
#                     reference's own shape and not of this parse.
#
# ★★ AND THE UNMAPPED KINDS ARE ARGUED, NOT ASSUMED. 386 Kind constants, 195
# mapped: the remaining 191 are the 25 range MARKERS (aliases of other members,
# not kinds), `KindUnknown`, `KindCount`, and every token / keyword / trivia kind
# — all of which are built by `NewToken`, `NewKeywordExpression` or
# `NewKeywordTypeNode`, the three sections that declare a struct and no kind of
# their own. This script ASSERTS that those three structs are outside the
# declaration closure, which is what makes `false` the right answer for all of
# them; if a pin bump ever put `DeclarationBase` on `Token`, the assert fires
# instead of the table quietly going wrong.
#
# Usage (from the repo root, submodule initialized):
#   packages/tscaly/tools/gendeclarationkinds.py [--verify]
#
# The output is committed. With the submodule absent the committed file stays
# valid and this script simply cannot run — same arrangement as genkind.py.

import os
import re
import subprocess
import sys

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
SUB = os.path.join(REPO, "packages/tscaly/_submodules/typescript-go")
GEN = os.path.join(SUB, "internal/ast/ast_generated.go")
HAND = os.path.join(SUB, "internal/ast/ast.go")
KINDS = os.path.join(SUB, "internal/ast/kind_generated.go")
DST = os.path.join(REPO, "packages/tscaly/0.1.2/tscaly/DeclarationKinds.scaly")

# The three sections that declare a node struct and no Kind of their own: their
# factories take the kind as a parameter and serve every token / keyword kind.
# Named here so the assert below can say what it is asserting.
KINDLESS = ("Token", "KeywordExpression", "KeywordTypeNode")

SECTION = re.compile(r"^// ─+\n// (\w+)\n// ─+\n", re.M)
STRUCT = re.compile(r"^type (\w+) struct \{\n(.*?)^\}", re.S | re.M)
PREDICATE = re.compile(r"func Is(\w+)\(node \*Node\) bool \{\n\treturn (.*?)\n\}", re.S)
KINDCHAIN = re.compile(r"(node\.Kind == Kind\w+)( \|\| node\.Kind == Kind\w+)*")


def die(msg):
    sys.exit("gendeclarationkinds: " + msg)


def read(path):
    if not os.path.exists(path):
        die("no such file: %s\n  (the submodule is not initialized; the committed"
            " output stays valid)" % path)
    with open(path, encoding="utf-8") as f:
        return f.read()


def embedding_graph(text):
    """struct name -> the names it embeds (a field line that is one bare identifier)."""
    graph = {}
    for m in STRUCT.finditer(text):
        name, body = m.group(1), m.group(2)
        embedded = []
        for line in body.split("\n"):
            s = line.strip()
            if not s or s.startswith("//"):
                continue
            if re.fullmatch(r"[A-Za-z_]\w*", s):
                embedded.append(s)
        graph[name] = embedded
    return graph


def closure(graph, target):
    """Every struct that reaches `target` through embedding."""
    def reaches(name, seen):
        if name in seen:
            return False
        seen.add(name)
        return any(e == target or reaches(e, seen) for e in graph.get(name, ()))

    return {n for n in graph if reaches(n, set())}


def kind_map(gen_text, graph):
    """Kind constant -> section (== struct) name, from two witnesses."""
    marks = [(m.start(), m.group(1)) for m in SECTION.finditer(gen_text)]
    if not marks:
        die("no section banners in ast_generated.go — the file's shape changed")
    mapping = {}
    both = 0
    predicate_only = []
    node_structs = set()
    for i, (pos, name) in enumerate(marks):
        end = marks[i + 1][0] if i + 1 < len(marks) else len(gen_text)
        body = gen_text[pos:end]

        # ★ The section banner names the struct. Asserted rather than assumed:
        # if a section ever declared a differently-named type, every pairing
        # below would be attached to the wrong layout.
        declared = re.findall(r"^type (\w+) struct", body, re.M)
        if declared and declared[0] != name:
            die("section %r declares type %r — the file's shape changed" % (name, declared[0]))
        if name not in graph:
            continue  # NodeFactory and friends: a banner with no struct anywhere
        node_structs.add(name)

        by_factory = set(re.findall(r"newNode\((Kind\w+)", body))
        by_predicate = set()
        for m in PREDICATE.finditer(body):
            expr = m.group(2)
            if KINDCHAIN.fullmatch(expr):
                by_predicate |= set(re.findall(r"Kind\w+", expr))
        if by_factory and by_predicate and by_factory != by_predicate:
            die("section %r: the factory says %s and the predicate says %s"
                % (name, sorted(by_factory), sorted(by_predicate)))
        if by_factory and by_predicate:
            both += len(by_factory)
        elif by_predicate:
            predicate_only.append(name)
        for k in by_factory | by_predicate:
            if k in mapping and mapping[k] != name:
                die("kind %s is paired with both %s and %s" % (k, mapping[k], name))
            mapping[k] = name
    return mapping, both, predicate_only, node_structs


def verify(decl_structs, node_structs):
    """Ask Go's own type system, in the reference's own package.

    gentypeflags.py's arrangement: a probe compiled INTO internal/ast, run, and
    removed.

    ★★★ AND THE QUESTION IT ASKS HAD TO BE CORRECTED ONCE, WHICH IS THE WHOLE
    VALUE OF HAVING A SECOND PRODUCER. The first form asked reflect for the
    FIELD (`Type.FieldByName("DeclarationBase")`) and disagreed with the text
    derivation on exactly one struct of 199: `MethodSignatureDeclaration`, which
    embeds `NamedMemberBase` AND `FunctionLikeBase` and so reaches
    `DeclarationBase` twice at the same depth — ambiguous as a FIELD, which is
    what reflect reported. The reference does not read the field. It calls the
    METHOD, and there the two paths are NOT at the same depth:
    `NamedMemberBase` declares `DeclarationData()` itself (depth 1) while
    `FunctionLikeBase` only promotes it from its own `DeclarationBase` (depth 2),
    so Go's shallowest-wins rule picks one and the node IS a declaration. The
    probe therefore asserts the interface, which is `DeclarationData() != nil`
    verbatim — and `new(X)` rather than `X{}`, because several node structs embed
    `CompositeBase` with its `atomic.Uint32` and copying one is what `go vet`
    refuses.
    """
    probe = os.path.join(SUB, "internal/ast/zz_declkinds_probe_test.go")
    src = ["package ast", "",
           "// Written by packages/tscaly/tools/gendeclarationkinds.py --verify and",
           "// removed again by it. If this file is in a working tree, that run died.",
           "",
           "import (", '\t"reflect"', '\t"testing"', ")", "",
           "type zzDeclarationData interface{ DeclarationData() *DeclarationBase }", "",
           "func TestZZDeclKindsProbe(t *testing.T) {",
           "\twant := map[string]bool{}"]
    for n in sorted(decl_structs & node_structs):
        src.append('\twant["%s"] = true' % n)
    src.append("\tfor _, v := range []any{")
    for n in sorted(node_structs):
        src.append("\t\tnew(%s)," % n)
    src.append("\t} {")
    src.append("\t\tname := reflect.TypeOf(v).Elem().Name()")
    src.append("\t\tgot := false")
    src.append("\t\tif d, is := v.(zzDeclarationData); is {")
    src.append("\t\t\tgot = d.DeclarationData() != nil")
    src.append("\t\t}")
    src.append("\t\tif got != want[name] {")
    src.append('\t\t\tt.Errorf("%s: the reference answers %v, the generator says %v", name, got, want[name])')
    src.append("\t\t}")
    src.append("\t\tdelete(want, name)")
    src.append("\t}")
    src.append("\tfor name := range want {")
    src.append('\t\tt.Errorf("%s: the generator calls it a declaration and the probe never saw it", name)')
    src.append("\t}")
    src.append("}")
    with open(probe, "w", encoding="utf-8") as f:
        f.write("\n".join(src) + "\n")
    try:
        r = subprocess.run(["go", "test", "-count=1", "-run", "TestZZDeclKindsProbe",
                            "./internal/ast/"], cwd=SUB, capture_output=True, text=True)
        sys.stdout.write(r.stdout)
        sys.stderr.write(r.stderr)
        if r.returncode == 0:
            print("gendeclarationkinds --verify: the reference's own DeclarationData()"
                  " agrees on all %d node structs, %d of them declarations"
                  % (len(node_structs), len(decl_structs & node_structs)))
        return r.returncode
    finally:
        os.remove(probe)


HEADER = """; SPDX-License-Identifier: Apache-2.0
;
; DeclarationKinds — ast.IsDeclarationNode, as a question about the KIND.
;
; GENERATED by packages/tscaly/tools/gendeclarationkinds.py. Do not edit; edit
; the generator. Regenerate after a submodule pin bump.
;
; ★★★ THE REFERENCE DOES NOT ASK THIS QUESTION OF THE KIND, AND THAT IS THE
; WHOLE REASON THIS FILE IS GENERATED. `IsDeclarationNode(node)` is
; `node.DeclarationData() != nil`, an interface method with a nil default that a
; node answers exactly when its data STRUCT embeds `DeclarationBase` — a property
; of the node LAYOUT. The generator closes the embedding graph of the reference's
; own generated ast_generated.go over that base and pairs each struct with the
; Kind its section is built with, so this table is a DERIVED fact rather than a
; transcription. The pairing is proven single-valued: no kind is built from two
; structs, so the layout question does reduce to the kind question — but only
; after it has been asked of the layout.
;
; ★★ SEVEN OF THE {N} ARE ONES NOBODY WOULD GUESS. BinaryExpression,
; CallExpression, ObjectLiteralExpression, NoSubstitutionTemplateLiteral,
; SemicolonClassElement, JsxAttributes and SourceFile all embed DeclarationBase
; — the first four so a JavaScript expando assignment, a `require` call, an
; object literal and a tagged template can each own a symbol — while
; StringLiteral, which every other predicate in that file treats as
; NoSubstitutionTemplateLiteral's twin, does not. A hand-written list would have
; dropped a TS1046 on some files and invented one on others, which is exactly the
; deferral slice 47 wrote at check_grammar_source_file.
;
; ★ EVERY KIND NOT LISTED ANSWERS FALSE, and that is argued rather than assumed.
; The Kind constants the paragraph below counts are the node kinds; the rest are
; the range MARKERS (aliases of other members, not kinds), KindUnknown, KindCount,
; and the token / keyword / trivia kinds, whose nodes are built by NewToken,
; NewKeywordExpression and NewKeywordTypeNode. The
; generator asserts those three structs are outside the declaration closure, so a
; pin bump that put DeclarationBase on Token fails the generator instead of
; quietly turning this table into a wrong answer.
"""


def main(argv):
    gen_text = read(GEN)
    whole = gen_text + "\n" + read(HAND)
    graph = embedding_graph(whole)
    decl = closure(graph, "DeclarationBase")

    for n in KINDLESS:
        if n not in graph:
            die("the %r struct is gone — ast_generated.go's shape changed" % n)
        if n in decl:
            die("%s now embeds DeclarationBase: every token kind would have to be\n"
                "  a declaration node, and this table's `everything else is false`\n"
                "  argument no longer holds." % n)

    mapping, both, predicate_only, node_structs = kind_map(gen_text, graph)
    kinds = sorted(k for k, s in mapping.items() if s in decl)

    # Every declaration STRUCT must have been paired with at least one kind, or
    # the table silently omits it.
    paired = {mapping[k] for k in mapping}
    orphans = sorted(n for n in decl if n not in paired and not n.endswith("Base"))
    if orphans:
        die("declaration structs that no section pairs with a kind: %s" % orphans)

    if "--verify" in argv:
        return verify(decl, node_structs)

    total_kinds = len(re.findall(r"^\t(Kind\w+)", read(KINDS), re.M))
    out = [HEADER.replace("{N}", str(len(kinds))).rstrip("\n")]
    out.append(";")
    out.append("; %d node kinds of the reference's %d Kind constants are paired with a"
               % (len(mapping), total_kinds))
    out.append("; struct; %d of those %d pairings carry BOTH witnesses (the factory's"
               % (both, len(mapping)))
    out.append("; newNode call and the section's Is-predicate) and none disagree. The")
    out.append("; %d with only a predicate come from the %d sections whose factory takes"
               % (len(mapping) - both, len(predicate_only)))
    out.append("; the kind as a PARAMETER, plus SourceFile, whose struct and factory are")
    out.append("; hand-written in ast.go: %s." % ", ".join(sorted(predicate_only)))
    out.append("")
    out.append("function is_declaration_node_kind(k: int) returns bool")
    out.append("{")
    for k in kinds:
        out.append("    if k = %s" % k)
        out.append("        return true")
    out.append("    false")
    out.append("}")
    with open(DST, "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")
    print("gendeclarationkinds: %d declaration kinds -> %s"
          % (len(kinds), os.path.relpath(DST, REPO)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
