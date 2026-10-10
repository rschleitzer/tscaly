#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice78.sh — the slice-78 battery: THE JSDOC GATE, tightened from the
# FLAG to the LINK, and the stale parent that gate had been hiding.
#
# ★★★ THE SLICE HAS TWO HALVES AND THEY NEED OPPOSITE INSTRUMENTS. The gate half
# LOSES nothing and GAINS units, so diagcheck reads it only as a number and the
# rows that break it come back ungated — the TAGPIN is what sees them. The parent
# half is the other way round: putting a stale parent back INVENTS a diagnostic,
# which is the one direction a subsequence catches, so those rows are diagcheck RED.
# ★A battery over one of the halves alone would have called the other one untested.
#
# ★★★ TWO PREDICTIONS IN HERE WERE WRONG AND BOTH ARE THE ROW'S WHOLE VALUE. g02
# predicted that the EAGER accessor is the load-bearing half and came back with
# nothing moving on any instrument — the eager and lazy forms provably coincide for
# the only question the pass asks. g17 predicted a red from re-parenting the deep
# clone's shared children, the fear a five-year-old note in parser.scaly was written
# to protect, and came back silent for the reason the SECOND half of that same note
# gives. Both source notes were rewritten to say what the rows measured.
#
# ★★ READING THE STOPGATE ON A ROW THAT CHANGES A TAG: its counts are then
# CONTAMINATED, because stops.sh compares against the UNPORTED line the artifact
# tree recorded with the BASELINE binary — so disagreeing units drop out of the
# histogram and both the `matched` and the `speaking` column fall. Read `matched`
# first: below 1308 the row moved a tag, and the event count is then about that. The
# clean before/after for the slice comes from two full run.sh + stops.sh passes,
# not from this column.
#
# ★★★ AND THE PARENT HALF EXISTS BECAUSE OF THE GATE HALF. `finish_reparsed_node`
# carried a note predicting it — *the instrument that would show it is the one that
# showed this: a checker arm reading a parent* — and a node the reparser mutates
# always carries a doc comment, i.e. is exactly the population the flag gate
# refused to check. Three units invented a diagnostic on the first run of the
# tightened gate.
#
# ★★★ ITERATE AT STAGE 1 AND CONFIRM AT STAGE 2 ONCE — slice 64's rule. The
# recorded verdicts are stage 1's.
#
# Usage (nothing may edit the tree while this runs — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # stage 1, ~25 s
#   packages/tscaly/tests/controls-slice78.sh 2>&1 | tee /tmp/battery78.log

set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.2/tscaly/checker.scaly
PARSER=$PKG/0.1.2/tscaly/parser.scaly
AST=$PKG/0.1.2/tscaly/ast.scaly
FIX=$PKG/tests/fixtures

. packages/tscaly/tests/toolchain.sh || exit 2

# ★ ONE MECHANISM PER FILE (slice 72's rule): the tagpin is first-wins, so a
# fixture naming two mechanisms is a fixture nobody can read a red row off.
#
# The first two are the POSITIVE half — a documented construct whose arm must run,
# once with a JSDoc that is absent from the eager cache and once with a JSDoc that
# is IN it (`@see` forces the eager parse even in a TS file). The next four are one
# per link spelling plus the tag-comment position. The last two are the parent half,
# and both are `.js` because the reparser runs for a JavaScript file only.
PINFILES="
$FIX/checker_jsdoc_no_link.ts
$FIX/checker_jsdoc_see_no_link.ts
$FIX/checker_jsdoc_link.ts
$FIX/checker_jsdoc_linkcode.ts
$FIX/checker_jsdoc_linkplain.ts
$FIX/checker_jsdoc_link_in_tag.ts
$FIX/checker_jsdoc_reparse_this.js
$FIX/checker_jsdoc_reparse_template_const.js
"
red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl78)

PATCHED_FILES=""
cleanup() {
  local f i=0
  for f in $PATCHED_FILES; do
    [ -f "$WORK/orig.$i" ] && cp "$WORK/orig.$i" "$f"
    i=$((i+1))
  done
  [ -n "$PATCHED_FILES" ] && red "INTERRUPTED — $PATCHED_FILES restored from the row that was running."
  rm -rf "$WORK"
}
trap cleanup EXIT INT TERM

build_bins() {
  "$SCALYC" -c --no-prelude -o "$WORK/pkg.o" "$PKG/0.1.2/tscaly.scaly" > "$WORK/build.log" 2>&1 || return 1
  "$SCALYC" -c -o "$WORK/types.o" "$PKG/0.1.2/tscaly_types.scaly" >> "$WORK/build.log" 2>&1 || return 1
  clang -o "$WORK/tscaly_types" "$WORK/types.o" "$WORK/pkg.o" "$LIBSCALY" -lm >> "$WORK/build.log" 2>&1
}

# The DIAGPIN: the C section of each pin file, one line each. `--diags` rather than
# the dump, because every one of these units stops somewhere and the dump prints
# nothing for such a unit (TypeDump.emit's own note).
#
# ★ Every line was checked against the reference's own C section before this battery
# ran: the two positive fixtures are EQUAL to it, the four link fixtures are the
# empty strict subsequence of its two TS2374 lines (that loss IS what the tag
# records), and the two `.js` fixtures are equal to it at EMPTY — which is the
# whole claim of the parent half.
diags_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$("$WORK/tscaly_types" --diags "$f" 2>/dev/null | tr '\n' '|')"
  done
}

# The TAGPIN: the first unported tag of each fixture, read off the DUMP the way the
# artifact tree records it.
tags_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$("$WORK/tscaly_types" "$f" 2>/dev/null | grep '^UNPORTED ' | head -1 | cut -d' ' -f3-)"
  done
}

# The STOPGATE: stops.sh's internal agreement plus the two counts it prints. The
# EVENT count is the sensitive column for this slice — the two halves together took
# the corpus from 7 911 stop events to 8 154, because 107 units now walk into their
# arms. ★See the header on reading this column when a row changes a tag.
stopgate() {   # writes "matched units speaking events other" to stdout
  BIN=$WORK/tscaly_types packages/tscaly/tests/stops.sh > "$WORK/stops.out" 2>&1
  local m u s e o
  m=$(sed -n 's/^  agreeing with the work list  *\([0-9]*\)$/\1/p' "$WORK/stops.out")
  u=$(sed -n 's/^  units compared  *\([0-9]*\)$/\1/p' "$WORK/stops.out")
  s=$(sed -n 's/^  units with a stop  *\([0-9]*\)$/\1/p' "$WORK/stops.out")
  e=$(sed -n 's/^  stop events  *\([0-9]*\)$/\1/p' "$WORK/stops.out")
  o=$(sed -n 's/^  parse\/bind stop  *\([0-9]*\).*$/\1/p' "$WORK/stops.out")
  echo "$m $u $s $e $o"
}

DIAG_BASE=""; DIAG_LINES=""; DIAG_DIAGS=""; STOP_BASE=""

baseline() {
  echo "################################################################"
  bold "BASELINE — three instruments"
  if ! build_bins; then
    red "the unpatched tree did not build — every row below would be measuring that."
    sed 's/^/    /' "$WORK/build.log"
    exit 2
  fi
  BIN=$WORK/tscaly_types "$DIAGCHECK" > "$WORK/base.diag" 2>&1
  local rc=$?
  DIAG_BASE=$(sed -n 's/^  consistent  *\([0-9]*\)$/\1/p' "$WORK/base.diag")
  DIAG_LINES=$(sed -n 's/^  units we speak on  *\([0-9]*\).*$/\1/p' "$WORK/base.diag")
  DIAG_DIAGS=$(sed -n 's/^.*(\([0-9]*\) diagnostics.*$/\1/p' "$WORK/base.diag")
  if [ "$rc" != 0 ]; then
    red "the diagnostics instrument is already red on the unpatched tree — fix that first."
    exit 2
  fi
  tags_of > "$WORK/base.tags"
  diags_of > "$WORK/base.diags"
  STOP_BASE=$(stopgate)
  echo
  echo "  the DIAGPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.diags"
  echo
  echo "  the TAGPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.tags"
  echo
  echo "  BASELINE   diagcheck $DIAG_BASE consistent, $DIAG_LINES speaking, $DIAG_DIAGS diagnostics"
  echo "             stopgate  (matched units speaking events other) = $STOP_BASE"
}

control() {   # $1 = label, $2 = files, $3 = patch
  echo
  echo "################################################################"
  bold "CONTROL: $1"
  local files="$2" f i=0
  for f in $files; do cp "$f" "$WORK/orig.$i"; i=$((i+1)); done
  PATCHED_FILES="$files"
  if ! python3 "$3" $files; then
    red "the patch did not apply — the anchor moved. The row measures nothing."
    i=0; for f in $files; do cp "$WORK/orig.$i" "$f"; i=$((i+1)); done
    PATCHED_FILES=""; return 1
  fi
  echo "  patched $files"
  if ! build_bins; then
    red "the patched tree did not build — the row measures nothing:"
    tail -5 "$WORK/build.log" | sed 's/^/    /'
    i=0; for f in $files; do cp "$WORK/orig.$i" "$f"; i=$((i+1)); done
    PATCHED_FILES=""; return 1
  fi
  BIN=$WORK/tscaly_types "$DIAGCHECK" > "$WORK/ctl.diag" 2>&1
  local rc=$?
  local consistent differing speaking diags stop
  consistent=$(sed -n 's/^  consistent  *\([0-9]*\)$/\1/p' "$WORK/ctl.diag")
  differing=$(sed -n 's/^  differing  *\([0-9]*\)$/\1/p' "$WORK/ctl.diag")
  speaking=$(sed -n 's/^  units we speak on  *\([0-9]*\).*$/\1/p' "$WORK/ctl.diag")
  diags=$(sed -n 's/^.*(\([0-9]*\) diagnostics.*$/\1/p' "$WORK/ctl.diag")
  tags_of > "$WORK/ctl.tags"
  diags_of > "$WORK/ctl.diags"
  stop=$(stopgate)
  local restored=1
  i=0
  for f in $files; do
    cp "$WORK/orig.$i" "$f"
    cmp -s "$WORK/orig.$i" "$f" || restored=0
    i=$((i+1))
  done
  if [ "$restored" != 1 ]; then
    red "the source did NOT come back — every number below is suspect."
    return 1
  fi
  PATCHED_FILES=""
  echo "  RESTORE VERIFIED   $files byte-identical"
  echo
  local moved=0
  if [ "$rc" != 0 ]; then
    green "diagcheck RED $differing   (consistent $consistent, was $DIAG_BASE; speaking on $speaking/$diags, was $DIAG_LINES/$DIAG_DIAGS)"
    moved=1
  else
    echo "  diagcheck ungated — speaking on $speaking units with $diags diagnostics, was $DIAG_LINES/$DIAG_DIAGS."
  fi
  if cmp -s "$WORK/base.diags" "$WORK/ctl.diags"; then
    echo "  diagpin   unmoved — all eight pin files answer the same C section."
  else
    green "diagpin   RED"
    diff "$WORK/base.diags" "$WORK/ctl.diags" | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.tags" "$WORK/ctl.tags"; then
    echo "  tagpin    unmoved — all eight fixtures answer the same tag."
  else
    green "tagpin    RED"
    diff "$WORK/base.tags" "$WORK/ctl.tags" | sed 's/^/    /'
    moved=1
  fi
  if [ "$stop" = "$STOP_BASE" ]; then
    echo "  stopgate  unmoved — $stop"
  else
    green "stopgate  MOVED   $STOP_BASE -> $stop   (matched units speaking events other)"
    moved=1
  fi
  if [ "$moved" = 0 ]; then
    if [ "$speaking" != "$DIAG_LINES" ] || [ "$diags" != "$DIAG_DIAGS" ]; then
      echo "  ungated on all three, WITH A NUMBER: $DIAG_LINES/$DIAG_DIAGS -> $speaking/$diags."
    else
      red "UNGATED ON ALL THREE AND NOTHING MOVED AT ALL."
      echo "  Decide which of §3.5v's four kinds this is. A row that predicted"
      echo "  this is a measurement; a row that did not is a hole in the battery."
    fi
  fi
  return 0
}

PATCHDIR=$WORK/patches
mkdir -p "$PATCHDIR"

# ── the patches ─────────────────────────────────────────────────────────────
#
# Written first, ALL of them, so the dry run below can apply every one against a
# copy of the tree before a single build is spent (slice 57).

cat > "$PATCHDIR/g01.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE PREMISE ROW: the blanket FLAG gate back, exactly as it stood before this
# slice. PREDICTION: diagcheck ungated at a LOSS (251/537 -> 240/517) and the
# STOPGATE MOVED by the whole of the slice — this is the row that prices it.
# The diagpin goes red on the two positive fixtures, whose TS2374 lines disappear.
old = """        if this.check_jsdoc_of_node(node, k)
        {"""
new = """        if (AstNode.flags_of(node) & NodeFlagsHasJSDoc) <> 0
        {
            this.record_unported("check-jsdoc-comments", k)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g02.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE LOAD-BEARING HALF, AND IT IS ONE WORD: the LAZY accessor instead of the
# EAGER one. checkSourceElementWorker asks EagerJSDoc, which reads the cache and
# never parses; jsdoc_for_node PARSES on demand, so with this patch every doc
# comment of every TS file materialises and each one carrying a link stops again.
# PREDICTION: a LOSS on diagcheck and the stopgate moved. The row exists because
# `p.lookup_jsdoc_info` and `p.parse_jsdoc_for_node` differ by nothing a reader can
# see at the call site.
old = "        let docs Parser.eager_jsdoc(p, node)"
new = "        let docs Parser.jsdoc_for_node(p, node)"
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g03.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★ EagerJSDoc's OWN first line — the HasJSDoc test — dropped from
# Parser.eager_jsdoc. PREDICTION: UNGATED with nothing moving, and it is a
# MEASUREMENT rather than a hole: a JS file sets the flag in the same branch of
# with_jsdoc that fills the table, and a TS file whose comment carries no @see or
# @link has no entry to find. The test is transcribed for fidelity, and this row is
# the statement that it is currently redundant in both directions.
old = """        if (AstNode.flags_of(n) & NodeFlagsHasJSDoc) = 0
            return null
        p.lookup_jsdoc_info(n)"""
new = """        p.lookup_jsdoc_info(n)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g04.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE TAGS' COMMENTS DROPPED — the pass walks the JSDoc's own prose only.
# checkSourceElementWorker calls checkJSDocComments TWICE per JSDoc, once for the
# comment and once per TAG, and a link can sit in either. PREDICTION: tagpin RED on
# checker_jsdoc_link_in_tag.ts ALONE, which is why that fixture exists.
old = """            let tags AstNode.jsdoc_tags_of(jsdoc)
            if tags <> null
            {
                let tl tags as ref[Array[ref[AstNode]?]]
                let tcount tl.get_length() as int
                var j 0
                while j < tcount
                {
                    if this.check_jsdoc_comments(*(tl.get_buffer() + j), k)
                        return true
                    set j: j + 1
                }
            }
"""
new = ""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g05.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE ABANDON TURNED INTO A RECORD-AND-WALK-ON: the link arm still reports but
# the node's arm runs anyway. PREDICTION: the four link fixtures keep their tag (it
# is still recorded) and GAIN their two TS2374 lines, so the diagpin goes red on all
# four and diagcheck moves with a number. The row prices the decision rather than
# proving it: resolveJSDocMemberName's own PURPOSE is to record a reference for
# checkUnusedIdentifiers, which is inert here, so what the abandon protects is the
# possibility that getTypeOfSymbol reports — and that cannot be shown, only stated.
old = """            let jsdoc *(list.get_buffer() + i)
            if this.check_jsdoc_comments(jsdoc, k)
                return true"""
new = """            let jsdoc *(list.get_buffer() + i)
            this.check_jsdoc_comments(jsdoc, k)"""
assert s.count(old) == 1
s = s.replace(old, new, 1)
old2 = """                    if this.check_jsdoc_comments(*(tl.get_buffer() + j), k)
                        return true
                    set j: j + 1"""
new2 = """                    this.check_jsdoc_comments(*(tl.get_buffer() + j), k)
                    set j: j + 1"""
assert s.count(old2) == 1
s = s.replace(old2, new2, 1)
old3 = """            if this.check_jsdoc_comment(*(list.get_buffer() + i), k)
                return true
            set i: i + 1"""
new3 = """            this.check_jsdoc_comment(*(list.get_buffer() + i), k)
            set i: i + 1"""
assert s.count(old3) == 1
open(p, "w").write(s.replace(old3, new3, 1))
PY

cat > "$PATCHDIR/g06.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★ THE JSDocLink ARM DROPPED. PREDICTION: tagpin RED on checker_jsdoc_link.ts and
# checker_jsdoc_link_in_tag.ts and nothing else — three rows rather than one,
# because a patch breaking all three kinds together could not say which fixture
# measures which.
old = """        if ck = KindJSDocLink
        {
            this.record_unported("check-jsdoc-comments", k)
            return true
        }
"""
new = ""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g07.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★ THE JSDocLinkCode ARM DROPPED. PREDICTION: tagpin RED on
# checker_jsdoc_linkcode.ts alone.
old = """        if ck = KindJSDocLinkCode
        {
            this.record_unported("check-jsdoc-comments", k)
            return true
        }
"""
new = ""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g08.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★ THE JSDocLinkPlain ARM DROPPED. PREDICTION: tagpin RED on
# checker_jsdoc_linkplain.ts alone.
old = """        if ck = KindJSDocLinkPlain
        {
            this.record_unported("check-jsdoc-comments", k)
            return true
        }
"""
new = ""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g09.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ jsdoc_comment_list_of LOSES ITS KindJSDoc ARM, so only a TAG's comment is
# walked. The reference writes Node.CommentList() as ONE switch whose first case is
# KindJSDoc; this port had the tag half already and added that case in front.
# PREDICTION: tagpin RED on the three fixtures whose link is in the JSDoc's own
# prose, and NOT on checker_jsdoc_link_in_tag.ts — the exact complement of g04, and
# the pair is what shows the two positions are two mechanisms.
old = """        choose n.data
            when d: JSDoc
                return d.comment
        AstNode.jsdoc_tag_comment_of(n)"""
new = """        AstNode.jsdoc_tag_comment_of(n)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g10.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE PARENT HALF'S PREMISE ROW: finish_mutated_node emptied out, which is the
# tree as it stood before this slice at all twenty sites at once. PREDICTION:
# diagcheck RED 3 — the two TS2680 and the one TS1277 the tightened gate exposed —
# and the diagpin red on both `.js` fixtures. ★It is the only row of this battery
# that is red on the SUBSEQUENCE, because a stale parent makes the port INVENT.
old = """        if n = null
            return
        this.override_parent_in_immediate_children(n)
    }

    ; DeepCloneReparse"""
new = """        if n = null
            return
    }

    ; DeepCloneReparse"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g11.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ ONLY THE @this SITE. PREDICTION: diagcheck RED 2 and the diagpin red on
# checker_jsdoc_reparse_this.js alone — TS2680, from parameter_index_of searching a
# parameter list reached through a parent that still names nothing.
old = """            AstNode.set_parameters(fun, new_params)
            this.finish_mutated_node(fun)"""
new = """            AstNode.set_parameters(fun, new_params)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g12.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ ONLY THE @template SITES (the function-like host and the class). PREDICTION:
# diagcheck RED 1 and the diagpin red on checker_jsdoc_reparse_template_const.js
# alone — TS1277, from checkGrammarModifiers asking a reparsed type parameter's
# parent whether it is function-like. ★A different arm from g11's, which is why the
# two rows are separate: one mechanism, two independent readers of `parent`.
old = """                        AstNode.set_type_parameters(fun, this.gather_type_parameters(jsdoc, false))
                        this.finish_mutated_node(fun)"""
new = """                        AstNode.set_type_parameters(fun, this.gather_type_parameters(jsdoc, false))"""
assert s.count(old) == 1
s = s.replace(old, new, 1)
old2 = """                    AstNode.set_type_parameters(parent, this.gather_type_parameters(jsdoc, false))
                    this.finish_mutated_node(parent)"""
new2 = """                    AstNode.set_type_parameters(parent, this.gather_type_parameters(jsdoc, false))"""
assert s.count(old2) == 1
open(p, "w").write(s.replace(old2, new2, 1))
PY

cat > "$PATCHDIR/g13.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★ ONLY THE @param SITE. PREDICTION: measured rather than predicted. `@param`
# writes a TYPE and a QUESTION TOKEN onto a parameter the source already wrote, so
# the parameter's own parent is correct and only the new children's are stale — and
# whether any checker arm reads those is what this row answers.
old = """                AstNode.set_parameter_question_token(param, this.make_question_if_optional(tag))
            this.finish_mutated_node(param)"""
new = """                AstNode.set_parameter_question_token(param, this.make_question_if_optional(tag))"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g14.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★ ONLY THE MODIFIER-TAG SITE (@readonly / @private / @public / @protected /
# @override becoming real modifiers). PREDICTION: measured. checkGrammarModifiers
# reads `modifier.Parent` at several of its arms, so this is the site most likely to
# matter after g12's; if it comes back silent the corpus is what to say so about.
old = """        AstNode.set_modifiers(parent, nodes)
        this.finish_mutated_node(parent)"""
new = """        AstNode.set_modifiers(parent, nodes)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g15.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★ THE HERITAGE SITES — @implements' two and @augments' one. PREDICTION: measured.
# A heritage clause's own parent is what checkClassHeritageClauses reads, and the
# extends chapter is still a stop (§3.5du), so a silence here is very likely
# UNCOVERED-behind-a-stop rather than unreachable — which is a thing to write down
# rather than a colour.
old = """                        types.add(this.add_deep_clone_reparse(class_name))
                        this.finish_mutated_node(c)"""
new = """                        types.add(this.add_deep_clone_reparse(class_name))"""
assert s.count(old) == 1
s = s.replace(old, new, 1)
old2 = """            clauses.add(clause)
        this.finish_mutated_node(parent)"""
new2 = """            clauses.add(clause)"""
assert s.count(old2) == 1
s = s.replace(old2, new2, 1)
old3 = """            AstNode.set_expression_type_arguments(target, new_args)
            this.finish_mutated_node(target)"""
new3 = """            AstNode.set_expression_type_arguments(target, new_args)"""
assert s.count(old3) == 1
open(p, "w").write(s.replace(old3, new3, 1))
PY

cat > "$PATCHDIR/g16.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★ THE @type AND @satisfies SITES — the ten that write a TYPE or wrap an
# initializer or expression in a cast. PREDICTION: measured. These are the sites
# whose new child is a TYPE NODE or a synthesized cast, and the type-node arms are
# ported (slice 61), so if any of them reads a parent this row is where it shows.
import re
n = 0
for old in ["""                    AstNode.set_type(d, this.add_deep_clone_reparse(inner))
                    this.finish_mutated_node(d)""",
            """            AstNode.set_type(parent, this.add_deep_clone_reparse(inner))
            this.finish_mutated_node(parent)""",
            """            AstNode.set_type(parent, this.reparse_jsdoc_type_literal(inner))
            this.finish_mutated_node(parent)""",
            """            AstNode.set_type(bin, this.add_deep_clone_reparse(inner))
            this.finish_mutated_node(bin)""",
            """            AstNode.set_expression(parent, this.make_new_cast(this.add_deep_clone_reparse(inner), e, true))
            this.finish_mutated_node(parent)""",
            """            AstNode.set_full_signature(fun, this.add_deep_clone_reparse(AstNode.jsdoc_type_expression_inner_of(te)))
            this.finish_mutated_node(fun)""",
            """                    AstNode.set_initializer(d, this.make_new_cast(this.add_deep_clone_reparse(inner), initializer, false))
                    this.finish_mutated_node(d)""",
            """            AstNode.set_initializer(parent, this.make_new_cast(this.add_deep_clone_reparse(inner), initializer, false))
            this.finish_mutated_node(parent)""",
            """            AstNode.set_shorthand_object_assignment_initializer(parent, this.make_new_cast(this.add_deep_clone_reparse(inner), initializer, false))
            this.finish_mutated_node(parent)""",
            """            AstNode.set_expression(parent, this.make_new_cast(this.add_deep_clone_reparse(inner), e, false))
            this.finish_mutated_node(parent)""",
            """            AstNode.set_binary_right(bin, this.make_new_cast(this.add_deep_clone_reparse(inner), AstNode.binary_right_of(bin), false))
            this.finish_mutated_node(bin)"""]:
    assert s.count(old) == 1, old[:60]
    lines = old.split("\n")
    s = s.replace(old, "\n".join(lines[:-1]), 1)
    n += 1
assert n == 11
open(p, "w").write(s)
PY

cat > "$PATCHDIR/g17.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE OLD NOTE'S FEAR, BUILT: the same re-parenting loop called from
# add_deep_clone_reparse as well, which is what the reference's DeepCloneReparse
# does. PREDICTION: a red SOMEWHERE — this port's clone copies the ROOT and SHARES
# the children, so the loop steals every shared child's parent from the node still
# in the tree. It is the row that shows the distinction between the two call sites
# is load-bearing and not a stylistic one; a battery that only added the mutation
# sites would have left that as an assertion.
old = """        let c AstNode.alloc(host)
        set *c: *n
        set c.flags: c.flags | NodeFlagsReparsed
        c"""
new = """        let c AstNode.alloc(host)
        set *c: *n
        set c.flags: c.flags | NodeFlagsReparsed
        this.override_parent_in_immediate_children(c)
        c"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

# ── the dry run ─────────────────────────────────────────────────────────────
bold "DRY RUN — every patch against a copy of the tree"
DRY=$WORK/dry
for spec in "g01 $CHECKER" "g02 $CHECKER" "g03 $PARSER" "g04 $CHECKER" "g05 $CHECKER" \
            "g06 $CHECKER" "g07 $CHECKER" "g08 $CHECKER" "g09 $AST" "g10 $PARSER" \
            "g11 $PARSER" "g12 $PARSER" "g13 $PARSER" "g14 $PARSER" "g15 $PARSER" \
            "g16 $PARSER" "g17 $PARSER"; do
  set -- $spec
  rm -rf "$DRY"; mkdir -p "$DRY"; cp "$2" "$DRY/f.scaly"
  if python3 "$PATCHDIR/$1.py" "$DRY/f.scaly" >/dev/null 2>&1; then
    echo "  $1 applies"
  else
    red "  $1 DOES NOT APPLY — its anchor has moved."; exit 2
  fi
done
rm -rf "$DRY"

baseline

control "g01 the blanket FLAG gate back (the premise)"                    "$CHECKER" "$PATCHDIR/g01.py"
control "g02 the LAZY accessor instead of the eager one"                  "$CHECKER" "$PATCHDIR/g02.py"
control "g03 EagerJSDoc's HasJSDoc test dropped"                          "$PARSER"  "$PATCHDIR/g03.py"
control "g04 the TAGS' comments not walked"                               "$CHECKER" "$PATCHDIR/g04.py"
control "g05 the link arm records but does not abandon"                   "$CHECKER" "$PATCHDIR/g05.py"
control "g06 the JSDocLink arm dropped"                                   "$CHECKER" "$PATCHDIR/g06.py"
control "g07 the JSDocLinkCode arm dropped"                               "$CHECKER" "$PATCHDIR/g07.py"
control "g08 the JSDocLinkPlain arm dropped"                              "$CHECKER" "$PATCHDIR/g08.py"
control "g09 jsdoc_comment_list_of loses its KindJSDoc arm"               "$AST"     "$PATCHDIR/g09.py"
control "g10 finish_mutated_node emptied (the parent premise)"            "$PARSER"  "$PATCHDIR/g10.py"
control "g11 only the @this site"                                        "$PARSER"  "$PATCHDIR/g11.py"
control "g12 only the @template sites"                                   "$PARSER"  "$PATCHDIR/g12.py"
control "g13 only the @param site"                                       "$PARSER"  "$PATCHDIR/g13.py"
control "g14 only the modifier-tag site"                                 "$PARSER"  "$PATCHDIR/g14.py"
control "g15 the heritage sites (@implements, @augments)"                 "$PARSER"  "$PATCHDIR/g15.py"
control "g16 the @type and @satisfies sites"                             "$PARSER"  "$PATCHDIR/g16.py"
control "g17 the clone re-parented too (the old note's fear, built)"      "$PARSER"  "$PATCHDIR/g17.py"

echo
echo "################################################################"
bold "DONE — read every row against its PREDICTION, not against its colour."
