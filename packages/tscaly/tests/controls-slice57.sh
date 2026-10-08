#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice57.sh — the slice-57 battery: the INTERFACE and the TYPE ALIAS,
# both of which stop at checkExportsOnMergedDeclarations.
#
# ★★★ TWO INSTRUMENTS AGAIN, AND THE SECOND ONE IS LOAD-BEARING FOR A DIFFERENT
# REASON THAN IN SLICE 56. There the pin existed because a whole ported block
# produced no diagnostic; here every ported line produces one EXCEPT
# checkTypeParameters, whose call in the interface arm has no observable effect on
# the C section at all — record_unported marks the unit and does not return, so
# the reports run on past the hole. Its only effect is on the unported TAG, and
# the tag is also where this slice's one asymmetry lives: the reference asks the
# reserved name AFTER checkTypeParameters in the interface arm and BEFORE
# everything in the alias arm, so a generic interface carries
# `check-type-parameter` and a generic type alias carries
# `check-exports-on-merged-declarations`. No yardstick compares a tag. The pin
# does.
#
# ★★★ AND IT IS THE INSTRUMENT FOR THE TWO ACCESSOR WIDENINGS, which no
# diagnostic can reach either. type_parameters_of and heritage_clauses_of were
# both narrowed to their callers (§3.5br, fifth and sixth time); t3 and t4 take
# the new arm out again and the pin says what that costs.
#
# ★★ THE PIN SAYS WHAT CHANGED, NEVER WHAT IS RIGHT. It compares this port
# against itself. What makes each expectation defensible is written in the
# fixture that produces it — one term of the reference's own control flow per
# file.
#
# ★★ THE ROWS DO NOT GO THROUGH ctl.sh, for slice 48's reason: both instruments
# read the reference dumps run.sh produced, and a filtered run would rewrite part
# of that tree. Each row builds the package and the dumper into a scratch
# directory, points the instruments at it, leaves tests/out alone, restores the
# source and PROVES the restore with `cmp`.
#
# ★ TWO ROWS PATCH ast.scaly RATHER THAN checker.scaly, which is why `control`
# takes the file as an argument. The restore check is per row and per file.
#
# Usage (nothing may edit the tree while this runs — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # the artifact tree, first
#   packages/tscaly/tests/controls-slice57.sh 2>&1 | tee /tmp/battery57.log

set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.1/tscaly/checker.scaly
AST=$PKG/0.1.1/tscaly/ast.scaly
FIX=$PKG/tests/fixtures

. packages/tscaly/tests/toolchain.sh || exit 2

# The six fixtures the PIN reads. The first two are the PAIR: one generic
# interface and one generic type alias, one declaration each, because
# record_unported keeps the FIRST report and a generic declaration behind a plain
# one would carry the plain one's tag and witness nothing (slice 56's *a fixture
# that cannot be first is not a witness*).
TAGFILES="
$FIX/checker_interface_generic_reserved_name.ts
$FIX/checker_type_alias_generic_reserved_name.ts
$FIX/checker_interface_reserved_name.ts
$FIX/checker_type_alias_reserved_name.ts
$FIX/checker_interface_heritage.ts
$FIX/checker_interface_modifier_gate.ts
"

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  echo "Both instruments compare against the reference dumps that run produced."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl57)
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

build_diag_bin() {
  "$SCALYC" -c --no-prelude -o "$WORK/pkg.o" "$PKG/0.1.1/tscaly.scaly" > "$WORK/build.log" 2>&1 || return 1
  "$SCALYC" -c -o "$WORK/types.o" "$PKG/0.1.1/tscaly_types.scaly" >> "$WORK/build.log" 2>&1 || return 1
  clang -o "$WORK/tscaly_types" "$WORK/types.o" "$WORK/pkg.o" "$LIBSCALY" -lm >> "$WORK/build.log" 2>&1
}

# The PIN: one line per fixture, "<basename> <tag> <detail>".
tags_of() {
  local f
  for f in $TAGFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$("$WORK/tscaly_types" "$f" 2>/dev/null | grep '^UNPORTED ' | head -1 | cut -d' ' -f3-)"
  done
}

DIAG_BASE=""
DIAG_LINES=""
DIAG_DIAGS=""

baseline() {
  echo "################################################################"
  bold "BASELINE — both instruments"
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
  tags_of > "$WORK/base.tags"
  echo
  echo "  the PIN — the six fixtures' unported tags on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.tags"
  if grep -q '	$' "$WORK/base.tags"; then
    red "a fixture answers NO tag — the pin would be comparing two empties."
    exit 2
  fi
  echo
  echo "  BASELINE   $DIAG_BASE units consistent, $DIAG_LINES speaking, $DIAG_DIAGS diagnostics"
}

control() {   # $1 = label, $2 = file, $3 = python patch file
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
  local consistent differing speaking diags
  consistent=$(sed -n 's/^  consistent  *\([0-9]*\)$/\1/p' "$WORK/ctl.diag")
  differing=$(sed -n 's/^  differing  *\([0-9]*\)$/\1/p' "$WORK/ctl.diag")
  speaking=$(sed -n 's/^  units we speak on  *\([0-9]*\).*$/\1/p' "$WORK/ctl.diag")
  diags=$(sed -n 's/^.*(\([0-9]*\) diagnostics.*$/\1/p' "$WORK/ctl.diag")
  tags_of > "$WORK/ctl.tags"
  cp "$WORK/orig" "$2"
  if ! cmp -s "$WORK/orig" "$2"; then
    red "the source did NOT come back — every number below is suspect."
    return 1
  fi
  echo "  RESTORE VERIFIED   $2 byte-identical"
  echo
  if [ "$rc" != 0 ]; then
    green "diagcheck RED $differing   (consistent $consistent, was $DIAG_BASE; speaking on $speaking/$diags, was $DIAG_LINES/$DIAG_DIAGS)"
  else
    echo "  diagcheck ungated — speaking on $speaking units with $diags diagnostics, was $DIAG_LINES/$DIAG_DIAGS."
  fi
  if cmp -s "$WORK/base.tags" "$WORK/ctl.tags"; then
    echo "  pin       unmoved — all six fixtures answer the same tag."
  else
    green "pin       RED"
    diff "$WORK/base.tags" "$WORK/ctl.tags" | sed 's/^/    /'
  fi
  if [ "$rc" = 0 ] && cmp -s "$WORK/base.tags" "$WORK/ctl.tags"; then
    if [ "$speaking" != "$DIAG_LINES" ] || [ "$diags" != "$DIAG_DIAGS" ]; then
      echo "  ungated on both, WITH A NUMBER: $DIAG_LINES/$DIAG_DIAGS -> $speaking/$diags."
      echo "  A control which REMOVES a diagnostic is ungated on diagcheck by"
      echo "  construction (its header), and the falling count is then the row."
    else
      red "UNGATED on BOTH INSTRUMENTS AND NOTHING MOVED AT ALL."
      echo "  Decide which of §3.5v's four kinds this is. A row that predicted"
      echo "  this is a measurement; a row that did not is a hole in the battery."
    fi
  fi
  return 0
}

baseline

# ── g1: the `extends` arm reports on the FIRST clause ────────────────────────

cat > "$WORK/g1.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ `extends` is refused only the SECOND time, and dropping the seen-flag
# inverts the population exactly: every interface with one extends clause — which
# the corpus is full of — reports TS1172, and the duplicate on line 3 of
# checker_interface_heritage.ts is the one that goes quiet. It INVENTS lines, so
# diagcheck sees it.
# ★ THE ANCHOR CARRIES THE LINE AFTER IT, because the class version of this
# block (slice 51) has the same two lines and the patch would otherwise match
# twice — which the harness reports as *the anchor moved* rather than patching
# the wrong one. `set seen_extends_clause: true` is the interface arm's, since
# the class arm has an implements test between them.
old = """                if seen_extends_clause
                    return this.grammar_error_on_first_token(clause, DiagX_extends_clause_already_seen)
                set seen_extends_clause: true
"""
new = """                if seen_extends_clause = false
                    return this.grammar_error_on_first_token(clause, DiagX_extends_clause_already_seen)
                set seen_extends_clause: true
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
control "g1 the extends arm reports on the first clause" "$CHECKER" "$WORK/g1.py"

# ── g2: TS1176's CODE ────────────────────────────────────────────────────────

cat > "$WORK/g2.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★ A CODE-ONLY row, same span and same order — the cheapest demonstration that
# the dump compares the code, and the reason these two reports may be transcribed
# without their message arguments (§3.5ct).
old = """                return this.grammar_error_on_first_token(clause, DiagInterface_declaration_cannot_have_implements_clause)
"""
new = """                return this.grammar_error_on_first_token(clause, DiagX_extends_clause_already_seen)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
control "g2 TS1176's code" "$CHECKER" "$WORK/g2.py"

# ── g3: TS1176's REPORTER, and therefore its SPAN ────────────────────────────

cat > "$WORK/g3.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ grammarErrorOnFirstToken SCANS for the first token of the node; the ordinary
# reporter takes the node's error RANGE, which for a heritage clause is the whole
# clause including its type list. So `implements A` reports at the `implements`
# either way but ENDS ten characters later, which is the pair that says the two
# reporters are not interchangeable.
old = """                return this.grammar_error_on_first_token(clause, DiagInterface_declaration_cannot_have_implements_clause)
"""
new = """                return this.grammar_error_on_node(clause, DiagInterface_declaration_cannot_have_implements_clause)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
control "g3 TS1176's reporter" "$CHECKER" "$WORK/g3.py"

# ── g4: the `implements` arm does not RETURN ─────────────────────────────────

cat > "$WORK/g4.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ THE FIFTH LINE OF checker_interface_heritage.ts EXISTS FOR THIS ROW.
# `interface E implements A extends B extends A {}` reports ONCE in the
# reference — the implements — because the arm RETURNS and the loop stops. Report
# and continue, and the duplicate `extends` behind it reports too: a line the
# reference does not have, in a unit where the reference does speak. That is the
# one failure mode a subsequence relation catches best.
old = """            else
                return this.grammar_error_on_first_token(clause, DiagInterface_declaration_cannot_have_implements_clause)
"""
new = """            else
                this.grammar_error_on_first_token(clause, DiagInterface_declaration_cannot_have_implements_clause)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
control "g4 the implements arm does not return" "$CHECKER" "$WORK/g4.py"

# ── g5: every clause read as `extends` ───────────────────────────────────────

cat > "$WORK/g5.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ The token test is the whole of the fork. Reading every clause as `extends`
# loses both TS1176 lines and INVENTS a TS1172 on line 5, where the second
# `extends`-shaped clause now looks like a duplicate. Both directions at once,
# which is what makes it the row for the fork rather than for either arm.
old = """            if AstNode.heritage_clause_token_of(clause) = KindExtendsKeyword
            {
                if seen_extends_clause
                    return this.grammar_error_on_first_token(clause, DiagX_extends_clause_already_seen)
                set seen_extends_clause: true
            }
"""
new = """            if true
            {
                if seen_extends_clause
                    return this.grammar_error_on_first_token(clause, DiagX_extends_clause_already_seen)
                set seen_extends_clause: true
            }
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
control "g5 every clause read as extends" "$CHECKER" "$WORK/g5.py"

# ── g6: the modifier GATE in front of the heritage check ─────────────────────

cat > "$WORK/g6.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ THE ROW checker_interface_modifier_gate.ts WAS WRITTEN FOR. Upstream's
# `if !c.checkGrammarModifiers(node) { c.checkGrammarInterfaceDeclaration(...) }`
# suppresses the heritage walk on an interface whose modifiers already reported.
# Calling it unconditionally adds a TS1172 to `private interface C extends A
# extends B {}` that the reference does not have — and leaves the second
# interface's line alone, so the row is exactly one invented diagnostic.
old = """        if this.check_grammar_modifiers(node) = false
            this.check_grammar_interface_declaration(node)
"""
new = """        this.check_grammar_modifiers(node)
        this.check_grammar_interface_declaration(node)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
control "g6 the modifier gate in front of the heritage check" "$CHECKER" "$WORK/g6.py"

# ── g7: checkGrammarHeritageClause's DISCARDED result ────────────────────────

cat > "$WORK/g7.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ EXPECTED UNGATED ON BOTH, EVERY NUMBER UNMOVED, AND THE PREDICTION IS THE
# ROW. The call's result is discarded upstream, so a report inside one clause does
# not stop the walk over the rest — but reaching that difference needs an
# interface with TWO heritage clauses where the FIRST one reports, and an
# interface may have only one legal `extends`: the second clause is refused by the
# arms above before this line is reached. So the distinction is real in the
# reference and unreachable here, and saying so with a number is worth more than
# a fixture that cannot exist.
old = """            this.check_grammar_heritage_clause(clause)
        }
        false
    }

    ; ── slice 52: the function-like grammar checks"""
new = """            if this.check_grammar_heritage_clause(clause)
                return true
        }
        false
    }

    ; ── slice 52: the function-like grammar checks"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
control "g7 the heritage clause's discarded result" "$CHECKER" "$WORK/g7.py"

# ── t1: the reserved-name list drops a spelling ──────────────────────────────

cat > "$WORK/t1.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ EXPECTED UNGATED WITH A FALLING COUNT, and the count is the row. The eleven
# are a LIST and nothing derives them, so the only way to measure that the list is
# read is to take an entry out: both reserved-name fixtures lose their
# `undefined` line, two diagnostics in two units that still speak. diagcheck
# cannot see a missing line by construction (its header), so the number is the
# whole gate.
old = """        if Checker.identifier_text_equals(name, "undefined", 9)
            set reserved: true
"""
new = """"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
control "t1 the reserved-name list drops a spelling" "$CHECKER" "$WORK/t1.py"

# ── t2: the reserved-name list gains one ─────────────────────────────────────

cat > "$WORK/t2.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ THE OTHER DIRECTION, AND IT IS GATED. `Thing` is the clean negative of both
# reserved-name fixtures — the reference says nothing about it — so adding it to
# the list invents lines where the reference has none. The pair t1/t2 is what
# makes the list EXACT rather than merely non-empty: one row says every entry is
# read, the other says nothing else is.
#
# ★ MEASURED RED 4 OVER 76 SPEAKING UNITS, WAS 74/144 — so two of the four
# invented lines are the fixtures' own negative and two are in CORPUS units that
# were silent before, which is what the rising unit count says. A negative
# control that only reddens its own fixture proves the fixture; this one reaches
# the corpus as well.
old = """        var reserved false
"""
new = """        var reserved false
        if Checker.identifier_text_equals(name, "Thing", 5)
            set reserved: true
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
control "t2 the reserved-name list gains one" "$CHECKER" "$WORK/t2.py"

# ── t3: type_parameters_of loses its InterfaceDeclaration arm ────────────────

cat > "$WORK/t3.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ THE ROW FOR THE §3.5br WIDENING, AND ONLY THE PIN CAN SEE IT. The accessor
# was narrowed to its callers and answered null for an interface; putting it back
# that way makes checkTypeParameters see no type parameters at all, so
# `interface never<T> {}` stops reporting `check-type-parameter` and answers
# `check-exports-on-merged-declarations` — the same tag as its non-generic
# neighbour. Not one diagnostic moves, in either direction: the reserved-name
# report is made past the hole either way. A widening whose only witness is a tag
# is exactly the kind that gets silently un-done.
old = """            when intf: InterfaceDeclaration
                return intf.type_parameters
"""
new = """"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
control "t3 type_parameters_of loses its interface arm" "$AST" "$WORK/t3.py"

# ── t4: heritage_clauses_of loses its InterfaceDeclaration arm ───────────────

cat > "$WORK/t4.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ THE SECOND WIDENING, and it is ungated WITH A NUMBER rather than pinned:
# the accessor answers null, check_grammar_interface_declaration returns at its
# first line, and every heritage diagnostic of this slice disappears — three from
# checker_interface_heritage.ts and one from checker_interface_modifier_gate.ts.
# Removing lines is invisible to diagcheck by construction, so the falling number
# is the row: 74/144 -> 73/140.
#
# ★ THE UNIT COUNT WAS PREDICTED AS TWO AND IS ONE, and the correction is worth
# keeping. checker_interface_modifier_gate.ts keeps SPEAKING with this arm gone,
# because its other diagnostic is the modifier report — which is the whole point
# of that fixture. A unit stops speaking only when it had nothing else to say,
# and a fixture built to carry two independent reports is by construction not
# such a unit.
#
# ★ It is also the proof that the OLD accessor name was a lie about its arms
# rather than a harmless one: with the interface arm gone, nothing in this slice
# works and nothing says so.
old = """            when intf: InterfaceDeclaration
                return intf.heritage_clauses
"""
new = """"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
control "t4 heritage_clauses_of loses its interface arm" "$AST" "$WORK/t4.py"

# ── t5: the interface arm loses checkTypeParameters ──────────────────────────

cat > "$WORK/t5.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ THE ASYMMETRY THIS SLICE IS ABOUT, held to a number. The reference asks
# checkTypeParameters BEFORE the reserved name in the interface arm and nowhere at
# all before the alias arm's stop; dropping the call makes the two arms answer the
# SAME tag on the generic pair, which is precisely the difference the two
# one-declaration fixtures were written to witness. Nothing else moves — the
# call's only effect on the C section is none, because record_unported does not
# return.
old = """        this.check_type_parameters(AstNode.type_parameters_of(node))
        this.check_type_name_is_reserved(AstNode.name_of(node), DiagInterface_name_cannot_be_0)
"""
new = """        this.check_type_name_is_reserved(AstNode.name_of(node), DiagInterface_name_cannot_be_0)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
control "t5 the interface arm loses checkTypeParameters" "$CHECKER" "$WORK/t5.py"

# ── t6: the container test, inverted ─────────────────────────────────────────

cat > "$WORK/t6.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ THE LINE SLICE 53 DATED, GATED AT LAST. containerAllowsBlockScopedVariable
# answers true for every parent an interface can have in reach, so the report is
# unreachable and t7 measures that; this row inverts the test so that it fires on
# EVERY interface instead, which invents TS1156 in every unit that has one. The
# pair is the only way to say anything about an unreachable report: one row proves
# the branch is wired, the other proves it is not taken.
old = """        if this.container_allows_block_scoped_variable(AstNode.parent_node_of(node)) = false
            this.grammar_error_on_node(node, DiagX_0_declarations_can_only_be_declared_inside_a_block)
        this.check_type_parameters"""
new = """        if this.container_allows_block_scoped_variable(AstNode.parent_node_of(node))
            this.grammar_error_on_node(node, DiagX_0_declarations_can_only_be_declared_inside_a_block)
        this.check_type_parameters"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
control "t6 the container test, inverted" "$CHECKER" "$WORK/t6.py"

# ── t7: the container report, removed ────────────────────────────────────────

cat > "$WORK/t7.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ EXPECTED UNGATED ON BOTH INSTRUMENTS WITH EVERY NUMBER UNMOVED, AND THE
# PREDICTION IS THE ROW. TS1156's condition is a parent that is one of the seven
# loop/if/with statements, and no arm that CONTAINS a statement is ported — so
# nothing can put an interface or a type alias under one, and the report is
# unreachable on both corpora. Removing it must therefore cost exactly zero.
# t6 is what keeps that from being an excuse.
old = """        if this.container_allows_block_scoped_variable(AstNode.parent_node_of(node)) = false
            this.grammar_error_on_node(node, DiagX_0_declarations_can_only_be_declared_inside_a_block)
        this.check_type_parameters"""
new = """        this.check_type_parameters"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
control "t7 the container report, removed" "$CHECKER" "$WORK/t7.py"

# ── t8: the type-alias arm loses the reserved-name check ─────────────────────

cat > "$WORK/t8.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ EXPECTED UNGATED WITH A FALLING COUNT. The alias arm and the interface arm
# call the same helper with different codes, so a row that only broke the helper
# could not tell which caller it had measured; this one takes the alias caller
# out and leaves the interface's alone. Measured: 74/144 -> 72/141.
#
# ★★★ BOTH HALVES OF THE PREDICTION WERE WRONG AND THE CAUSE IS ONE LINE OF THE
# FIXTURE. It was written as *four diagnostics, one unit* on the reading that
# checker_type_alias_reserved_name.ts reports on three of its four declarations.
# It reports on TWO: `Object` is NOT one of the eleven — that line is there to
# show the reference saying TS2300 where we say nothing — so the plain fixture
# loses two lines and the generic one loses its single line, and BOTH units then
# have nothing left to say. ★The miscount is the same one the fixture exists to
# prevent, made while writing the row that measures it: *looks like a built-in*
# is not the rule, and the eleven are a list.
old = """        this.check_type_name_is_reserved(AstNode.name_of(node), DiagType_alias_name_cannot_be_0)
"""
new = """"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
control "t8 the type-alias arm loses the reserved-name check" "$CHECKER" "$WORK/t8.py"

# ── t9: the whole interface arm, clipped ─────────────────────────────────────

cat > "$WORK/t9.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ THE SLICE'S OWN BASELINE ROW. Everything the interface arm gained goes back
# to the single report slice 53 left here, so both instruments must move at once:
# every interface fixture answers the pre-slice tag and every heritage and
# reserved-name diagnostic of an interface disappears. It is the row that says
# what the slice is worth, in the two currencies the battery has.
old = """        if this.check_grammar_modifiers(node) = false
            this.check_grammar_interface_declaration(node)
        if this.container_allows_block_scoped_variable(AstNode.parent_node_of(node)) = false
            this.grammar_error_on_node(node, DiagX_0_declarations_can_only_be_declared_inside_a_block)
        this.check_type_parameters(AstNode.type_parameters_of(node))
        this.check_type_name_is_reserved(AstNode.name_of(node), DiagInterface_name_cannot_be_0)
        this.record_unported("check-exports-on-merged-declarations", KindInterfaceDeclaration)
"""
new = """        if this.check_grammar_modifiers(node)
        {
            this.record_unported("check-container-allows-block-scoped-variable", KindInterfaceDeclaration)
            return
        }
        this.record_unported("check-grammar-interface-declaration", KindInterfaceDeclaration)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
control "t9 the whole interface arm, clipped" "$CHECKER" "$WORK/t9.py"

echo
echo "################################################################"
bold "DONE — 16 rows over two instruments."
echo "  Every row restored its file and the restore was verified with cmp."
