#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice50.sh — the slice-50 battery. Every row goes through
# tests/diagcheck.sh, for slice 49's reason and one of this slice's own.
#
# ★★★ SLICE 49's REASON: the yardstick counters cannot move. A unit is matched
# only when its check runs to the END, and — see below — no unit of this family
# can reach that. ★★★ THIS SLICE'S OWN: the one arm that DOES run to the end
# (`export {}`) is in a file that has an export, and a file with an export is an
# external module, so checkSourceFile's last branch reports
# check-external-module-exports for it. So the arm finishes and the FILE does not:
# the same conclusion slice 49 reached from the other end, and the reason checker
# matched stays 10 across everything below.
#
# ★★★ THE INSTRUMENT IS ONE-DIRECTIONAL, WHICH DECIDES HOW EVERY ROW IS WRITTEN.
# diagcheck compares our C section as a SUBSEQUENCE of the reference's, so it
# cannot see a diagnostic we FAIL to report. Fourteen of the seventeen rows below
# therefore break their claim in the direction that INVENTS a line, moves a span
# or changes a code. The last three (f15, f16, f17) are COVERAGE claims — they can
# only be broken by making the port measure LESS — so they are UNGATED BY
# CONSTRUCTION and are read off the *units we speak on* / *diagnostics* counters
# instead, which is what those numbers are printed for.
#
# ★★ THE ROWS DO NOT GO THROUGH ctl.sh, for slice 48's reason: diagcheck reads the
# reference dumps run.sh produced, and a filtered run would rewrite part of that
# tree. Each row builds the package and the dumper into a scratch directory,
# points diagcheck's BIN at it, leaves tests/out alone, restores the source and
# PROVES the restore with `cmp`.
#
# ★ f12 patches parser.scaly rather than checker.scaly, and it is the row for the
# defect this slice FOUND rather than for code it wrote — the reparser's missing
# re-parenting call. It is in this battery because the checker is the only reader
# that can see it.
#
# Usage (nothing may edit the tree while this runs — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # the artifact tree, first
#   packages/tscaly/tests/controls-slice50.sh 2>&1 | tee /tmp/battery50.log

set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.0/tscaly/checker.scaly
PARSER=$PKG/0.1.0/tscaly/parser.scaly

LIBSCALY=${LIBSCALY:-/tmp/libscaly.a}
SCALYC=${SCALYC:-$REPO/scalyc/build/scalyc}

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  echo "Every row compares against the reference dumps that run produced."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl50)
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

build_diag_bin() {
  "$SCALYC" -c --no-prelude -o "$WORK/pkg.o" "$PKG/0.1.0/tscaly.scaly" > "$WORK/build.log" 2>&1 || return 1
  "$SCALYC" -c -o "$WORK/types.o" "$PKG/0.1.0/tscaly_types.scaly" >> "$WORK/build.log" 2>&1 || return 1
  clang -o "$WORK/tscaly_types" "$WORK/types.o" "$WORK/pkg.o" "$LIBSCALY" -lm >> "$WORK/build.log" 2>&1
}

DIAG_BASE=""
DIAG_LINES=""
DIAG_DIAGS=""

diag_baseline() {
  echo "################################################################"
  bold "DIAGNOSTICS BASELINE"
  if ! build_diag_bin; then
    red "the unpatched tree did not build — every row below would be measuring that."
    sed 's/^/    /' "$WORK/build.log"
    exit 2
  fi
  BIN=$WORK/tscaly_types "$DIAGCHECK" > "$WORK/base.diag" 2>&1
  local rc=$?
  DIAG_BASE=$(sed -n 's/^  consistent  *\([0-9]*\)$/\1/p' "$WORK/base.diag")
  DIAG_LINES=$(sed -n 's/^  units we speak on  *\([0-9]*\).*$/\1/p' "$WORK/base.diag")
  DIAG_DIAGS=$(sed -n 's/^.*(\([0-9]*\) diagnostics.*$/\1/p' "$WORK/base.diag")
  sed -n '/^diagcheck/,$p' "$WORK/base.diag" | sed 's/^/  /'
  if [ "$rc" != 0 ]; then
    red "the diagnostics instrument is already red on the unpatched tree — fix that first."
    exit 2
  fi
  echo "  BASELINE   $DIAG_BASE units consistent, $DIAG_LINES speaking, $DIAG_DIAGS diagnostics"
}

diag_control() {   # $1 = label, $2 = file, $3 = python patch file
  echo
  echo "################################################################"
  bold "CONTROL: $1"
  cp "$2" "$WORK/orig"
  if ! python3 "$3" "$2"; then
    red "the patch did not apply — the anchor moved. The row measures nothing."
    cp "$WORK/orig" "$2"
    return 1
  fi
  echo "  patched $2"
  if ! build_diag_bin; then
    red "the patched tree did not build — the row measures nothing:"
    tail -5 "$WORK/build.log" | sed 's/^/    /'
    cp "$WORK/orig" "$2"
    return 1
  fi
  BIN=$WORK/tscaly_types "$DIAGCHECK" > "$WORK/ctl.diag" 2>&1
  local rc=$?
  local consistent differing speaking
  consistent=$(sed -n 's/^  consistent  *\([0-9]*\)$/\1/p' "$WORK/ctl.diag")
  differing=$(sed -n 's/^  differing  *\([0-9]*\)$/\1/p' "$WORK/ctl.diag")
  speaking=$(sed -n 's/^  units we speak on  *\([0-9]*\).*$/\1/p' "$WORK/ctl.diag")
  local diags
  diags=$(sed -n 's/^.*(\([0-9]*\) diagnostics.*$/\1/p' "$WORK/ctl.diag")
  cp "$WORK/orig" "$2"
  if ! cmp -s "$WORK/orig" "$2"; then
    red "the source did NOT come back — every number below is suspect."
    return 1
  fi
  echo "  RESTORE VERIFIED   $2 byte-identical"
  echo
  if [ "$rc" != 0 ]; then
    green "RED $differing   (consistent $consistent, was $DIAG_BASE; speaking on $speaking/$diags, was $DIAG_LINES/$DIAG_DIAGS)"
  else
    red "UNGATED: every line we print is still a subsequence of the reference's."
    echo "  Speaking on $speaking units with $diags diagnostics, was $DIAG_LINES/$DIAG_DIAGS."
    echo "  Decide which of §3.5v's four kinds this is — and note that a control"
    echo "  which REMOVES a diagnostic, or narrows the port's COVERAGE, is ungated"
    echo "  here by construction (header)."
  fi
  return 0
}

diag_baseline

# ── f1: SourceFile is an appropriate parent ──────────────────────────────────

cat > "$WORK/f1.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ THE LOUDEST INVENTION THE HEAD CAN MAKE. Every import, export and namespace
# at the top level of a file has a SourceFile parent, so dropping that arm makes
# the whole family report its illegal-context message everywhere.
old = """        if pk = KindSourceFile
            set in_appropriate_context: true
        if pk = KindModuleBlock
"""
new = """        if pk = KindModuleBlock
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f1 a SourceFile is an appropriate context for a module element" "$CHECKER" "$WORK/f1.py"

# ── f2: ModuleBlock is an appropriate parent ─────────────────────────────────

cat > "$WORK/f2.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ The second arm of the same set, and it is reachable ONLY because this slice
# ported the block arm: an export or import inside a namespace body has a
# ModuleBlock parent, and before slice 50 nothing checked those statements at all.
old = """        if pk = KindModuleBlock
            set in_appropriate_context: true
"""
new = ""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f2 a ModuleBlock is an appropriate context too" "$CHECKER" "$WORK/f2.py"

# ── f3: the type-only test on a specifier ────────────────────────────────────

cat > "$WORK/f3.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★ checkGrammarTypeOnlyNamedImportsOrExports reports on the first specifier that
# is ITSELF type-only. Report on the first specifier instead and every
# `export type { A } from "m"` in the corpus invents a TS2207.
old = """            if AstNode.is_type_only_of(specifier)
                return this.grammar_error_on_first_token(specifier, code)
"""
new = """            return this.grammar_error_on_first_token(specifier, code)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f3 only a type-only SPECIFIER is reported under export type" "$CHECKER" "$WORK/f3.py"

# ── f4: which message a specifier gets ──────────────────────────────────────

cat > "$WORK/f4.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★ The two messages differ only by import vs export and the reference chooses on
# the specifier's KIND. Swapping them is the same span with a different code,
# which is the failure mode a subsequence test is sharpest on.
old = """            var code: int DiagThe_type_modifier_cannot_be_used_on_a_named_export_when_export_type_is_used_on_its_export_statement
            if AstNode.kind_of(specifier) = KindImportSpecifier
                set code: DiagThe_type_modifier_cannot_be_used_on_a_named_import_when_import_type_is_used_on_its_import_statement
"""
new = """            var code: int DiagThe_type_modifier_cannot_be_used_on_a_named_import_when_import_type_is_used_on_its_import_statement
            if AstNode.kind_of(specifier) = KindImportSpecifier
                set code: DiagThe_type_modifier_cannot_be_used_on_a_named_export_when_export_type_is_used_on_its_export_statement
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f4 the specifier's message is chosen by the specifier's KIND" "$CHECKER" "$WORK/f4.py"

# ── f5: `cannot have modifiers` needs a modifier list ────────────────────────

cat > "$WORK/f5.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ The report is about a modifier being present, so it is guarded on there
# BEING one. Drop the guard on the import arm and every plain `import x from "m"`
# in the corpus invents a TS1191.
old = """        if this.check_grammar_modifiers(node) = false
        {
            if AstNode.modifiers_of(node) <> null
                this.grammar_error_on_first_token(node, DiagAn_import_declaration_cannot_have_modifiers)
        }
"""
new = """        if this.check_grammar_modifiers(node) = false
            this.grammar_error_on_first_token(node, DiagAn_import_declaration_cannot_have_modifiers)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f5 `an import declaration cannot have modifiers` needs a modifier" "$CHECKER" "$WORK/f5.py"

# ── f6: ... and needs the grammar check to have been silent ──────────────────

cat > "$WORK/f6.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ THE SHORT-CIRCUIT IS THE SUPPRESSION. `!checkGrammarModifiers(node) && …`
# means the extra report fires only when the modifier check found NOTHING; drop
# the negation and `declare import a from "./a"` answers TS1079 *and* TS1191,
# where the reference answers only the first.
old = """        if this.check_grammar_modifiers(node) = false
        {
            if AstNode.modifiers_of(node) <> null
                this.grammar_error_on_first_token(node, DiagAn_import_declaration_cannot_have_modifiers)
        }
"""
new = """        this.check_grammar_modifiers(node)
        if AstNode.modifiers_of(node) <> null
            this.grammar_error_on_first_token(node, DiagAn_import_declaration_cannot_have_modifiers)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f6 the modifier report is suppressed by the grammar check's own" "$CHECKER" "$WORK/f6.py"

# ── f7: TS1035 is guarded on the ambient context ─────────────────────────────

cat > "$WORK/f7.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ `Only ambient modules can use quoted names` is exactly the report that must
# NOT fire in an ambient context — every `declare module "m"` in every .d.ts of
# the corpus is a quoted name, so dropping the guard inverts the check's meaning
# and floods.
old = """            if in_ambient_context = false
            {
                let name AstNode.name_of(node)
"""
new = """            if true
            {
                let name AstNode.name_of(node)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f7 the quoted-name report is guarded on the ambient context" "$CHECKER" "$WORK/f7.py"

# ── f8: TS1035 needs a QUOTED name ──────────────────────────────────────────

cat > "$WORK/f8.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★ The other half of the same condition, and a different mechanism: with the
# kind test gone every plain `namespace N {}` reports that its name is quoted.
old = """                if Checker.kind_or_unknown(name) = KindStringLiteral
                    this.grammar_error_on_node(name, DiagOnly_ambient_modules_can_use_quoted_names)
"""
new = """                if name <> null
                    this.grammar_error_on_node(name, DiagOnly_ambient_modules_can_use_quoted_names)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f8 the quoted-name report needs a STRING LITERAL name" "$CHECKER" "$WORK/f8.py"

# ── f9: which container message an export assignment gets ────────────────────

cat > "$WORK/f9.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★ `export =` and `export default` are one node kind under a FIELD, so the two
# messages of the container walk are told apart by that field alone. Swapped, the
# spans are right and both codes are wrong.
old = """                if is_export_equals
                    this.error_on_node(node, DiagAn_export_assignment_cannot_be_used_in_a_namespace)
                if is_export_equals = false
                    this.error_on_node(node, DiagA_default_export_can_only_be_used_in_an_ECMAScript_style_module)
"""
new = """                if is_export_equals
                    this.error_on_node(node, DiagA_default_export_can_only_be_used_in_an_ECMAScript_style_module)
                if is_export_equals = false
                    this.error_on_node(node, DiagAn_export_assignment_cannot_be_used_in_a_namespace)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f9 the container messages are chosen by the export-equals FIELD" "$CHECKER" "$WORK/f9.py"

# ── f10: error_on_node's span is the ERROR RANGE ─────────────────────────────

cat > "$WORK/f10.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ c.error goes through GetErrorRangeForNode and grammarErrorOnFirstToken
# through a re-scan of one token. For `export = 1;` inside a namespace that is the
# whole statement against the `export` keyword — the same start and a different
# end, which is what makes the two reporters two functions.
old = """        if b.error_range_for_node(n, &start, &stop) = false
        {
            this.record_unported("error-range", AstNode.kind_of(n))
            return
        }
"""
new = """        if false
        {
            this.record_unported("error-range", AstNode.kind_of(n))
            return
        }
        b.range_of_token_at_position(AstNode.pos_of(n), &start, &stop)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f10 error_on_node reports at the ERROR RANGE, not at the first token" "$CHECKER" "$WORK/f10.py"

# ── f11: TS1035 reports at the NAME ─────────────────────────────────────────

cat > "$WORK/f11.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★ The one report of this family that points at a child rather than at the
# statement. Point it at the statement and the span moves from the quoted name to
# the whole declaration.
old = """                    this.grammar_error_on_node(name, DiagOnly_ambient_modules_can_use_quoted_names)
"""
new = """                    this.grammar_error_on_node(node, DiagOnly_ambient_modules_can_use_quoted_names)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f11 the quoted-name report points at the NAME" "$CHECKER" "$WORK/f11.py"

# ── f12: finish_reparsed_node re-parents its immediate children ──────────────

cat > "$WORK/f12.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ THE DEFECT THIS SLICE FOUND, restored. The reference's finishReparsedNode
# ends in overrideParentInImmediateChildren; without it a dotted `@typedef
# {T} A.B.C` leaves the inner ModuleDeclaration pointing at the JSDoc node it was
# parsed under, and checkGrammarModuleElementContext — asking that parent for its
# kind — invents a TS1235 inside a comment. Four yardsticks cannot see a parent.
old = """        set n.end: location.end
        this.override_parent_in_immediate_children(n)
    }
"""
new = """        set n.end: location.end
    }
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f12 finish_reparsed_node re-parents its immediate children" "$PARSER" "$WORK/f12.py"

# ── f13: the export declaration's permitted contexts ────────────────────────

cat > "$WORK/f13.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ The gate for checker_export_empty_clause.ts, whose expected answer is NOTHING
# — and this is the row that proves such a fixture is still a gate. Drop the
# SourceFile arm and every specifier-less `export { … }` at the top level of a
# file reports that export declarations are not permitted in a namespace.
old = """        var permitted false
        if pk = KindSourceFile
            set permitted: true
"""
new = """        var permitted false
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f13 a specifier-less export is permitted at the top level of a file" "$CHECKER" "$WORK/f13.py"

# ── f14: the once-bit an unported arm may have spent ─────────────────────────

cat > "$WORK/f14.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ THE SECOND DEFECT THE BLOCK ARM EXPOSED, and the one that made the first
# stage-2 run red. checkGrammarStatementInAmbientContext is the first line of some
# twenty statement arms, so in `declare namespace M { break; debugger; }` the
# reference spends the block's once-bit on the `break` — a statement this port has
# no arm for — and reporting on the `debugger` puts a diagnostic where the
# reference has none. Removing the suppression restores exactly that.
old = """            this.record_unported("check", k)
            this.spend_ambient_report_of_container(node)
"""
new = """            this.record_unported("check", k)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f14 an unported statement arm may have spent the block's once-bit" "$CHECKER" "$WORK/f14.py"

# ── f15, f16, f17: the three coverage claims, ungated by construction ───────
#
# ★★★ ALL THREE MAKE THE PORT MEASURE LESS, and diagcheck cannot fail on that —
# fewer lines are still a subsequence. They are here because the *units we speak
# on* and *diagnostics* counters are the instrument for exactly this, and because
# each names a mechanism that would otherwise shrink the slice's coverage in
# silence.

cat > "$WORK/f15.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# The BLOCK arm. Without it no statement inside a namespace body is checked at
# all, which is the state slice 49 described and named the next slice to lift.
old = """        if k = KindModuleBlock
        {
            this.check_block(node)
            return
        }
"""
new = ""
assert s.count(old) == 1, s.count(old)
s2 = s.replace(old, new)
old2 = """        if k = KindModuleBlock
            return true
"""
assert s2.count(old2) == 1, s2.count(old2)
open(p, "w").write(s2.replace(old2, ""))
PY
diag_control "f15 the ModuleBlock arm is what reaches a namespace body" "$CHECKER" "$WORK/f15.py"

cat > "$WORK/f16.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# The module arm's own recursion — the other half of f14, and an independent way
# to lose the same coverage: the arm exists and nothing calls it.
old = """        let body AstNode.body_of(node)
        if body <> null
            this.check_source_element(body)
"""
new = """        let body AstNode.body_of(node)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f16 checkModuleDeclaration recurses into its BODY" "$CHECKER" "$WORK/f16.py"

cat > "$WORK/f17.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# checkGrammarExportDeclaration stands BEFORE the module-specifier bail, which is
# the claim checker_export_type_only_specifier.ts pins. Move it behind and the
# TS2207 of every `export type { type A } from "m"` disappears.
old = """        this.check_grammar_export_declaration(node)

        if AstNode.module_specifier_of(node) <> null
"""
new = """        if AstNode.module_specifier_of(node) <> null
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f17 the export declaration's grammar check runs BEFORE the bail" "$CHECKER" "$WORK/f17.py"

echo
echo "################################################################"
bold "BATTERY 50 COMPLETE"
echo "Sixteen rows. Thirteen must be RED; f14, f15 and f16 are UNGATED by"
echo "construction and are read off the two coverage counters."
